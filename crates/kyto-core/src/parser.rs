use crate::ast::*;
use crate::error::{KytoError, KytoResult};
use crate::lexer::{Lexer, Token};

pub fn parse(source: &str) -> KytoResult<Program> {
    let tokens = Lexer::new(source).tokenize()?;
    let mut p = Parser { tokens, pos: 0 };
    let mut items = Vec::new();
    while !p.is_at(Token::Eof) {
        items.push(p.parse_item()?);
    }
    Ok(Program { items })
}

struct Parser {
    tokens: Vec<Token>,
    pos: usize,
}

impl Parser {
    fn peek(&self) -> &Token {
        self.tokens.get(self.pos).unwrap_or(&Token::Eof)
    }

    fn bump(&mut self) -> Token {
        let t = self.peek().clone();
        if !matches!(t, Token::Eof) {
            self.pos += 1;
        }
        t
    }

    fn expect(&mut self, expected: Token) -> KytoResult<()> {
        let t = self.bump();
        if std::mem::discriminant(&t) == std::mem::discriminant(&expected) {
            Ok(())
        } else {
            Err(KytoError::Parse {
                line: 1,
                col: 1,
                msg: format!("expected token, got {:?}", t),
            })
        }
    }

    fn is_at(&self, tok: Token) -> bool {
        std::mem::discriminant(self.peek()) == std::mem::discriminant(&tok)
    }

    fn parse_item(&mut self) -> KytoResult<Item> {
        match self.peek() {
            Token::Import => self.parse_import(),
            Token::Enum => self.parse_enum(),
            Token::Struct => self.parse_struct(),
            Token::Let => self.parse_let_item(),
            Token::Fn => self.parse_fn_item(),
            Token::Emit => self.parse_emit(),
            other => Err(KytoError::Parse {
                line: 1,
                col: 1,
                msg: format!("unexpected item start: {:?}", other),
            }),
        }
    }

    fn parse_import(&mut self) -> KytoResult<Item> {
        self.bump();
        let Token::Ident(alias) = self.bump() else {
            return Err(KytoError::Parse {
                line: 1,
                col: 1,
                msg: "expected import alias".into(),
            });
        };
        let Token::Ident(from_kw) = self.bump() else {
            return Err(KytoError::Parse {
                line: 1,
                col: 1,
                msg: "expected 'from'".into(),
            });
        };
        if from_kw != "from" {
            return Err(KytoError::Parse {
                line: 1,
                col: 1,
                msg: "expected 'from'".into(),
            });
        }
        let Token::String(path) = self.bump() else {
            return Err(KytoError::Parse {
                line: 1,
                col: 1,
                msg: "expected import path string".into(),
            });
        };
        Ok(Item::Import { alias, path })
    }

    fn parse_enum(&mut self) -> KytoResult<Item> {
        self.bump();
        let Token::Ident(name) = self.bump() else {
            return Err(KytoError::Parse {
                line: 1,
                col: 1,
                msg: "expected enum name".into(),
            });
        };
        self.expect(Token::LBrace)?;
        let mut variants = Vec::new();
        while !self.is_at(Token::RBrace) {
            if let Token::Ident(v) = self.bump() {
                variants.push(v);
            }
            if self.is_at(Token::Comma) {
                self.bump();
            }
        }
        self.expect(Token::RBrace)?;
        Ok(Item::Enum { name, variants })
    }

    fn parse_struct(&mut self) -> KytoResult<Item> {
        self.bump();
        let Token::Ident(name) = self.bump() else {
            return Err(KytoError::Parse {
                line: 1,
                col: 1,
                msg: "expected struct name".into(),
            });
        };
        self.expect(Token::LBrace)?;
        let mut fields = Vec::new();
        while !self.is_at(Token::RBrace) {
            let Token::Ident(field) = self.bump() else {
                return Err(KytoError::Parse {
                    line: 1,
                    col: 1,
                    msg: "expected field name".into(),
                });
            };
            self.expect(Token::Colon)?;
            let ty = self.parse_type()?;
            fields.push((field, ty));
            if self.is_at(Token::Comma) {
                self.bump();
            }
        }
        self.expect(Token::RBrace)?;
        Ok(Item::Struct { name, fields })
    }

    fn parse_type(&mut self) -> KytoResult<TypeDesc> {
        if let Token::Ident(name) = self.peek().clone() {
            if name == "string" {
                self.bump();
                return Ok(TypeDesc::String);
            }
            if name == "int" {
                self.bump();
                return Ok(TypeDesc::Int);
            }
            if name == "bool" {
                self.bump();
                return Ok(TypeDesc::Bool);
            }
            if name == "map" {
                self.bump();
                self.expect(Token::Lt)?;
                let Token::Ident(k) = self.bump() else {
                    return Err(KytoError::Parse {
                        line: 1,
                        col: 1,
                        msg: "expected map key type".into(),
                    });
                };
                if k != "string" {
                    return Err(KytoError::Parse {
                        line: 1,
                        col: 1,
                        msg: "only map<string, T> supported".into(),
                    });
                }
                self.expect(Token::Comma)?;
                let value = self.parse_type()?;
                self.expect(Token::Gt)?;
                return Ok(TypeDesc::Map {
                    value: Box::new(value),
                });
            }
            self.bump();
            if self.is_at(Token::LBracket) {
                self.bump();
                self.expect(Token::RBracket)?;
                return Ok(TypeDesc::List(Box::new(TypeDesc::Named(name))));
            }
            return Ok(TypeDesc::Named(name));
        }
        Err(KytoError::Parse {
            line: 1,
            col: 1,
            msg: "expected type".into(),
        })
    }

    fn parse_let_item(&mut self) -> KytoResult<Item> {
        self.bump();
        let Token::Ident(name) = self.bump() else {
            return Err(KytoError::Parse {
                line: 1,
                col: 1,
                msg: "expected let name".into(),
            });
        };
        let ty = if self.is_at(Token::Colon) {
            self.bump();
            Some(self.parse_type()?)
        } else {
            None
        };
        self.expect(Token::Assign)?;
        let value = self.parse_expr(0)?;
        Ok(Item::Let { name, ty, value })
    }

    fn parse_fn_item(&mut self) -> KytoResult<Item> {
        self.bump();
        let Token::Ident(name) = self.bump() else {
            return Err(KytoError::Parse {
                line: 1,
                col: 1,
                msg: "expected fn name".into(),
            });
        };
        self.expect(Token::LParen)?;
        let mut params = Vec::new();
        while !self.is_at(Token::RParen) {
            let Token::Ident(param) = self.bump() else {
                return Err(KytoError::Parse {
                    line: 1,
                    col: 1,
                    msg: "expected param name".into(),
                });
            };
            let ty = if self.is_at(Token::Colon) {
                self.bump();
                self.parse_type()?
            } else {
                TypeDesc::Named("_".into())
            };
            params.push((param, ty));
            if self.is_at(Token::Comma) {
                self.bump();
            }
        }
        self.bump();
        self.expect(Token::Arrow)?;
        let ret = self.parse_type()?;
        self.expect(Token::LBrace)?;
        let body = self.parse_block_stmts()?;
        Ok(Item::Fn {
            name,
            params,
            ret,
            body,
        })
    }

    fn parse_emit(&mut self) -> KytoResult<Item> {
        self.bump();
        let kind = match self.bump() {
            Token::Ident(s) if s == "env" => EmitKind::Env,
            Token::Ident(s) if s == "users" => EmitKind::Users,
            Token::Ident(s) if s == "deploy" => EmitKind::Deploy,
            other => {
                return Err(KytoError::Parse {
                    line: 1,
                    col: 1,
                    msg: format!("unknown emit kind: {:?}", other),
                })
            }
        };
        self.expect(Token::LParen)?;
        let expr = self.parse_expr(0)?;
        self.expect(Token::RParen)?;
        Ok(Item::Emit { kind, expr })
    }

    fn parse_block_stmts(&mut self) -> KytoResult<Vec<Stmt>> {
        let mut stmts = Vec::new();
        while !self.is_at(Token::RBrace) && !self.is_at(Token::Eof) {
            stmts.push(self.parse_stmt()?);
        }
        self.expect(Token::RBrace)?;
        Ok(stmts)
    }

    fn parse_block_stmts_inner(&mut self) -> KytoResult<Vec<Stmt>> {
        let mut stmts = Vec::new();
        while !self.is_at(Token::RBrace) && !self.is_at(Token::Eof) {
            stmts.push(self.parse_stmt()?);
        }
        self.bump();
        Ok(stmts)
    }

    fn parse_stmt(&mut self) -> KytoResult<Stmt> {
        match self.peek() {
            Token::Let => {
                self.bump();
                let Token::Ident(name) = self.bump() else {
                    return Err(KytoError::Parse {
                        line: 1,
                        col: 1,
                        msg: "expected let name".into(),
                    });
                };
                self.expect(Token::Assign)?;
                let value = self.parse_expr(0)?;
                Ok(Stmt::Let { name, value })
            }
            Token::Return => {
                self.bump();
                let expr = self.parse_expr(0)?;
                Ok(Stmt::Return(expr))
            }
            Token::If => {
                self.bump();
                let cond = self.parse_expr(0)?;
                self.expect(Token::LBrace)?;
                let then_body = self.parse_block_stmts_inner()?;
                let else_body = if self.is_at(Token::Else) {
                    self.bump();
                    self.expect(Token::LBrace)?;
                    self.parse_block_stmts_inner()?
                } else {
                    Vec::new()
                };
                Ok(Stmt::If {
                    cond,
                    then_body,
                    else_body,
                })
            }
            Token::For => {
                self.bump();
                let Token::Ident(var) = self.bump() else {
                    return Err(KytoError::Parse {
                        line: 1,
                        col: 1,
                        msg: "expected for var".into(),
                    });
                };
                let Token::Ident(in_kw) = self.bump() else {
                    return Err(KytoError::Parse {
                        line: 1,
                        col: 1,
                        msg: "expected 'in'".into(),
                    });
                };
                if in_kw != "in" {
                    return Err(KytoError::Parse {
                        line: 1,
                        col: 1,
                        msg: "expected 'in'".into(),
                    });
                }
                let iter = self.parse_expr(0)?;
                self.expect(Token::LBrace)?;
                let body = self.parse_block_stmts_inner()?;
                Ok(Stmt::For { var, iter, body })
            }
            _ => {
                if let Token::Ident(name) = self.peek().clone() {
                    let next_pos = self.pos + 1;
                    if matches!(self.tokens.get(next_pos), Some(Token::Assign)) {
                        self.bump();
                        self.bump();
                        let value = self.parse_expr(0)?;
                        return Ok(Stmt::Assign { name, value });
                    }
                }
                let expr = self.parse_expr(0)?;
                Ok(Stmt::Expr(expr))
            }
        }
    }

    fn parse_expr(&mut self, min_bp: u8) -> KytoResult<Expr> {
        let mut left = self.parse_prefix()?;
        loop {
            if self.is_at(Token::QuestionQuestion) {
                if 1 < min_bp {
                    break;
                }
                self.bump();
                let right = self.parse_expr(2)?;
                left = Expr::NullCoalesce {
                    left: Box::new(left),
                    right: Box::new(right),
                };
                continue;
            }
            if self.is_at(Token::Plus) {
                if 3 < min_bp {
                    break;
                }
                self.bump();
                let right = self.parse_expr(4)?;
                left = Expr::Binary {
                    left: Box::new(left),
                    op: BinOp::Add,
                    right: Box::new(right),
                };
                continue;
            }
            if self.is_at(Token::Eq) {
                if 5 < min_bp {
                    break;
                }
                self.bump();
                let right = self.parse_expr(6)?;
                left = Expr::Binary {
                    left: Box::new(left),
                    op: BinOp::Eq,
                    right: Box::new(right),
                };
                continue;
            }
            if self.is_at(Token::Dot) {
                self.bump();
                let Token::Ident(field) = self.bump() else {
                    return Err(KytoError::Parse {
                        line: 1,
                        col: 1,
                        msg: "expected field name".into(),
                    });
                };
                left = Expr::Field(Box::new(left), field);
                continue;
            }
            if self.is_at(Token::LParen) {
                if let Expr::Ident(func) = left {
                    self.bump();
                    let mut args = Vec::new();
                    while !self.is_at(Token::RParen) {
                        args.push(self.parse_expr(0)?);
                        if self.is_at(Token::Comma) {
                            self.bump();
                        }
                    }
                    self.bump();
                    left = Expr::Call { func, args };
                    continue;
                }
            }
            break;
        }
        Ok(left)
    }

    fn parse_prefix(&mut self) -> KytoResult<Expr> {
        match self.bump() {
            Token::Int(n) => Ok(Expr::Int(n)),
            Token::String(s) => Ok(Expr::Str(s)),
            Token::True => Ok(Expr::Bool(true)),
            Token::False => Ok(Expr::Bool(false)),
            Token::Ident(name) => {
                if self.is_at(Token::LBrace) {
                    self.bump();
                    let mut fields = Vec::new();
                    while !self.is_at(Token::RBrace) {
                        let Token::Ident(field) = self.bump() else {
                            return Err(KytoError::Parse {
                                line: 1,
                                col: 1,
                                msg: "expected field".into(),
                            });
                        };
                        self.expect(Token::Colon)?;
                        fields.push((field, self.parse_expr(0)?));
                        if self.is_at(Token::Comma) {
                            self.bump();
                        }
                    }
                    self.bump();
                    return Ok(Expr::StructLit { name, fields });
                }
                Ok(Expr::Ident(name))
            }
            Token::LBrace => {
                let mut fields = Vec::new();
                while !self.is_at(Token::RBrace) {
                    let key = match self.bump() {
                        Token::Ident(k) => k,
                        Token::String(k) => k,
                        other => {
                            return Err(KytoError::Parse {
                                line: 1,
                                col: 1,
                                msg: format!("expected map key, got {:?}", other),
                            });
                        }
                    };
                    self.expect(Token::Colon)?;
                    fields.push((key, self.parse_expr(0)?));
                    if self.is_at(Token::Comma) {
                        self.bump();
                    }
                }
                self.bump();
                Ok(Expr::MapLit(fields))
            }
            Token::LBracket => {
                let mut items = Vec::new();
                while !self.is_at(Token::RBracket) {
                    items.push(self.parse_expr(0)?);
                    if self.is_at(Token::Comma) {
                        self.bump();
                    }
                }
                self.bump();
                Ok(Expr::ListLit(items))
            }
            other => Err(KytoError::Parse {
                line: 1,
                col: 1,
                msg: format!("unexpected expr: {:?}", other),
            }),
        }
    }
}
