use std::ffi::{CStr, CString};
use lindera_ffi_spike::{lindera_init, lindera_tokenize_json, lindera_free_handle, lindera_free_string};

fn dict_path() -> CString {
    CString::new(format!("{}/../dict/lindera-ipadic-2.7.0-20250920", env!("CARGO_MANIFEST_DIR"))).unwrap()
}

#[test]
fn ffi_roundtrip_returns_valid_json_with_expected_surfaces() {
    let handle = lindera_init(dict_path().as_ptr());
    assert!(!handle.is_null(), "lindera_init should succeed with a valid dict path");

    let text = CString::new("東京都に住んでいます。").unwrap();
    let result_ptr = lindera_tokenize_json(handle, text.as_ptr());
    let json = unsafe { CStr::from_ptr(result_ptr) }.to_str().unwrap().to_owned();
    lindera_free_string(result_ptr);
    lindera_free_handle(handle);

    let parsed: serde_json::Value = serde_json::from_str(&json).expect("output must be valid JSON");
    assert_eq!(parsed["ok"], true);
    let surfaces: Vec<String> = parsed["surfaces"]
        .as_array()
        .unwrap()
        .iter()
        .map(|v| v.as_str().unwrap().to_string())
        .collect();
    assert_eq!(surfaces.concat(), "東京都に住んでいます。");
}

#[test]
fn lindera_init_returns_null_for_bad_dict_path() {
    let bad_path = CString::new("/does/not/exist").unwrap();
    let handle = lindera_init(bad_path.as_ptr());
    assert!(handle.is_null());
}
