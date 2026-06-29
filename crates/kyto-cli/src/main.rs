mod install;

use std::env;
use std::path::PathBuf;
use std::process::ExitCode;

use clap::{Parser, Subcommand};
use kyto_core::{self, KytoError, project};

#[derive(Parser)]
#[command(name = "kura", version, about = "Kura - Kyto package manager and compiler")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Parse and evaluate without writing artifacts
    Check {
        #[arg(long)]
        entry: Option<PathBuf>,
    },
    /// Compile .kyto sources to configured artifacts
    Compile {
        #[arg(long)]
        entry: Option<PathBuf>,
    },
    /// Encrypt a local secrets file
    Encrypt {
        input: PathBuf,
        #[arg(short, long)]
        output: PathBuf,
    },
    /// Decrypt an encrypted secrets file
    Decrypt {
        input: PathBuf,
        #[arg(short, long)]
        output: PathBuf,
    },
    /// Scaffold kyto.toml, .kyto.config.example, and kyto/main.kyto
    Init {
        #[arg(long, default_value = ".")]
        path: PathBuf,
        #[arg(long, default_value = "my-project")]
        name: String,
    },
    /// Install kura binary to ~/.local/bin and add it to PATH
    Install {
        #[arg(long)]
        bin_dir: Option<PathBuf>,
    },
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("error: {e}");
            ExitCode::FAILURE
        }
    }
}

fn resolve_entry(entry: Option<PathBuf>) -> PathBuf {
    let cwd = env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    let repo_root = project::find_project_root(&cwd);
    project::resolve_entry(&repo_root, entry.as_deref())
}

fn run() -> Result<(), KytoError> {
    let cli = Cli::parse();
    match cli.command {
        Commands::Check { entry } => {
            let entry = resolve_entry(entry);
            kyto_core::check(&entry)?;
            println!("ok");
        }
        Commands::Compile { entry } => {
            let entry = resolve_entry(entry);
            let summary = kyto_core::compile(&entry)?;
            println!(
                "compiled: {} env keys, {} users, {} deploy keys",
                summary.env_keys, summary.user_count, summary.deploy_keys
            );
        }
        Commands::Encrypt { input, output } => {
            kyto_core::encrypt_file(&input, &output)?;
            println!("encrypted -> {}", output.display());
        }
        Commands::Decrypt { input, output } => {
            kyto_core::decrypt_file_to(&input, &output)?;
            println!("decrypted -> {}", output.display());
        }
        Commands::Init { path, name } => {
            kyto_core::init_project(&path, &name)?;
            println!("initialized Kyto project in {}", path.display());
            println!("next: edit .kyto.config.example, copy to .kyto.config, run kura compile");
        }
        Commands::Install { bin_dir } => install::run(bin_dir)?,
    }
    Ok(())
}
