use lindera::dictionary::load_dictionary;
use lindera::mode::Mode;
use lindera::segmenter::Segmenter;
use lindera::tokenizer::Tokenizer;

pub fn tokenize_surfaces(dict_path: &str, text: &str) -> Result<Vec<String>, String> {
    let dictionary = load_dictionary(dict_path).map_err(|e| e.to_string())?;
    let segmenter = Segmenter::new(Mode::Normal, dictionary, None);
    let tokenizer = Tokenizer::new(segmenter);
    let tokens = tokenizer.tokenize(text).map_err(|e| e.to_string())?;
    Ok(tokens.into_iter().map(|t| t.surface.to_string()).collect())
}

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

pub struct TokenizerHandle {
    tokenizer: Tokenizer,
}

#[derive(serde::Serialize)]
struct TokenizeResult {
    ok: bool,
    surfaces: Vec<String>,
    error: Option<String>,
}

#[no_mangle]
pub extern "C" fn lindera_init(dict_path: *const c_char) -> *mut TokenizerHandle {
    let dict_path = unsafe { CStr::from_ptr(dict_path) }.to_string_lossy().into_owned();
    let dictionary = match load_dictionary(&dict_path) {
        Ok(d) => d,
        Err(_) => return std::ptr::null_mut(),
    };
    let segmenter = Segmenter::new(Mode::Normal, dictionary, None);
    let tokenizer = Tokenizer::new(segmenter);
    Box::into_raw(Box::new(TokenizerHandle { tokenizer }))
}

#[no_mangle]
pub extern "C" fn lindera_tokenize_json(
    handle: *mut TokenizerHandle,
    text: *const c_char,
) -> *mut c_char {
    let handle = unsafe { &*handle };
    let text = unsafe { CStr::from_ptr(text) }.to_string_lossy().into_owned();

    let result = match handle.tokenizer.tokenize(&text) {
        Ok(tokens) => TokenizeResult {
            ok: true,
            surfaces: tokens.into_iter().map(|t| t.surface.to_string()).collect(),
            error: None,
        },
        Err(e) => TokenizeResult { ok: false, surfaces: vec![], error: Some(e.to_string()) },
    };
    let json = serde_json::to_string(&result).expect("TokenizeResult serialization cannot fail");
    CString::new(json).expect("no interior NUL in generated JSON").into_raw()
}

#[no_mangle]
pub extern "C" fn lindera_free_handle(handle: *mut TokenizerHandle) {
    if handle.is_null() {
        return;
    }
    unsafe {
        drop(Box::from_raw(handle));
    }
}

#[no_mangle]
pub extern "C" fn lindera_free_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(ptr));
    }
}
