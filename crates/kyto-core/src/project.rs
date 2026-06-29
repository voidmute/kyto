use std::path::{Path, PathBuf};

use serde::Deserialize;

use crate::error::{KytoError, KytoResult};

pub const MANIFEST_NAME: &str = "kyto.toml";

#[derive(Debug, Clone, Deserialize)]
pub struct KytoManifest {
    #[serde(default)]
    pub project: ProjectSection,
    #[serde(default)]
    pub config: ConfigSection,
    #[serde(default)]
    pub emit: EmitSection,
}

#[derive(Debug, Clone, Deserialize, Default)]
pub struct ProjectSection {
    #[serde(default = "default_project_name")]
    pub name: String,
    #[serde(default = "default_entry")]
    pub entry: String,
}

#[derive(Debug, Clone, Deserialize, Default)]
pub struct ConfigSection {
    #[serde(default = "default_config_file")]
    pub file: String,
}

#[derive(Debug, Clone, Deserialize, Default)]
pub struct EmitSection {
    #[serde(default)]
    pub env: EnvEmit,
    #[serde(default)]
    pub users: UsersEmit,
    #[serde(default)]
    pub deploy: DeployEmit,
}

#[derive(Debug, Clone, Deserialize)]
pub struct EnvEmit {
    #[serde(default = "default_true")]
    pub enabled: bool,
    #[serde(default = "default_env_file")]
    pub file: String,
    #[serde(default = "default_env_example")]
    pub example: String,
    #[serde(default = "default_redact_keys")]
    pub redact_keys: Vec<String>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct UsersEmit {
    #[serde(default = "default_true")]
    pub enabled: bool,
    #[serde(default = "default_users_sql")]
    pub sql: String,
    #[serde(default = "default_users_sql_table")]
    pub sql_table: String,
    #[serde(default)]
    pub typescript: Option<String>,
    #[serde(default = "default_ts_export")]
    pub typescript_export: String,
    #[serde(default = "default_users_json")]
    pub json: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct DeployEmit {
    #[serde(default = "default_true")]
    pub enabled: bool,
    #[serde(default = "default_deploy_script")]
    pub script: String,
    #[serde(default)]
    pub apply_roles: Option<ApplyRolesHook>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ApplyRolesHook {
    #[serde(default = "default_true")]
    pub enabled: bool,
    #[serde(default)]
    pub command: String,
    #[serde(default = "default_admin_role")]
    pub admin_role: String,
    #[serde(default = "default_user_role")]
    pub user_role: String,
}

impl Default for KytoManifest {
    fn default() -> Self {
        Self {
            project: ProjectSection::default(),
            config: ConfigSection::default(),
            emit: EmitSection::default(),
        }
    }
}

impl Default for EnvEmit {
    fn default() -> Self {
        Self {
            enabled: true,
            file: default_env_file(),
            example: default_env_example(),
            redact_keys: default_redact_keys(),
        }
    }
}

impl Default for UsersEmit {
    fn default() -> Self {
        Self {
            enabled: true,
            sql: default_users_sql(),
            sql_table: default_users_sql_table(),
            typescript: Some("src/generated/users.ts".into()),
            typescript_export: default_ts_export(),
            json: default_users_json(),
        }
    }
}

impl Default for DeployEmit {
    fn default() -> Self {
        Self {
            enabled: true,
            script: default_deploy_script(),
            apply_roles: None,
        }
    }
}

pub fn find_project_root(start: &Path) -> PathBuf {
    let mut dir = if start.is_file() {
        start.parent().map(|p| p.to_path_buf()).unwrap_or_else(|| PathBuf::from("."))
    } else {
        start.to_path_buf()
    };

    for _ in 0..12 {
        if dir.join(MANIFEST_NAME).exists() {
            return dir;
        }
        if dir.join("package.json").exists() || dir.join("Cargo.toml").exists() {
            return dir;
        }
        if !dir.pop() {
            break;
        }
    }

    start
        .parent()
        .map(|p| p.to_path_buf())
        .unwrap_or_else(|| PathBuf::from("."))
}

pub fn load_manifest(repo_root: &Path) -> KytoResult<KytoManifest> {
    let path = repo_root.join(MANIFEST_NAME);
    if !path.exists() {
        return Ok(KytoManifest::default());
    }
    let source = std::fs::read_to_string(&path)
        .map_err(|e| KytoError::Io(path.display().to_string(), e.to_string()))?;
    toml::from_str(&source)
        .map_err(|e| KytoError::Eval(format!("{MANIFEST_NAME}: {e}")))
}

pub fn resolve_entry(repo_root: &Path, entry: Option<&Path>) -> PathBuf {
    if let Some(path) = entry {
        if path.is_absolute() {
            return path.to_path_buf();
        }
        if path.exists() {
            return path.to_path_buf();
        }
        let from_root = repo_root.join(path);
        if from_root.exists() {
            return from_root;
        }
        return path.to_path_buf();
    }

    let manifest = load_manifest(repo_root).unwrap_or_default();
    let candidate = repo_root.join(&manifest.project.entry);
    if candidate.exists() {
        return candidate;
    }
    repo_root.join(default_entry())
}

fn default_project_name() -> String {
    "my-project".into()
}
fn default_entry() -> String {
    "kyto/main.kyto".into()
}
fn default_config_file() -> String {
    ".kyto.config".into()
}
fn default_true() -> bool {
    true
}
fn default_env_file() -> String {
    ".env".into()
}
fn default_env_example() -> String {
    ".env.example".into()
}
fn default_redact_keys() -> Vec<String> {
    vec![
        "SECRET".into(),
        "TOKEN".into(),
        "PASSWORD".into(),
        "KEY".into(),
    ]
}
fn default_users_sql() -> String {
    "generated/users.sql".into()
}
fn default_users_sql_table() -> String {
    "users".into()
}
fn default_ts_export() -> String {
    "AUTHORIZED_USERS".into()
}
fn default_users_json() -> String {
    "generated/users.json".into()
}
fn default_deploy_script() -> String {
    "scripts/generated/deploy-env.sh".into()
}
fn default_admin_role() -> String {
    "ADMIN".into()
}
fn default_user_role() -> String {
    "USER".into()
}
