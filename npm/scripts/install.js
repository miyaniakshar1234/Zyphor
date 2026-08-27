const fs = require("fs");
const path = require("path");
const https = require("https");
const { execSync } = require("child_process");

const pkg = require("../package.json");
const REPO = "miyaniakshar1234/Zyphor";
const VERSION = "v" + pkg.version;

function getPlatformInfo() {
  const type = process.platform;
  const arch = process.arch;

  let os = "";
  if (type === "win32") os = "windows";
  else if (type === "darwin") os = "macos";
  else if (type === "linux") os = "linux";
  else throw new Error(`Unsupported OS platform: ${type}`);

  let targetArch = "";
  if (arch === "x64") targetArch = "x86_64";
  else if (arch === "arm64") targetArch = "aarch64";
  else throw new Error(`Unsupported CPU architecture: ${arch}`);

  const ext = os === "windows" ? ".zip" : ".tar.gz";
  const binaryName = os === "windows" ? "zyphor.exe" : "zyphor";
  const assetName = `zyphor-${os}-${targetArch}${ext}`;

  return { os, arch: targetArch, ext, binaryName, assetName };
}

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return downloadFile(res.headers.location, dest).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`Download failed with HTTP status ${res.statusCode} from ${url}`));
      }
      const fileStream = fs.createWriteStream(dest);
      res.pipe(fileStream);
      fileStream.on("finish", () => {
        fileStream.close();
        resolve();
      });
      fileStream.on("error", reject);
    }).on("error", reject);
  });
}

async function main() {
  try {
    const { os, binaryName, assetName } = getPlatformInfo();
    const binDir = path.join(__dirname, "..", "bin");
    const targetBinary = path.join(binDir, binaryName);

    if (fs.existsSync(targetBinary)) {
      return;
    }

    const downloadUrl = `https://github.com/${REPO}/releases/download/${VERSION}/${assetName}`;
    const tmpArchive = path.join(binDir, assetName);

    console.log(`[Zyphor] Fetching native binary from ${downloadUrl}...`);
    await downloadFile(downloadUrl, tmpArchive);

    console.log(`[Zyphor] Unpacking binary package...`);
    if (os === "windows") {
      execSync(`powershell -Command "Expand-Archive -Path '${tmpArchive}' -DestinationPath '${binDir}' -Force"`);
    } else {
      execSync(`tar -xzf "${tmpArchive}" -C "${binDir}"`);
      fs.chmodSync(targetBinary, 0o755);
    }

    if (fs.existsSync(tmpArchive)) {
      fs.unlinkSync(tmpArchive);
    }

    console.log(`[Zyphor] Native executable successfully installed.`);
  } catch (err) {
    console.warn(`[Zyphor] Postinstall note: Binary download deferred to initial runtime execution (${err.message})`);
  }
}

if (require.main === module) {
  main();
}

module.exports = { getPlatformInfo, downloadFile, main };

