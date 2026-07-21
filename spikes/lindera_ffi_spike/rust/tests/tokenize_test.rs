use lindera_ffi_spike::tokenize_surfaces;

fn dict_path() -> String {
    format!("{}/../dict/lindera-ipadic-2.7.0-20250920", env!("CARGO_MANIFEST_DIR"))
}

#[test]
fn tokenizes_known_sentence_and_reconstructs_original_text() {
    let text = "東京都に住んでいます。";
    let surfaces = tokenize_surfaces(&dict_path(), text).expect("tokenize should succeed");

    // Structural invariant: concatenating every surface must reconstruct the input
    // exactly — this holds for any correct tokenizer regardless of exact segmentation.
    assert_eq!(surfaces.concat(), text);
    // Sanity bound: a real tokenizer splits this into several tokens, not one blob.
    assert!(surfaces.len() >= 5, "expected several tokens, got {:?}", surfaces);
    // "東京" (Tokyo) is a proper-noun segment recognized by IPADIC.
    // Some IPADIC versions may also include "都" as a separate token, which is valid.
    assert_eq!(surfaces[0], "東京");
}
