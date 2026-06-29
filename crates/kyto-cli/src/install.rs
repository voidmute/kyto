use std::path::{Path, PathBuf};

use kyto_core::KytoError;

pub fn run(bin_dir: Option<PathBuf>) -> Result<(), KytoError> {
    let current = std::env::current_exe()
        .map_err(|e| KytoError::Io("current_exe".into(), e.to_string()))?;
    let target_dir = bin_dir.unwrap_or_else(default_bin_dir);
    std::fs::create_dir_all(&target_dir)
        .map_err(|e| KytoError::Io(target_dir.display().to_string(), e.to_string()))?;

    let bin_name = if cfg!(windows) { "kura.exe" } else { "kura" };
    let target = target_dir.join(bin_name);

    let same_binary = std::fs::canonicalize(&current)
        .ok()
        .zip(std::fs::canonicalize(&target).ok())
        .is_some_and(|(a, b)| a == b);

    if !same_binary {
        std::fs::copy(&current, &target)
            .map_err(|e| KytoError::Io(target.display().to_string(), e.to_string()))?;

        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            std::fs::set_permissions(&target, std::fs::Permissions::from_mode(0o755))
                .map_err(|e| KytoError::Io(target.display().to_string(), e.to_string()))?;
        }
    }

    add_to_path(&target_dir)?;
    if same_binary {
        println!("kura already installed at {}", target.display());
    } else {
        println!("installed kura -> {}", target.display());
    }
    println!("restart your shell, then run: kura --version");
    Ok(())
}

fn default_bin_dir() -> PathBuf {
    let home = dirs::home_dir().expect("home directory");
    home.join(".local").join("bin")
}

fn add_to_path(dir: &Path) -> Result<(), KytoError> {
    #[cfg(windows)]
    {
        use winreg::enums::{HKEY_CURRENT_USER, KEY_READ, KEY_WRITE};
        use winreg::RegKey;

        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let environment = hkcu
            .open_subkey_with_flags("Environment", KEY_READ | KEY_WRITE)
            .map_err(|e| KytoError::Io("HKCU\\Environment".into(), e.to_string()))?;
        let path: String = environment.get_value("Path").unwrap_or_default();
        let dir_str = dir.to_string_lossy().to_string();
        if path
            .split(';')
            .any(|entry| entry.eq_ignore_ascii_case(&dir_str))
        {
            return Ok(());
        }
        let new_path = if path.is_empty() {
            dir_str
        } else {
            format!("{path};{dir_str}")
        };
        environment
            .set_value("Path", &new_path)
            .map_err(|e| KytoError::Io("HKCU\\Environment\\Path".into(), e.to_string()))?;
        return Ok(());
    }

    #[cfg(not(windows))]
    {
        let dir_str = dir.to_string_lossy();
        if let Ok(path) = std::env::var("PATH") {
            if path.split(':').any(|entry| entry == dir_str.as_ref()) {
                return Ok(());
            }
        }
        eprintln!(
            "note: add {} to PATH, e.g. export PATH=\"{}:$PATH\"",
            dir.display(),
            dir.display()
        );
        Ok(())
    }
}
