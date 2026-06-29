pub mod ast;
pub mod config;
pub mod crypto;
pub mod emit;
pub mod error;
pub mod eval;
pub mod lexer;
pub mod parser;
pub mod project;

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

pub use error::{KytoError, KytoResult};
pub use project::{KytoManifest, MANIFEST_NAME};

#[derive(Debug, Clone)]
pub struct CompileOptions {
    pub entry: PathBuf,
    pub repo_root: PathBuf,
    pub manifest: KytoManifest,
    pub write: bool,
}

impl CompileOptions {
    pub fn from_repo(repo_root: PathBuf) -> KytoResult<Self> {
        let manifest = project::load_manifest(&repo_root)?;
        let entry = if project::is_config_only(&manifest, &repo_root) {
            repo_root.join(&manifest.project.entry)
        } else {
            project::resolve_entry(&repo_root, None)
        };
        Ok(Self {
            entry,
            repo_root,
            manifest,
            write: true,
        })
    }

    pub fn from_entry(entry: PathBuf) -> KytoResult<Self> {
        let repo_root = project::find_project_root(&entry);
        let manifest = project::load_manifest(&repo_root)?;
        Ok(Self {
            entry,
            repo_root,
            manifest,
            write: true,
        })
    }
}

pub fn check_at(repo_root: &Path) -> KytoResult<()> {
    let mut opts = CompileOptions::from_repo(repo_root.to_path_buf())?;
    opts.write = false;
    compile_with_options(&opts)?;
    Ok(())
}

pub fn check(entry: &Path) -> KytoResult<()> {
    let mut opts = CompileOptions::from_entry(entry.to_path_buf())?;
    opts.write = false;
    compile_with_options(&opts)?;
    Ok(())
}

pub fn compile_at(repo_root: &Path) -> KytoResult<emit::EmitSummary> {
    let opts = CompileOptions::from_repo(repo_root.to_path_buf())?;
    compile_with_options(&opts)
}

pub fn compile(entry: &Path) -> KytoResult<emit::EmitSummary> {
    let opts = CompileOptions::from_entry(entry.to_path_buf())?;
    compile_with_options(&opts)
}

fn compile_with_options(opts: &CompileOptions) -> KytoResult<emit::EmitSummary> {
    if project::is_config_only(&opts.manifest, &opts.repo_root) {
        return compile_config_only(opts);
    }

    let source = read_entry_source(&opts.entry)?;
    let program = parser::parse(&source)?;
    let mut evaluator = eval::Evaluator::new(opts.entry.clone(), opts.repo_root.clone());
    let mut emits = evaluator.eval_program(&program)?;
    config::load_and_apply(&opts.repo_root, &opts.manifest.config.file, &mut emits)?;
    finish_compile(opts, emits)
}

fn compile_config_only(opts: &CompileOptions) -> KytoResult<emit::EmitSummary> {
    let mut emits = emit::EmitBundle::default();
    if let Some(cfg) = config::load_config(&opts.repo_root, &opts.manifest.config.file)? {
        config::apply_config(&cfg, &mut emits)?;
    }
    if emits.env.is_none() {
        emits.env = Some(BTreeMap::new());
    }
    finish_compile(opts, emits)
}

fn finish_compile(opts: &CompileOptions, emits: emit::EmitBundle) -> KytoResult<emit::EmitSummary> {
    if opts.write {
        emit::write_artifacts(&opts.repo_root, &opts.manifest, &emits)
    } else {
        Ok(emit::EmitSummary {
            env_keys: emits.env.as_ref().map(|m| m.len()).unwrap_or(0),
            user_count: emits.users.as_ref().map(|u| u.len()).unwrap_or(0),
            deploy_keys: emits.deploy.as_ref().map(|m| m.len()).unwrap_or(0),
        })
    }
}

fn read_entry_source(entry: &Path) -> KytoResult<String> {
    if entry.exists() {
        return std::fs::read_to_string(entry)
            .map_err(|e| KytoError::Io(entry.display().to_string(), e.to_string()));
    }
    let enc = entry.with_extension("kyto.enc");
    if enc.exists() {
        return crypto::decrypt_file(&enc);
    }
    Err(KytoError::MissingFile(entry.display().to_string()))
}

pub fn encrypt_file(input: &Path, output: &Path) -> KytoResult<()> {
    crypto::encrypt_file(input, output)
}

pub fn decrypt_file_to(input: &Path, output: &Path) -> KytoResult<()> {
    let plain = crypto::decrypt_file(input)?;
    std::fs::write(output, plain)
        .map_err(|e| KytoError::Io(output.display().to_string(), e.to_string()))
}

pub fn init_project(repo_root: &Path, name: &str) -> KytoResult<()> {
    let manifest_path = repo_root.join(MANIFEST_NAME);
    if manifest_path.exists() {
        return Err(KytoError::Eval(format!("{MANIFEST_NAME} already exists")));
    }

    let manifest = format!(
        r#"[project]
name = "{name}"
config_only = true

[config]
file = ".kyto.config"

[emit.env]
file = ".env"
example = ".env.example"

[emit.users]
sql = "generated/users.sql"
typescript = "src/generated/users.ts"
typescript_export = "AUTHORIZED_USERS"
json = "generated/users.json"

[emit.deploy]
script = "scripts/generated/deploy-env.sh"
"#
    );
    std::fs::write(&manifest_path, manifest)
        .map_err(|e| KytoError::Io(manifest_path.display().to_string(), e.to_string()))?;

    let config_example = repo_root.join(".kyto.config.example");
    std::fs::write(
        &config_example,
        "+ Edit and run: kura compile\nDOMAIN localhost\nADMIN admin\nUSERS admin\nNODE_ENV development\n",
    )
    .map_err(|e| KytoError::Io(config_example.display().to_string(), e.to_string()))?;

    Ok(())
}
