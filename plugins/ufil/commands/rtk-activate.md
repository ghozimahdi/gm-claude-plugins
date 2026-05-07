---
description: "Activate rtk-ai/rtk: install the global Claude Code hook that wraps shell commands to cut LLM token usage 60-90%."
argument-hint: ""
allowed-tools: ["Bash"]
model: haiku
---

Activate RTK for Claude Code by installing its global hook.

Steps:
1. Verify the binary is installed: `command -v rtk` — if missing, instruct the user to run `/rtk-activate` again after `brew install rtk` (macOS) or `curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh`. Do not attempt to install it from inside this command.
2. Run `rtk init -g` to install the hook and `RTK.md` into the user's global Claude Code settings.
3. On success, create the sentinel `~/.cache/ufil/rtk-initialized` (use `${XDG_CACHE_HOME:-$HOME/.cache}/ufil/rtk-initialized`) so the SessionStart auto-installer skips re-running init.
4. Report the result and remind the user: **restart Claude Code** for the hook to take effect.
5. If `rtk init -g` fails, surface the exact stderr output — do not retry blindly.

## References

- [github.com/rtk-ai/rtk](https://github.com/rtk-ai/rtk)
- `scripts/install-rtk.sh` — auto-install logic this command mirrors
