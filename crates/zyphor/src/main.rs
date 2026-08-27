use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

const REPO: &str = "miyaniakshar1234/Zyphor";
const VERSION: &str = "v0.1.0";

fn get_binary_target() -> Result<(&'static str, &'static str, &'static str), String> {
    let os = match env::consts::OS {
        "windows" => "windows",
        "macos" => "macos",
        "linux" => "linux",
        other => return Err(format!("Unsupported OS: {}", other)),
    };

    let arch = match env::consts::ARCH {
        "x86_64" => "x86_64",
        "aarch64" => "aarch64",
        other => return Err(format!("Unsupported architecture: {}", other)),
    };

    let bin_name = if os == "windows" { "zyphor.exe" } else { "zyphor" };
    Ok((os, arch, bin_name))
}

fn get_cache_binary_path() -> Result<PathBuf, String> {
    let home = env::var("USERPROFILE")
        .or_else(|_| env::var("HOME"))
        .map_err(|_| "Could not determine user home directory".to_string())?;

    let (_, _, bin_name) = get_binary_target()?;
    let bin_dir = Path::new(&home).join(".zyphor").join("bin");
    fs::create_dir_all(&bin_dir).map_err(|e| e.to_string())?;

    Ok(bin_dir.join(bin_name))
}

fn download_and_extract_binary(target_path: &Path) -> Result<(), String> {
    let (os, arch, bin_name) = get_binary_target()?;
    let ext = if os == "windows" { ".zip" } else { ".tar.gz" };
    let asset = format!("zyphor-{}-{}{}", os, arch, ext);
    let url = format!("https://github.com/{}/releases/download/{}/{}", REPO, VERSION, asset);

    eprintln!("\x1b[34m==>\x1b[0m Downloading Zyphor native engine ({}) from {}...", asset, url);

    let temp_dir = env::temp_dir().join(format!("zyphor-install-{}", std::process::id()));
    fs::create_dir_all(&temp_dir).map_err(|e| e.to_string())?;
    let archive_path = temp_dir.join(&asset);

    if os == "windows" {
        let download_cmd = format!(
            "Invoke-WebRequest -Uri '{}' -OutFile '{}' -UseBasicParsing; Expand-Archive -Path '{}' -DestinationPath '{}' -Force",
            url, archive_path.display(), archive_path.display(), temp_dir.display()
        );
        let status = Command::new("powershell")
            .args(["-NoProfile", "-Command", &download_cmd])
            .status()
            .map_err(|e| format!("Failed to download archive via PowerShell: {}", e))?;

        if !status.success() {
            return Err("Failed to download or unpack Windows release archive".to_string());
        }
    } else {
        let status = Command::new("curl")
            .args(["-fsSL", &url, "-o", &archive_path.to_string_lossy()])
            .status()
            .map_err(|e| format!("Failed to download archive via curl: {}", e))?;

        if !status.success() {
            return Err("Failed to download release archive via curl".to_string());
        }

        let tar_status = Command::new("tar")
            .args(["-xzf", &archive_path.to_string_lossy(), "-C", &temp_dir.to_string_lossy()])
            .status()
            .map_err(|e| format!("Failed to unpack release archive via tar: {}", e))?;

        if !tar_status.success() {
            return Err("Failed to unpack release archive".to_string());
        }
    }

    let extracted_bin = temp_dir.join(bin_name);
    if !extracted_bin.exists() {
        return Err(format!("Extracted binary not found at {}", extracted_bin.display()));
    }

    fs::copy(&extracted_bin, target_path).map_err(|e| format!("Failed to copy binary to cache: {}", e))?;

    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mut perms = fs::metadata(target_path).map_err(|e| e.to_string())?.permissions();
        perms.set_mode(0o755);
        fs::set_permissions(target_path, perms).map_err(|e| e.to_string())?;
    }

    let _ = fs::remove_dir_all(&temp_dir);
    eprintln!("\x1b[32m✓\x1b[0m Installed native binary to {}", target_path.display());
    Ok(())
}

fn main() {
    let binary_path = match get_cache_binary_path() {
        Ok(p) => p,
        Err(e) => {
            eprintln!("[Zyphor Error] {}", e);
            std::process::exit(1);
        }
    };

    if !binary_path.exists() {
        if let Err(e) = download_and_extract_binary(&binary_path) {
            eprintln!("[Zyphor Error] {}", e);
            eprintln!("Please install directly from https://github.com/miyaniakshar1234/Zyphor#readme");
            std::process::exit(1);
        }
    }

    let args: Vec<String> = env::args().skip(1).collect();
    let mut child = match Command::new(&binary_path)
        .args(&args)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .spawn()
    {
        Ok(c) => c,
        Err(e) => {
            eprintln!("[Zyphor Error] Failed to execute {}: {}", binary_path.display(), e);
            std::process::exit(1);
        }
    };

    let exit_status = child.wait().unwrap_or_else(|_| std::process::exit(1));
    std::process::exit(exit_status.code().unwrap_or(0));
}

