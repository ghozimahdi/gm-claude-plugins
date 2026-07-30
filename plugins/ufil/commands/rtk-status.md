---
description: "Show rtk-ai/rtk status: whether the binary is installed, whether the global Claude Code hook is active, and the local sentinel state."
argument-hint: ""
allowed-tools: ["Bash"]
model: haiku
---

Report whether RTK is installed and whether its Claude Code hook is active.

Steps:
1. Check the binary: `command -v rtk` and `rtk --version` (only if found). If missing, report "binary not installed" and stop — the rest is irrelevant.
2. Run `rtk init --show` and surface the output verbatim — that is the authoritative answer for whether the global hook is registered.
3. Report the local sentinel state: whether `~/.cache/ufil/rtk-initialized` (use `${XDG_CACHE_HOME:-$HOME/.cache}/ufil/rtk-initialized`) exists. This only tells you whether *this plugin* has run `rtk init -g` before — RTK itself is the source of truth, the sentinel just gates auto-install.
4. If `rtk init --show` says the hook is active but the sentinel is missing (or vice versa), call that out — the user may want to run `/ufil:rtk-activate` or `/ufil:rtk-deactivate` to resync.

Output a short summary: binary version, hook active yes/no, sentinel present yes/no. No extra commentary.

## References

- [github.com/rtk-ai/rtk](https://github.com/rtk-ai/rtk)
