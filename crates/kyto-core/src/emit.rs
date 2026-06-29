use std::collections::BTreeMap;
use std::fs;
use std::path::Path;

use crate::ast::EmitKind;
use crate::error::{KytoError, KytoResult};
use crate::eval::Value;
use crate::project::KytoManifest;

#[derive(Debug, Default)]
pub struct EmitBundle {
    pub env: Option<BTreeMap<String, String>>,
    pub users: Option<Vec<UserRecord>>,
    pub deploy: Option<BTreeMap<String, String>>,
}

#[derive(Debug, Clone)]
pub struct UserRecord {
    pub name: String,
    pub role: String,
}

#[derive(Debug, Clone)]
pub struct EmitSummary {
    pub env_keys: usize,
    pub user_count: usize,
    pub deploy_keys: usize,
}

impl EmitBundle {
    pub fn push(&mut self, kind: EmitKind, value: Value) -> KytoResult<()> {
        match kind {
            EmitKind::Env => {
                self.env = Some(value_to_string_map(value)?);
            }
            EmitKind::Users => {
                self.users = Some(value_to_users(value)?);
            }
            EmitKind::Deploy => {
                self.deploy = Some(value_to_string_map(value)?);
            }
        }
        Ok(())
    }
}

fn value_to_string_map(value: Value) -> KytoResult<BTreeMap<String, String>> {
    match value {
        Value::Map(m) => {
            let mut out = BTreeMap::new();
            for (k, v) in m {
                out.insert(k, value_to_string(v)?);
            }
            Ok(out)
        }
        _ => Err(KytoError::Emit("expected map for env/deploy".into())),
    }
}

fn value_to_string(v: Value) -> KytoResult<String> {
    match v {
        Value::Str(s) => Ok(s),
        Value::Int(n) => Ok(n.to_string()),
        Value::Bool(b) => Ok(b.to_string()),
        _ => Err(KytoError::Emit("expected string value".into())),
    }
}

fn value_to_users(value: Value) -> KytoResult<Vec<UserRecord>> {
    match value {
        Value::List(items) => {
            let mut users = Vec::new();
            for item in items {
                users.push(parse_user(item)?);
            }
            Ok(users)
        }
        _ => Err(KytoError::Emit("expected user list".into())),
    }
}

fn parse_user(value: Value) -> KytoResult<UserRecord> {
    match value {
        Value::Struct { fields, .. } => {
            let name = fields
                .get("name")
                .and_then(|v| match v {
                    Value::Str(s) => Some(s.clone()),
                    _ => None,
                })
                .ok_or_else(|| KytoError::Emit("user missing name".into()))?;
            let role = fields
                .get("role")
                .map(role_to_db)
                .unwrap_or_else(|| "USER".into());
            Ok(UserRecord { name, role })
        }
        _ => Err(KytoError::Emit("expected User struct".into())),
    }
}

fn role_to_db(v: &Value) -> String {
    match v {
        Value::Enum { variant, .. } => {
            if variant.eq_ignore_ascii_case("admin") {
                "ADMIN".into()
            } else {
                "USER".into()
            }
        }
        Value::Str(s) => s.to_uppercase(),
        _ => "USER".into(),
    }
}

pub fn write_artifacts(
    repo_root: &Path,
    manifest: &KytoManifest,
    bundle: &EmitBundle,
) -> KytoResult<EmitSummary> {
    if manifest.emit.env.enabled {
        if let Some(env) = &bundle.env {
            write_env(repo_root, &manifest.emit.env, env)?;
        }
    }
    if manifest.emit.users.enabled {
        if let Some(users) = &bundle.users {
            write_users(repo_root, &manifest.emit.users, users)?;
        }
    }
    if manifest.emit.deploy.enabled {
        if let Some(deploy) = &bundle.deploy {
            write_deploy(
                repo_root,
                &manifest.emit.deploy,
                deploy,
                bundle.users.as_deref(),
            )?;
        }
    }
    Ok(EmitSummary {
        env_keys: bundle.env.as_ref().map(|m| m.len()).unwrap_or(0),
        user_count: bundle.users.as_ref().map(|u| u.len()).unwrap_or(0),
        deploy_keys: bundle.deploy.as_ref().map(|m| m.len()).unwrap_or(0),
    })
}

fn write_env(
    repo_root: &Path,
    cfg: &crate::project::EnvEmit,
    env: &BTreeMap<String, String>,
) -> KytoResult<()> {
    let mut lines = Vec::new();
    let mut example = Vec::new();
    for (k, v) in env {
        lines.push(format!("{k}={v}"));
        let redacted = if cfg
            .redact_keys
            .iter()
            .any(|needle| k.to_ascii_uppercase().contains(needle))
        {
            "changeme".into()
        } else {
            v.clone()
        };
        example.push(format!("{k}={redacted}"));
    }
    let env_path = repo_root.join(&cfg.file);
    let example_path = repo_root.join(&cfg.example);
    if let Some(parent) = env_path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| KytoError::Io(parent.display().to_string(), e.to_string()))?;
    }
    fs::write(&env_path, lines.join("\n") + "\n")
        .map_err(|e| KytoError::Io(env_path.display().to_string(), e.to_string()))?;
    fs::write(&example_path, example.join("\n") + "\n")
        .map_err(|e| KytoError::Io(example_path.display().to_string(), e.to_string()))?;
    Ok(())
}

fn write_users(
    repo_root: &Path,
    cfg: &crate::project::UsersEmit,
    users: &[UserRecord],
) -> KytoResult<()> {
    let sql_path = repo_root.join(&cfg.sql);
    if let Some(parent) = sql_path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| KytoError::Io(parent.display().to_string(), e.to_string()))?;
    }

    let mut sql = format!(
        "INSERT INTO {} (name, role, is_totp_setup, totp_secret)\nVALUES\n",
        cfg.sql_table
    );
    let values: Vec<String> = users
        .iter()
        .map(|u| format!("  ('{}', '{}', false, NULL)", escape_sql(&u.name), u.role))
        .collect();
    sql.push_str(&values.join(",\n"));
    sql.push_str("\nON CONFLICT (name) DO NOTHING;\n");
    fs::write(&sql_path, sql)
        .map_err(|e| KytoError::Io(sql_path.display().to_string(), e.to_string()))?;

    if let Some(ts_rel) = &cfg.typescript {
        let names: Vec<&str> = users.iter().map(|u| u.name.as_str()).collect();
        let ts_users: Vec<String> = users
            .iter()
            .map(|u| {
                format!(
                    "  {{ name: \"{}\", role: \"{}\" as const }},",
                    escape_ts(&u.name),
                    u.role
                )
            })
            .collect();
        let export = &cfg.typescript_export;
        let names_export = format!("{}_NAMES", export.trim_end_matches("_USERS"));
        let ts = format!(
            "// Generated by Kyto - do not edit.\n\nexport const {export} = [\n{}\n] as const;\n\nexport const {names_export} = [\n{}\n] as const;\n\nexport type AuthorizedUser = (typeof {export})[number];\n",
            ts_users.join("\n"),
            names
                .iter()
                .map(|n| format!("  \"{}\"", escape_ts(n)))
                .collect::<Vec<_>>()
                .join(",\n"),
        );
        let ts_path = repo_root.join(ts_rel);
        if let Some(parent) = ts_path.parent() {
            fs::create_dir_all(parent)
                .map_err(|e| KytoError::Io(parent.display().to_string(), e.to_string()))?;
        }
        fs::write(&ts_path, ts)
            .map_err(|e| KytoError::Io(ts_path.display().to_string(), e.to_string()))?;
    }

    let json_path = repo_root.join(&cfg.json);
    if let Some(parent) = json_path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| KytoError::Io(parent.display().to_string(), e.to_string()))?;
    }
    let names: Vec<String> = users.iter().map(|u| u.name.clone()).collect();
    let json = format!(
        "[{}]\n",
        names
            .iter()
            .map(|n| format!("\"{}\"", escape_ts(n)))
            .collect::<Vec<_>>()
            .join(", ")
    );
    fs::write(&json_path, json)
        .map_err(|e| KytoError::Io(json_path.display().to_string(), e.to_string()))?;
    Ok(())
}

fn write_deploy(
    repo_root: &Path,
    cfg: &crate::project::DeployEmit,
    deploy: &BTreeMap<String, String>,
    users: Option<&[UserRecord]>,
) -> KytoResult<()> {
    let path = repo_root.join(&cfg.script);
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| KytoError::Io(parent.display().to_string(), e.to_string()))?;
    }

    let mut lines = vec![
        "#!/usr/bin/env bash".into(),
        "# Generated by Kyto - do not edit.".into(),
        "".into(),
    ];
    for (k, v) in deploy {
        lines.push(format!("export {}=\"{}\"", k.to_uppercase(), escape_sh(v)));
    }

    if let Some(hook) = &cfg.apply_roles {
        if hook.enabled {
            if let Some(users) = users {
                if !hook.command.is_empty() {
                    lines.push("".into());
                    lines.push("apply_user_roles() {".into());
                    lines.push(format!("  {} <<'SQL'", hook.command));
                    for u in users {
                        if u.role == hook.admin_role {
                            lines.push(format!(
                                "UPDATE users SET role = '{}' WHERE name = '{}';",
                                escape_sql(&hook.admin_role),
                                escape_sql(&u.name)
                            ));
                        }
                    }
                    let user_names: Vec<String> = users
                        .iter()
                        .filter(|u| u.role != hook.admin_role)
                        .map(|u| format!("'{}'", escape_sql(&u.name)))
                        .collect();
                    if !user_names.is_empty() {
                        lines.push(format!(
                            "UPDATE users SET role = '{}' WHERE name IN ({});",
                            escape_sql(&hook.user_role),
                            user_names.join(", ")
                        ));
                    }
                    lines.push("SQL".into());
                    lines.push("}".into());
                }
            }
        }
    }

    fs::write(&path, lines.join("\n") + "\n")
        .map_err(|e| KytoError::Io(path.display().to_string(), e.to_string()))?;
    Ok(())
}

fn escape_sql(s: &str) -> String {
    s.replace('\'', "''")
}

fn escape_ts(s: &str) -> String {
    s.replace('\\', "\\\\").replace('"', "\\\"")
}

fn escape_sh(s: &str) -> String {
    s.replace('\\', "\\\\").replace('"', "\\\"")
}
