import { spawnSync } from "node:child_process";

// Basic sanity: ensure the wrapper starts and both CLI commands exist.

// Test moltbot command
const moltbot = spawnSync("moltbot", ["--version"], { encoding: "utf8" });
if (moltbot.status !== 0) {
  console.error("moltbot failed:", moltbot.stdout || moltbot.stderr);
  process.exit(moltbot.status ?? 1);
}
console.log("moltbot ok:", moltbot.stdout.trim());

// Test clawdbot shim (backwards compatibility)
const clawdbot = spawnSync("clawdbot", ["--version"], { encoding: "utf8" });
if (clawdbot.status !== 0) {
  console.error("clawdbot shim failed:", clawdbot.stdout || clawdbot.stderr);
  process.exit(clawdbot.status ?? 1);
}
console.log("clawdbot shim ok:", clawdbot.stdout.trim());
