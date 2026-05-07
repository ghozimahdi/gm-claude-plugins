---
description: "Deactivate rtk-ai/rtk: remove the global Claude Code hook, RTK.md, and settings.json entry. Leaves the binary installed."
argument-hint: ""
allowed-tools: ["Bash"]
model: haiku
---

Deactivate RTK for Claude Code by removing its global hook.

Steps:
1. Verify the binary is installed: `command -v rtk`. If missing, the hook can't be cleanly uninstalled via the CLI — tell the user, then stop. Do not hand-edit `~/.claude/settings.json`.
2. Run `rtk init -g --uninstall` to remove the hook, `RTK.md`, and the settings.json entry.
3. On success, delete the sentinel `~/.cache/ufil/rtk-initialized` (use `${XDG_CACHE_HOME:-$HOME/.cache}/ufil/rtk-initialized`) so a future `/rtk-activate` or SessionStart can re-init cleanly. Use `rm -f` so a missing sentinel isn't an error.
4. Report the result and remind the user: **restart Claude Code** to fully detach the hook.
5. The `rtk` binary itself is left installed. If the user wants to remove it too, suggest `brew uninstall rtk` (macOS) or `cargo uninstall rtk` — but do not run those automatically.

## References

- [github.com/rtk-ai/rtk](https://github.com/rtk-ai/rtk)
