use std::collections::{BTreeMap, HashSet};
use std::path::Path;

use base64::{engine::general_purpose::STANDARD, Engine as _};
use rand::RngCore;

use crate::emit::{EmitBundle, UserRecord};
use crate::error::{KytoError, KytoResult};

#[derive(Debug, Default, Clone)]
pub struct KytoConfig {
    pub domain: Option<String>,
    pub user_names: Vec<String>,
    pub admin_names: Vec<String>,
    pub extra: BTreeMap<String, String>,
}

impl KytoConfig {
    pub fn into_user_records(self) -> KytoResult<Vec<UserRecord>> {
        if self.user_names.is_empty() {
            return Err(KytoError::Eval(
                ".kyto.config: USERS must list at least one name".into(),
            ));
        }

        for admin in &self.admin_names {
            if !self.user_names.iter().any(|u| u == admin) {
                return Err(KytoError::Eval(format!(
                    ".kyto.config: ADMIN '{admin}' is not listed in USERS"
                )));
            }
        }

        let admins: HashSet<&str> = self.admin_names.iter().map(|s| s.as_str()).collect();
        Ok(self
            .user_names
            .into_iter()
            .map(|name| UserRecord {
                role: if admins.contains(name.as_str()) {
                    "ADMIN".into()
                } else {
                    "USER".into()
                },
                name,
            })
            .collect())
    }

    pub fn env_overlay(&self) -> KytoResult<BTreeMap<String, String>> {
        let mut env = self.extra.clone();
        if let Some(domain) = &self.domain {
            env.insert("APP_URL".into(), format!("https://{domain}"));
        }
        let secret = env.get("SESSION_SECRET").cloned().unwrap_or_default();
        if secret.is_empty() {
            env.insert("SESSION_SECRET".into(), random_base64(32));
        }
        Ok(env)
    }

    pub fn deploy_map(&self) -> BTreeMap<String, String> {
        let mut deploy = BTreeMap::new();
        for (key, value) in &self.extra {
            if let Some(rest) = key.strip_prefix("REPO_") {
                deploy.insert(rest.to_ascii_lowercase(), value.clone());
            }
        }
        deploy
    }
}

pub fn parse(source: &str) -> KytoResult<KytoConfig> {
    let mut cfg = KytoConfig::default();

    for (idx, raw) in source.lines().enumerate() {
        let line_num = idx + 1;
        let line = strip_comment(raw).trim();
        if line.is_empty() {
            continue;
        }

        let (keyword, value) = split_key_value(line)
            .ok_or_else(|| config_error(line_num, "empty directive"))?;
        let keyword_upper = keyword.to_ascii_uppercase();

        match keyword_upper.as_str() {
            "DOMAIN" => {
                if value.is_empty() {
                    return Err(config_error(line_num, "DOMAIN requires a host"));
                }
                if value.contains(' ') {
                    return Err(config_error(line_num, "DOMAIN accepts only one host value"));
                }
                cfg.domain = Some(value.to_ascii_lowercase());
            }
            "USERS" => {
                let names = parse_name_list(&value);
                if names.is_empty() {
                    return Err(config_error(line_num, "USERS requires at least one name"));
                }
                cfg.user_names = dedupe(names);
            }
            "ADMIN" => {
                let names = parse_name_list(&value);
                if names.is_empty() {
                    return Err(config_error(line_num, "ADMIN requires at least one name"));
                }
                cfg.admin_names = dedupe(names);
            }
            _ => {
                cfg.extra
                    .insert(keyword_upper, parse_quoted_value(&value));
            }
        }
    }

    Ok(cfg)
}

pub fn load_and_apply(
    repo_root: &Path,
    config_file: &str,
    bundle: &mut EmitBundle,
) -> KytoResult<()> {
    let cfg = load_config(repo_root, config_file)?;
    let Some(cfg) = cfg else {
        return Ok(());
    };
    apply_config(&cfg, bundle)
}

pub fn load_config(repo_root: &Path, config_file: &str) -> KytoResult<Option<KytoConfig>> {
    let path = repo_root.join(config_file);
    if !path.exists() {
        let example = repo_root.join(format!("{config_file}.example"));
        if example.exists() {
            std::fs::copy(&example, &path).map_err(|e| {
                KytoError::Io(path.display().to_string(), e.to_string())
            })?;
        } else {
            return Ok(None);
        }
    }

    let source = std::fs::read_to_string(&path)
        .map_err(|e| KytoError::Io(path.display().to_string(), e.to_string()))?;
    Ok(Some(parse(&source)?))
}

pub fn apply_config(cfg: &KytoConfig, bundle: &mut EmitBundle) -> KytoResult<()> {
    let overlay = cfg.env_overlay()?;
    let env = bundle.env.get_or_insert_with(BTreeMap::new);
    for (k, v) in overlay {
        env.insert(k, v);
    }

    if !cfg.user_names.is_empty() {
        bundle.users = Some(cfg.clone().into_user_records()?);
    }

    let deploy = cfg.deploy_map();
    if !deploy.is_empty() {
        bundle.deploy = Some(deploy);
    } else if let Some(existing) = bundle.deploy.as_mut() {
        for (k, v) in &cfg.extra {
            if k.starts_with("REPO_") {
                if let Some(rest) = k.strip_prefix("REPO_") {
                    existing.insert(rest.to_ascii_lowercase(), v.clone());
                }
            }
        }
    }

    if let Some(domain) = &cfg.domain {
        let app_url = format!("https://{domain}");
        if let Some(env) = bundle.env.as_mut() {
            env.insert("APP_URL".into(), app_url);
        }
    }

    Ok(())
}

fn split_key_value(line: &str) -> Option<(&str, &str)> {
    let line = line.trim();
    let mut parts = line.splitn(2, char::is_whitespace);
    let key = parts.next()?.trim();
    let value = parts.next().unwrap_or("").trim();
    if key.is_empty() {
        return None;
    }
    Some((key, value))
}

fn parse_name_list(value: &str) -> Vec<String> {
    value
        .split_whitespace()
        .map(|s| s.to_ascii_lowercase())
        .collect()
}

fn parse_quoted_value(value: &str) -> String {
    let trimmed = value.trim();
    if trimmed.len() >= 2 {
        let bytes = trimmed.as_bytes();
        if (bytes[0] == b'"' && bytes[bytes.len() - 1] == b'"')
            || (bytes[0] == b'\'' && bytes[bytes.len() - 1] == b'\'')
        {
            return trimmed[1..trimmed.len() - 1].to_string();
        }
    }
    trimmed.to_string()
}

fn random_base64(byte_len: usize) -> String {
    let mut bytes = vec![0u8; byte_len];
    rand::thread_rng().fill_bytes(&mut bytes);
    STANDARD.encode(bytes)
}

fn strip_comment(line: &str) -> &str {
    line.split('+').next().unwrap_or(line)
}

fn dedupe(names: Vec<String>) -> Vec<String> {
    let mut seen = HashSet::new();
    names
        .into_iter()
        .filter(|name| seen.insert(name.clone()))
        .collect()
}

fn config_error(line: usize, msg: &str) -> KytoError {
    KytoError::Eval(format!(".kyto.config:{line}: {msg}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_case_insensitive_directives() {
        let cfg = parse(
            "DOMAIN Portal.Example.COM\nADMIN VOID\nUSERS OLEG natalia VOID\n",
        )
        .unwrap();
        assert_eq!(cfg.domain.as_deref(), Some("portal.example.com"));
        assert_eq!(cfg.user_names, vec!["oleg", "natalia", "void"]);
        assert_eq!(cfg.admin_names, vec!["void"]);
    }

    #[test]
    fn parses_arbitrary_env_keys() {
        let cfg = parse(
            "DOMAIN app.example.com\nUSERS void\nDATABASE_URL postgresql://localhost/db\nREPO_DIR /root/app\n",
        )
        .unwrap();
        assert_eq!(
            cfg.extra.get("DATABASE_URL").map(String::as_str),
            Some("postgresql://localhost/db")
        );
        assert_eq!(cfg.deploy_map().get("dir").map(String::as_str), Some("/root/app"));
        let env = cfg.env_overlay().unwrap();
        assert_eq!(env.get("DATABASE_URL").map(String::as_str), Some("postgresql://localhost/db"));
        assert!(env.contains_key("SESSION_SECRET"));
    }

    #[test]
    fn parses_quoted_values() {
        let cfg = parse("BACKUP_CRON \"0 2 * * *\"\nUSERS void\n").unwrap();
        assert_eq!(
            cfg.extra.get("BACKUP_CRON").map(String::as_str),
            Some("0 2 * * *")
        );
    }

    #[test]
    fn parses_plus_comments() {
        let cfg = parse("+ note\nDOMAIN host.example\nUSERS void\n").unwrap();
        assert_eq!(cfg.domain.as_deref(), Some("host.example"));
        assert_eq!(cfg.user_names, vec!["void"]);
    }

    #[test]
    fn rejects_admin_not_in_users() {
        let cfg = parse("USERS oleg\nADMIN void\n").unwrap();
        let err = cfg.into_user_records().unwrap_err();
        assert!(err.to_string().contains("ADMIN 'void'"));
    }
}
