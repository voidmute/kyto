#[derive(Debug, Clone)]
pub enum TypeDesc {
    Named(String),
    String,
    Int,
    Bool,
    List(Box<TypeDesc>),
    Map { value: Box<TypeDesc> },
}

#[derive(Debug, Clone)]
pub enum Item {
    Import { alias: String, path: String },
    Enum { name: String, variants: Vec<String> },
    Struct { name: String, fields: Vec<(String, TypeDesc)> },
    Let { name: String, ty: Option<TypeDesc>, value: Expr },
    Fn {
        name: String,
        params: Vec<(String, TypeDesc)>,
        ret: TypeDesc,
        body: Vec<Stmt>,
    },
    Emit { kind: EmitKind, expr: Expr },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EmitKind {
    Env,
    Users,
    Deploy,
}

#[derive(Debug, Clone)]
pub enum Stmt {
    Let { name: String, value: Expr },
    Assign { name: String, value: Expr },
    Return(Expr),
    If {
        cond: Expr,
        then_body: Vec<Stmt>,
        else_body: Vec<Stmt>,
    },
    For {
        var: String,
        iter: Expr,
        body: Vec<Stmt>,
    },
    Expr(Expr),
}

#[derive(Debug, Clone)]
pub enum Expr {
    Int(i64),
    Str(String),
    Bool(bool),
    Ident(String),
    Field(Box<Expr>, String),
    EnumVariant { enum_name: String, variant: String },
    StructLit {
        name: String,
        fields: Vec<(String, Expr)>,
    },
    MapLit(Vec<(String, Expr)>),
    ListLit(Vec<Expr>),
    Binary {
        left: Box<Expr>,
        op: BinOp,
        right: Box<Expr>,
    },
    NullCoalesce {
        left: Box<Expr>,
        right: Box<Expr>,
    },
    Call { func: String, args: Vec<Expr> },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BinOp {
    Add,
    Eq,
}

#[derive(Debug, Clone)]
pub struct Program {
    pub items: Vec<Item>,
}
