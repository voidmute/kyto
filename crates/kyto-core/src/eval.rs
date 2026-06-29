use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

use crate::ast::*;
use crate::error::{KytoError, KytoResult};
use crate::emit::EmitBundle;
use crate::parser;

#[derive(Debug, Clone)]
pub enum Value {
    Int(i64),
    Bool(bool),
    Str(String),
    Null,
    List(Vec<Value>),
    Map(BTreeMap<String, Value>),
    Struct {
        name: String,
        fields: BTreeMap<String, Value>,
    },
    Enum {
        enum_name: String,
        variant: String,
    },
}

#[derive(Clone)]
struct Function {
    params: Vec<String>,
    body: Vec<Stmt>,
}

#[derive(Default)]
struct ModuleScope {
    enums: BTreeMap<String, Vec<String>>,
    structs: BTreeMap<String, Vec<(String, TypeDesc)>>,
    vars: BTreeMap<String, Value>,
    fns: BTreeMap<String, Function>,
}

pub struct Evaluator {
    entry: PathBuf,
    repo_root: PathBuf,
    current: ModuleScope,
    modules: BTreeMap<String, ModuleScope>,
    emits: EmitBundle,
}

impl Evaluator {
    pub fn new(entry: PathBuf, repo_root: PathBuf) -> Self {
        Self {
            entry,
            repo_root,
            current: ModuleScope::default(),
            modules: BTreeMap::new(),
            emits: EmitBundle::default(),
        }
    }

    pub fn eval_program(&mut self, program: &Program) -> KytoResult<EmitBundle> {
        for item in &program.items {
            if let Item::Import { alias, path } = item {
                self.load_import(alias, path)?;
            }
        }
        for item in &program.items {
            match item {
                Item::Import { .. } => {}
                Item::Enum { name, variants } => {
                    self.current.enums.insert(name.clone(), variants.clone());
                }
                Item::Struct { name, fields } => {
                    self.current.structs.insert(name.clone(), fields.clone());
                }
                Item::Let { name, value, .. } => {
                    let v = self.eval_expr(value, &mut self.current.vars.clone())?;
                    self.current.vars.insert(name.clone(), v);
                }
                Item::Fn { name, params, body, .. } => {
                    self.current.fns.insert(
                        name.clone(),
                        Function {
                            params: params.iter().map(|(n, _)| n.clone()).collect(),
                            body: body.clone(),
                        },
                    );
                }
                Item::Emit { kind, expr } => {
                    let mut scope = self.current.vars.clone();
                    let v = self.eval_expr(expr, &mut scope)?;
                    self.emits.push(*kind, v)?;
                }
            }
        }
        Ok(std::mem::take(&mut self.emits))
    }

    fn load_import(&mut self, alias: &str, path: &str) -> KytoResult<()> {
        if self.modules.contains_key(alias) {
            return Ok(());
        }
        let base = self.entry.parent().unwrap_or(Path::new("."));
        let mut resolved = base.join(path);
        if !resolved.exists() {
            resolved = base.join(format!("{}.enc", path.trim_end_matches(".kyto")));
            if resolved.exists() {
                let plain = crate::crypto::decrypt_file(&resolved)?;
                let program = parser::parse(&plain)?;
                return self.eval_import_module(alias, program);
            }
            // optional local layer — use defaults
            let default_src = r#"
struct Secrets {
  domain: string
  session_secret: string
}
let secrets = Secrets { domain: "localhost", session_secret: "" }
"#;
            let program = parser::parse(default_src)?;
            return self.eval_import_module(alias, program);
        }
        let source = std::fs::read_to_string(&resolved)
            .map_err(|e| KytoError::Io(resolved.display().to_string(), e.to_string()))?;
        let program = parser::parse(&source)?;
        self.eval_import_module(alias, program)
    }

    fn eval_import_module(&mut self, alias: &str, program: Program) -> KytoResult<()> {
        let mut scope = ModuleScope::default();
        for item in program.items {
            match item {
                Item::Enum { name, variants } => {
                    scope.enums.insert(name, variants);
                }
                Item::Struct { name, fields } => {
                    scope.structs.insert(name, fields);
                }
                Item::Let { name, value, .. } => {
                    let v = self.eval_expr(&value, &mut scope.vars.clone())?;
                    scope.vars.insert(name, v);
                }
                _ => {}
            }
        }
        self.modules.insert(alias.to_string(), scope);
        Ok(())
    }

    fn eval_expr(&mut self, expr: &Expr, scope: &mut BTreeMap<String, Value>) -> KytoResult<Value> {
        match expr {
            Expr::Int(n) => Ok(Value::Int(*n)),
            Expr::Str(s) => Ok(Value::Str(s.clone())),
            Expr::Bool(b) => Ok(Value::Bool(*b)),
            Expr::Ident(name) => scope.get(name).cloned().or_else(|| self.lookup(name)).ok_or_else(|| {
                KytoError::Eval(format!("undefined variable '{name}'"))
            }),
            Expr::Field(obj, field) => {
                if let Expr::Ident(enum_name) = obj.as_ref() {
                    if self.current.enums.contains_key(enum_name) {
                        return Ok(Value::Enum {
                            enum_name: enum_name.clone(),
                            variant: field.clone(),
                        });
                    }
                    if let Some(mod_scope) = self.modules.get(enum_name) {
                        return mod_scope
                            .vars
                            .get(field)
                            .cloned()
                            .ok_or_else(|| KytoError::Eval(format!("{enum_name}.{field} not found")));
                    }
                }
                let v = self.eval_expr(obj, scope)?;
                match v {
                    Value::Struct { fields, .. } => fields
                        .get(field)
                        .cloned()
                        .ok_or_else(|| KytoError::Eval(format!("unknown field '{field}'"))),
                    Value::Map(m) => m
                        .get(field)
                        .cloned()
                        .ok_or_else(|| KytoError::Eval(format!("unknown map key '{field}'"))),
                    _ => Err(KytoError::Eval(format!("cannot access field '{field}'"))),
                }
            }
            Expr::EnumVariant { enum_name, variant } => Ok(Value::Enum {
                enum_name: enum_name.clone(),
                variant: variant.clone(),
            }),
            Expr::StructLit { name, fields } => {
                let mut map = BTreeMap::new();
                for (k, v) in fields {
                    map.insert(k.clone(), self.eval_expr(v, scope)?);
                }
                Ok(Value::Struct {
                    name: name.clone(),
                    fields: map,
                })
            }
            Expr::MapLit(fields) => {
                let mut map = BTreeMap::new();
                for (k, v) in fields {
                    map.insert(k.clone(), self.eval_expr(v, scope)?);
                }
                Ok(Value::Map(map))
            }
            Expr::ListLit(items) => {
                let mut list = Vec::new();
                for item in items {
                    list.push(self.eval_expr(item, scope)?);
                }
                Ok(Value::List(list))
            }
            Expr::Binary { left, op, right } => {
                let l = self.eval_expr(left, scope)?;
                let r = self.eval_expr(right, scope)?;
                match op {
                    BinOp::Add => match (l, r) {
                        (Value::Str(a), Value::Str(b)) => Ok(Value::Str(a + &b)),
                        (Value::Int(a), Value::Int(b)) => Ok(Value::Int(a + b)),
                        (a, b) => Err(KytoError::Eval(format!("cannot add {:?} and {:?}", a, b))),
                    },
                    BinOp::Eq => Ok(Value::Bool(values_equal(&l, &r))),
                }
            }
            Expr::NullCoalesce { left, right } => {
                let l = self.eval_expr(left, scope)?;
                if is_emptyish(&l) {
                    self.eval_expr(right, scope)
                } else {
                    Ok(l)
                }
            }
            Expr::Call { func, args } => self.call_builtin(func, args, scope),
        }
    }

    fn lookup(&self, name: &str) -> Option<Value> {
        self.current.vars.get(name).cloned()
    }

    fn call_builtin(
        &mut self,
        func: &str,
        args: &[Expr],
        scope: &mut BTreeMap<String, Value>,
    ) -> KytoResult<Value> {
        if func == "random_base64" {
            let n = if args.is_empty() {
                32
            } else {
                match self.eval_expr(&args[0], scope)? {
                    Value::Int(v) => v as usize,
                    _ => return Err(KytoError::Eval("random_base64 expects int".into())),
                }
            };
            return Ok(Value::Str(random_base64(n)));
        }
        if func == "len" {
            let v = self.eval_expr(&args[0], scope)?;
            return Ok(Value::Int(value_len(&v)));
        }
        if func == "require" {
            let cond = self.eval_expr(&args[0], scope)?;
            if !truthy(&cond) {
                let msg = if args.len() > 1 {
                    match self.eval_expr(&args[1], scope)? {
                        Value::Str(s) => s,
                        _ => "require failed".into(),
                    }
                } else {
                    "require failed".into()
                };
                return Err(KytoError::Eval(msg));
            }
            return Ok(Value::Null);
        }

        if let Some(fn_def) = self.current.fns.get(func).cloned() {
            let mut local = scope.clone();
            for (i, param) in fn_def.params.iter().enumerate() {
                let arg_val = if i < args.len() {
                    self.eval_expr(&args[i], scope)?
                } else {
                    Value::Null
                };
                local.insert(param.clone(), arg_val);
            }
            return self.eval_block(&fn_def.body, &mut local);
        }

        Err(KytoError::Eval(format!("unknown function '{func}'")))
    }

    fn eval_block(&mut self, stmts: &[Stmt], scope: &mut BTreeMap<String, Value>) -> KytoResult<Value> {
        let mut last = Value::Null;
        for stmt in stmts {
            last = self.eval_stmt(stmt, scope)?;
            if matches!(stmt, Stmt::Return(_)) {
                break;
            }
        }
        Ok(last)
    }

    fn eval_stmt(&mut self, stmt: &Stmt, scope: &mut BTreeMap<String, Value>) -> KytoResult<Value> {
        match stmt {
            Stmt::Let { name, value } => {
                let v = self.eval_expr(value, scope)?;
                scope.insert(name.clone(), v);
                Ok(Value::Null)
            }
            Stmt::Assign { name, value } => {
                let v = self.eval_expr(value, scope)?;
                scope.insert(name.clone(), v);
                Ok(Value::Null)
            }
            Stmt::Return(expr) => self.eval_expr(expr, scope),
            Stmt::If { cond, then_body, else_body } => {
                let c = self.eval_expr(cond, scope)?;
                if truthy(&c) {
                    self.eval_block(then_body, scope)
                } else {
                    self.eval_block(else_body, scope)
                }
            }
            Stmt::For { var, iter, body } => {
                let list = self.eval_expr(iter, scope)?;
                let items = match list {
                    Value::List(v) => v,
                    _ => return Err(KytoError::Eval("for expects list".into())),
                };
                let mut last = Value::Null;
                for item in items {
                    scope.insert(var.clone(), item);
                    last = self.eval_block(body, scope)?;
                }
                Ok(last)
            }
            Stmt::Expr(expr) => self.eval_expr(expr, scope),
        }
    }
}

fn random_base64(byte_len: usize) -> String {
    use base64::{engine::general_purpose::STANDARD, Engine as _};
    use rand::RngCore;
    let mut bytes = vec![0u8; byte_len];
    rand::thread_rng().fill_bytes(&mut bytes);
    STANDARD.encode(bytes)
}

fn is_emptyish(v: &Value) -> bool {
    match v {
        Value::Null => true,
        Value::Str(s) => s.is_empty(),
        _ => false,
    }
}

fn truthy(v: &Value) -> bool {
    match v {
        Value::Bool(b) => *b,
        Value::Null => false,
        Value::Str(s) => !s.is_empty(),
        Value::Int(n) => *n != 0,
        _ => true,
    }
}

fn values_equal(a: &Value, b: &Value) -> bool {
    match (a, b) {
        (Value::Int(x), Value::Int(y)) => x == y,
        (Value::Bool(x), Value::Bool(y)) => x == y,
        (Value::Str(x), Value::Str(y)) => x == y,
        (Value::Null, Value::Null) => true,
        _ => false,
    }
}

fn value_len(v: &Value) -> i64 {
    match v {
        Value::Str(s) => s.len() as i64,
        Value::List(l) => l.len() as i64,
        Value::Map(m) => m.len() as i64,
        _ => 0,
    }
}
