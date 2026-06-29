use std::collections::HashSet;
use std::path::Path;

use crate::emit::{EmitBundle, UserRecord};
use crate::error::{KytoError, KytoResult};

#[derive(Debug, Default, Clone)]
pub struct KytoConfig {
    pub domain: Option<String>,
    pub user_names: Vec<String>,
    pub admin_names: Vec<String>,
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
}

pub fn parse(source: &str) -> KytoResult<KytoConfig> {
    let mut cfg = KytoConfig::default();

    for (idx, raw) in source.lines().enumerate() {
        let line_num = idx + 1;
        let line = strip_comment(raw).trim();
        if line.is_empty() {
            continue;
        }

        let mut parts = line.split_whitespace();
        let keyword = parts
            .next()
            .ok_or_else(|| config_error(line_num, "empty directive"))?
            .to_ascii_uppercase();

        match keyword.as_str() {
            "DOMAIN" => {
                let domain = parts
                    .next()
                    .ok_or_else(|| config_error(line_num, "DOMAIN requires a host"))?;
                if parts.next().is_some() {
                    return Err(config_error(
                        line_num,
                        "DOMAIN accepts only one host value",
                    ));
                }
                cfg.domain = Some(domain.to_ascii_lowercase());
            }
            "USERS" => {
                let names: Vec<String> = parts.map(|s| s.to_ascii_lowercase()).collect();
                if names.is_empty() {
                    return Err(config_error(line_num, "USERS requires at least one name"));
                }
                cfg.user_names = dedupe(names);
            }
            "ADMIN" => {
                let names: Vec<String> = parts.map(|s| s.to_ascii_lowercase()).collect();
                if names.is_empty() {
                    return Err(config_error(line_num, "ADMIN requires at least one name"));
                }
                cfg.admin_names = dedupe(names);
            }
            other => {
                return Err(config_error(
                    line_num,
                    &format!("unknown directive '{other}'"),
                ));
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
    let path = repo_root.join(config_file);
    if !path.exists() {
        let example = repo_root.join(format!("{config_file}.example"));
        if example.exists() {
            std::fs::copy(&example, &path).map_err(|e| {
                KytoError::Io(path.display().to_string(), e.to_string())
            })?;
        } else {
            return Ok(());
        }
    }

    let source = std::fs::read_to_string(&path)
        .map_err(|e| KytoError::Io(path.display().to_string(), e.to_string()))?;
    let cfg = parse(&source)?;

    if !cfg.user_names.is_empty() {
        bundle.users = Some(cfg.clone().into_user_records()?);
    }

    if let Some(domain) = cfg.domain {
        let app_url = format!("https://{domain}");
        if let Some(env) = bundle.env.as_mut() {
            env.insert("APP_URL".into(), app_url);
        }
    }

    Ok(())
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
