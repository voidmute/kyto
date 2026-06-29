use std::path::PathBuf;

use kyto_core::config;
use kyto_core::{check, compile, project};

#[test]
fn parses_example_config() {
    let cfg = config::parse(
        "+ comment\nDOMAIN portal.example.com\nADMIN void\nUSERS oleg natalia VOID\n",
    )
    .unwrap();
    assert_eq!(cfg.domain.as_deref(), Some("portal.example.com"));
    assert_eq!(cfg.user_names.len(), 3);
    assert_eq!(cfg.admin_names, vec!["void"]);

    let users = cfg.into_user_records().unwrap();
    assert_eq!(users.len(), 3);
    assert_eq!(users[2].name, "void");
    assert_eq!(users[2].role, "ADMIN");
}

#[test]
fn rejects_unknown_directive_with_line_number() {
    let err = config::parse("FOO bar\n").unwrap_err();
    assert!(err.to_string().contains(".kyto.config:1"));
}

#[test]
fn minimal_example_compiles() {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("..")
        .join("..")
        .join("examples")
        .join("minimal");
    let entry = root.join("kyto").join("main.kyto");
    check(&entry).expect("example should pass check");
    let summary = compile(&entry).expect("example should compile");
    assert!(summary.env_keys >= 2);
    assert_eq!(summary.user_count, 2);
}

#[test]
fn loads_kyto_toml_manifest() {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("..")
        .join("..")
        .join("examples")
        .join("minimal");
    let manifest = project::load_manifest(&root).expect("manifest should parse");
    assert_eq!(manifest.project.name, "minimal-example");
    assert_eq!(manifest.project.entry, "kyto/main.kyto");
}
