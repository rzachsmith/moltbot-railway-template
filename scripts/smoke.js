import { spawnSync } from "node:child_process";

// Basic sanity: ensure the wrapper starts and all CLI commands exist.

// Test openclaw command (primary)
const openclaw = spawnSync("openclaw", ["--version"], { encoding: "utf8" });
if (openclaw.status !== 0) {
  console.error("openclaw failed:", openclaw.stdout || openclaw.stderr);
  process.exit(openclaw.status ?? 1);
}
console.log("openclaw ok:", openclaw.stdout.trim());

// Test moltbot shim (backwards compatibility)
const moltbot = spawnSync("moltbot", ["--version"], { encoding: "utf8" });
if (moltbot.status !== 0) {
  console.error("moltbot shim failed:", moltbot.stdout || moltbot.stderr);
  process.exit(moltbot.status ?? 1);
}
console.log("moltbot shim ok:", moltbot.stdout.trim());

// Test clawdbot shim (backwards compatibility)
const clawdbot = spawnSync("clawdbot", ["--version"], { encoding: "utf8" });
if (clawdbot.status !== 0) {
  console.error("clawdbot shim failed:", clawdbot.stdout || clawdbot.stderr);
  process.exit(clawdbot.status ?? 1);
}
console.log("clawdbot shim ok:", clawdbot.stdout.trim());
