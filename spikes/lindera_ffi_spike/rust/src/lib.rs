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
