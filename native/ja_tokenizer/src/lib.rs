//! JA tokenizer FFI library. Host-native (no Android/Gradle/cargokit —
//! Phase 3 is headless per SPEC_MINING_PIPELINE.md's own phase table),
//! loaded via plain `dart:ffi`. The Lindera + embedded-IPADIC setup
//! itself was already proven on a physical Android device in Phase 1
//! (BERICHT_1_lindera-spike.md); this crate reuses that exact
//! configuration for a desktop/CLI target instead of repeating the
//! cargokit/Gradle integration this phase doesn't need.

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::sync::OnceLock;

use lindera::dictionary::load_dictionary;
use lindera::mode::Mode;
use lindera::segmenter::Segmenter;
use lindera::tokenizer::Tokenizer;
use serde::Serialize;

static TOKENIZER: OnceLock<Tokenizer> = OnceLock::new();

#[derive(Serialize, Debug, PartialEq)]
pub struct TokenOut {
    pub surface: String,
    /// Comma-joined POS tags (IPADIC's pos1..pos4 fields), e.g.
    /// "名詞,固有名詞,組織,*".
    pub pos: String,
    /// Dictionary base form. Falls back to `surface` for unknown words
    /// (IPADIC reports "*" when the base form isn't available).
    pub lemma: String,
    /// Katakana reading, if IPADIC has one for this token.
    pub reading: Option<String>,
}

fn tokenizer() -> &'static Tokenizer {
    TOKENIZER.get_or_init(|| {
        let dictionary =
            load_dictionary("embedded://ipadic").expect("failed to load embedded IPADIC");
        let segmenter = Segmenter::new(Mode::Normal, dictionary, None);
        Tokenizer::new(segmenter)
    })
}

/// Tokenizes `text` and returns one [TokenOut] per morpheme, in order.
/// The plain-Rust entry point — exercised directly by `cargo test`,
/// shared with the FFI wrapper below.
pub fn tokenize(text: &str) -> Vec<TokenOut> {
    let mut tokens = match tokenizer().tokenize(text) {
        Ok(t) => t,
        Err(_) => return Vec::new(),
    };

    tokens
        .iter_mut()
        .map(|t| {
            let details = t.details();
            let get = |i: usize| details.get(i).map(|s| s.to_string());
            let pos = (0..4)
                .filter_map(|i| get(i))
                .collect::<Vec<_>>()
                .join(",");
            let base_form = get(6).filter(|s| s != "*");
            let reading = get(7).filter(|s| s != "*");

            TokenOut {
                surface: t.surface.to_string(),
                pos,
                lemma: base_form.unwrap_or_else(|| t.surface.to_string()),
                reading,
            }
        })
        .collect()
}

/// FFI entry point: tokenizes `text` (a NUL-terminated UTF-8 C string)
/// and returns a JSON array of [TokenOut] as an owned, NUL-terminated
/// C string. Caller must free the result with [ja_free_string] — Dart
/// and Rust use different allocators, so Dart must not `free()` this
/// pointer itself.
///
/// # Safety
/// `text` must be a valid pointer to a NUL-terminated UTF-8 C string
/// that outlives this call.
#[no_mangle]
pub unsafe extern "C" fn ja_tokenize_json(text: *const c_char) -> *mut c_char {
    let text = if text.is_null() {
        ""
    } else {
        unsafe { CStr::from_ptr(text) }.to_str().unwrap_or("")
    };

    let tokens = tokenize(text);
    let json = serde_json::to_string(&tokens).unwrap_or_else(|_| "[]".to_string());
    CString::new(json)
        .unwrap_or_else(|_| CString::new("[]").unwrap())
        .into_raw()
}

/// Frees a string previously returned by [ja_tokenize_json].
///
/// # Safety
/// `s` must be a pointer previously returned by [ja_tokenize_json] and
/// not already freed.
#[no_mangle]
pub unsafe extern "C" fn ja_free_string(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    drop(unsafe { CString::from_raw(s) });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tokenizes_a_proper_noun_as_a_single_token() {
        let tokens = tokenize("関西国際空港限定トートバッグ");

        assert_eq!(tokens[0].surface, "関西国際空港");
        assert_eq!(tokens[0].lemma, "関西国際空港");
        assert!(tokens[0].pos.starts_with("名詞"));
    }

    #[test]
    fn unknown_word_falls_back_lemma_to_surface() {
        let tokens = tokenize("トートバッグ");

        // Not in IPADIC as a single entry; lemma should still be
        // populated (falling back to surface), never empty.
        assert!(!tokens[0].lemma.is_empty());
    }

    #[test]
    fn empty_input_yields_no_tokens() {
        assert!(tokenize("").is_empty());
    }

    #[test]
    fn conjugated_verb_reports_dictionary_base_form_as_lemma() {
        // 食べます (polite present) -> base form 食べる
        let tokens = tokenize("食べます");
        let verb = tokens.iter().find(|t| t.surface == "食べ").unwrap();

        assert_eq!(verb.lemma, "食べる");
    }
}
