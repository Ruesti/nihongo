use lindera::dictionary::load_dictionary;
use lindera::mode::Mode;
use lindera::segmenter::Segmenter;
use lindera::tokenizer::Tokenizer;
use std::sync::OnceLock;
use std::time::Instant;

static TOKENIZER: OnceLock<Tokenizer> = OnceLock::new();

pub struct BenchmarkResult {
    pub sentence_count: i32,
    pub total_tokenize_ms: f64,
    pub per_sentence_ms: Vec<f64>,
    pub total_tokens: i32,
}

#[flutter_rust_bridge::frb(sync)]
pub fn init_tokenizer() -> f64 {
    let t0 = Instant::now();
    let dictionary = load_dictionary("embedded://ipadic").expect("failed to load ipadic");
    let segmenter = Segmenter::new(Mode::Normal, dictionary, None);
    let tokenizer = Tokenizer::new(segmenter);
    TOKENIZER
        .set(tokenizer)
        .unwrap_or_else(|_| panic!("init_tokenizer called twice"));
    t0.elapsed().as_secs_f64() * 1000.0
}

#[flutter_rust_bridge::frb(sync)]
pub fn benchmark_batch(sentences: Vec<String>) -> BenchmarkResult {
    let tokenizer = TOKENIZER.get().expect("call init_tokenizer first");
    let mut per_sentence_ms = Vec::with_capacity(sentences.len());
    let mut total_tokens: i32 = 0;

    let overall_start = Instant::now();
    for s in &sentences {
        let t0 = Instant::now();
        let tokens = tokenizer.tokenize(s).expect("tokenize failed");
        per_sentence_ms.push(t0.elapsed().as_secs_f64() * 1000.0);
        total_tokens += tokens.len() as i32;
    }
    let total_tokenize_ms = overall_start.elapsed().as_secs_f64() * 1000.0;

    BenchmarkResult {
        sentence_count: sentences.len() as i32,
        total_tokenize_ms,
        per_sentence_ms,
        total_tokens,
    }
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
