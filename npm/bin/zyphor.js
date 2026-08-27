#!/usr/bin/env node

const path = require("path");
const fs = require("fs");
const { spawnSync } = require("child_process");
const { getPlatformInfo, main: installBinary } = require("../scripts/install");

async function run() {
  const { binaryName } = getPlatformInfo();
  const binDir = path.join(__dirname);
  const binaryPath = path.join(binDir, binaryName);

  if (!fs.existsSync(binaryPath)) {
    await installBinary();
  }

  if (!fs.existsSync(binaryPath)) {
    console.error(`\x1b[31m[Zyphor Error] Native binary not found at ${binaryPath}.\x1b[0m`);
    console.error(`Please install directly via: https://github.com/miyaniakshar1234/Zyphor#readme`);
    process.exit(1);
  }

  const args = process.argv.slice(2);
  const result = spawnSync(binaryPath, args, {
    stdio: "inherit",
    windowsHide: false,
  });

  if (result.error) {
    console.error(`[Zyphor Error] Failed to launch binary: ${result.error.message}`);
    process.exit(1);
  }

  process.exit(result.status !== null ? result.status : 0);
}

run();

