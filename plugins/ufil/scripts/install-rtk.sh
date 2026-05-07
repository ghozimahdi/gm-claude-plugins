#!/usr/bin/env bash
# Idempotent installer for rtk (https://github.com/rtk-ai/rtk).
# RTK is a CLI proxy that wraps shell commands invoked via Claude Code's Bash
# tool to cut LLM token consumption by 60-90% on common dev commands
# (git, flutter, dart, npm, ...). Safe to call on every SessionStart.
#
# Steps:
#   1. Install the `rtk` binary if missing (brew on macOS, curl install
#      script as fallback). Skipped entirely if `rtk` is already on PATH.
#   2. Run `rtk init -g` once to register the global Claude Code hook.
#      A sentinel file prevents re-running init on every session.
#
# Always exits 0 so a hook failure never breaks the user's session.

set -u

SENTINEL_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ufil"
SENTINEL_FILE="$SENTINEL_DIR/rtk-initialized"

install_rtk() {
  if command -v rtk >/dev/null 2>&1; then
    return 0
  fi

  echo "[rtk] not found — installing (one-time)..." >&2

  if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
    if brew install rtk >&2; then
      return 0
    fi
    echo "[rtk] brew install failed — falling back to install script." >&2
  fi

  if command -v curl >/dev/null 2>&1; then
    if curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh >&2; then
      return 0
    fi
  fi

  echo "[rtk] install failed — see https://github.com/rtk-ai/rtk for manual install." >&2
  return 1
}

init_rtk() {
  if [[ -f "$SENTINEL_FILE" ]]; then
    return 0
  fi

  if ! command -v rtk >/dev/null 2>&1; then
    return 1
  fi

  echo "[rtk] running 'rtk init -g' to register Claude Code hook (one-time)..." >&2
  if rtk init -g >&2; then
    mkdir -p "$SENTINEL_DIR"
    : > "$SENTINEL_FILE"
    echo "[rtk] initialized. Restart Claude Code to activate the auto-rewrite hook." >&2
  else
    echo "[rtk] 'rtk init -g' failed — run it manually to enable token savings." >&2
  fi
}

install_rtk && init_rtk

exit 0
