use thiserror::Error;

pub type KytoResult<T> = Result<T, KytoError>;

#[derive(Debug, Error)]
pub enum KytoError {
    #[error("IO {0}: {1}")]
    Io(String, String),
    #[error("missing file: {0}")]
    MissingFile(String),
    #[error("lex error at {line}:{col}: {msg}")]
    Lex { line: usize, col: usize, msg: String },
    #[error("parse error at {line}:{col}: {msg}")]
    Parse { line: usize, col: usize, msg: String },
    #[error("eval error: {0}")]
    Eval(String),
    #[error("crypto error: {0}")]
    Crypto(String),
    #[error("emit error: {0}")]
    Emit(String),
}
