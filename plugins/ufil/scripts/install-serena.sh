#!/usr/bin/env bash
# Idempotent installer for serena-agent (provides `serena` and `serena-hooks`).
# Safe to call on every SessionStart: exits fast if already installed.

set -u

if command -v serena-hooks >/dev/null 2>&1; then
  exit 0
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "[serena] uv not found. Install it first: https://docs.astral.sh/uv/getting-started/installation/" >&2
  exit 0
fi

echo "[serena] serena-hooks not found — installing serena-agent via uv (one-time)..." >&2
if uv tool install -p 3.13 serena-agent@latest --prerelease=allow >&2; then
  echo "[serena] installed. Make sure '$(uv tool dir 2>/dev/null)/bin' (or ~/.local/bin) is on your PATH." >&2
else
  echo "[serena] install failed — continuing without serena-hooks." >&2
fi

exit 0
