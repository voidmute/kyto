use crate::error::{KytoError, KytoResult};

#[derive(Debug, Clone, PartialEq)]
pub enum Token {
    Let,
    Fn,
    Struct,
    Enum,
    Import,
    If,
    Else,
    For,
    In,
    Return,
    Emit,
    True,
    False,
    Ident(String),
    String(String),
    Int(i64),
    Arrow,
    Colon,
    Comma,
    Dot,
    Assign,
    Eq,
    Plus,
    QuestionQuestion,
    Lt,
    Gt,
    LParen,
    RParen,
    LBrace,
    RBrace,
    LBracket,
    RBracket,
    Eof,
}

pub struct Lexer<'a> {
    src: &'a str,
    chars: std::iter::Peekable<std::str::CharIndices<'a>>,
    line: usize,
    col: usize,
    bol: bool,
}

impl<'a> Lexer<'a> {
    pub fn new(src: &'a str) -> Self {
        Self {
            src,
            chars: src.char_indices().peekable(),
            line: 1,
            col: 1,
            bol: true,
        }
    }

    pub fn tokenize(mut self) -> KytoResult<Vec<Token>> {
        let mut tokens = Vec::new();
        loop {
            let tok = self.next_token()?;
            let done = matches!(tok, Token::Eof);
            tokens.push(tok);
            if done {
                break;
            }
        }
        Ok(tokens)
    }

    fn bump(&mut self) -> Option<(usize, char)> {
        let next = self.chars.next();
        if let Some((_, c)) = next {
            if c == '\n' {
                self.line += 1;
                self.col = 1;
                self.bol = true;
            } else {
                self.col += 1;
                self.bol = false;
            }
        }
        next
    }

    fn peek(&mut self) -> Option<char> {
        self.chars.peek().map(|(_, c)| *c)
    }

    fn error(&self, msg: impl Into<String>) -> KytoError {
        KytoError::Lex {
            line: self.line,
            col: self.col,
            msg: msg.into(),
        }
    }

    fn skip_ws_and_comments(&mut self) {
        while let Some(c) = self.peek() {
            if c.is_whitespace() {
                self.bump();
                continue;
            }
            if c == '+' && self.bol {
                while matches!(self.peek(), Some(ch) if ch != '\n') {
                    self.bump();
                }
                continue;
            }
            break;
        }
    }

    fn read_string(&mut self) -> KytoResult<String> {
        self.bump(); // opening "
        let mut s = String::new();
        loop {
            match self.peek() {
                None => return Err(self.error("unterminated string")),
                Some('"') => {
                    self.bump();
                    break;
                }
                Some('\\') => {
                    self.bump();
                    match self.bump().map(|(_, c)| c) {
                        Some('"') => s.push('"'),
                        Some('\\') => s.push('\\'),
                        Some('n') => s.push('\n'),
                        Some(c) => return Err(self.error(format!("invalid escape \\{c}"))),
                        None => return Err(self.error("unterminated string")),
                    }
                }
                Some(c) => {
                    self.bump();
                    s.push(c);
                }
            }
        }
        Ok(s)
    }

    fn read_ident(&mut self, start: char) -> String {
        let mut ident = String::new();
        ident.push(start);
        while matches!(self.peek(), Some(c) if c.is_ascii_alphanumeric() || c == '_') {
            ident.push(self.bump().unwrap().1);
        }
        ident
    }

    fn read_number(&mut self, start: char) -> KytoResult<i64> {
        let mut num = String::new();
        num.push(start);
        while matches!(self.peek(), Some(c) if c.is_ascii_digit()) {
            num.push(self.bump().unwrap().1);
        }
        num.parse::<i64>().map_err(|_| self.error("invalid integer"))
    }

    fn next_token(&mut self) -> KytoResult<Token> {
        self.skip_ws_and_comments();
        let Some((_, c)) = self.bump() else {
            return Ok(Token::Eof);
        };
        match c {
            '(' => Ok(Token::LParen),
            ')' => Ok(Token::RParen),
            '{' => Ok(Token::LBrace),
            '}' => Ok(Token::RBrace),
            '[' => Ok(Token::LBracket),
            ']' => Ok(Token::RBracket),
            ':' => Ok(Token::Colon),
            ',' => Ok(Token::Comma),
            '.' => Ok(Token::Dot),
            '+' => Ok(Token::Plus),
            '<' => Ok(Token::Lt),
            '>' => Ok(Token::Gt),
            '=' => {
                if self.peek() == Some('=') {
                    self.bump();
                    Ok(Token::Eq)
                } else {
                    Ok(Token::Assign)
                }
            }
            '-' => {
                if self.peek() == Some('>') {
                    self.bump();
                    Ok(Token::Arrow)
                } else {
                    Err(self.error("unexpected '-'"))
                }
            }
            '?' => {
                if self.peek() == Some('?') {
                    self.bump();
                    Ok(Token::QuestionQuestion)
                } else {
                    Err(self.error("expected ??"))
                }
            }
            '"' => {
                let mut s = String::new();
                loop {
                    match self.peek() {
                        None => return Err(self.error("unterminated string")),
                        Some('"') => {
                            self.bump();
                            break;
                        }
                        Some('\\') => {
                            self.bump();
                            match self.bump().map(|(_, ch)| ch) {
                                Some('"') => s.push('"'),
                                Some('\\') => s.push('\\'),
                                Some('n') => s.push('\n'),
                                Some(ch) => return Err(self.error(format!("invalid escape \\{ch}"))),
                                None => return Err(self.error("unterminated string")),
                            }
                        }
                        Some(ch) => {
                            self.bump();
                            s.push(ch);
                        }
                    }
                }
                Ok(Token::String(s))
            }
            c if c.is_ascii_digit() => Ok(Token::Int(self.read_number(c)?)),
            c if c.is_ascii_alphabetic() || c == '_' => {
                let ident = self.read_ident(c);
                Ok(match ident.as_str() {
                    "let" => Token::Let,
                    "fn" => Token::Fn,
                    "struct" => Token::Struct,
                    "enum" => Token::Enum,
                    "import" => Token::Import,
                    "if" => Token::If,
                    "else" => Token::Else,
                    "for" => Token::For,
                    "in" => Token::In,
                    "return" => Token::Return,
                    "emit" => Token::Emit,
                    "true" => Token::True,
                    "false" => Token::False,
                    _ => Token::Ident(ident),
                })
            }
            _ => Err(self.error(format!("unexpected character '{c}'"))),
        }
    }
}
