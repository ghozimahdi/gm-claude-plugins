# RTK — Installation

RTK is a single binary plus a Claude Code hook. Two steps: install the binary, then register the hook.

> Skip this page if you're a UFIL user — UFIL auto-installs RTK on first session via `scripts/install-rtk.sh`. See [RTK-Usage-in-Plugins](RTK-Usage-in-Plugins).

## 1. Install the `rtk` binary

### macOS (preferred)

```bash
brew install rtk
```

### Cross-platform install script

```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
```

### Manual / source build

See the [`rtk-ai/rtk` README](https://github.com/rtk-ai/rtk) for `cargo install` or release-binary download.

## 2. Verify the binary

```bash
rtk --version    # should print: rtk X.Y.Z
which rtk        # confirm the path is what you expect
rtk gain         # should not print "command not found"
```

> ⚠️ If `rtk gain` errors with something like "no such subcommand", you most likely have **`reachingforthejack/rtk` (Rust Type Kit)** installed instead. Uninstall it (or shadow it) before continuing. Full diagnosis in [RTK-Troubleshooting](RTK-Troubleshooting).

## 3. Register the Claude Code hook

```bash
rtk init -g
```

This writes a global hook into `~/.claude/settings.json` plus a copy of `RTK.md` (RTK's own usage guide) into `~/.claude/`. The hook is what rewrites `Bash("git status")` → `Bash("rtk git status")` transparently.

Inspect the current state any time with:

```bash
rtk init --show
```

It will tell you whether the global hook is installed, and where it lives.

## 4. Restart Claude Code

The hook is loaded at Claude Code start-up. After `rtk init -g`, **quit and reopen Claude Code** so the new settings take effect. Without a restart, RTK is installed but inert.

## 5. Confirm RTK is active

In a fresh Claude Code session, ask Claude to run any shell command (e.g. `git status`). Then:

```bash
rtk gain --history
```

If you see your recent commands listed with savings metrics, the hook is active. If `gain --history` is empty even though you ran commands, the hook didn't fire — check [RTK-Troubleshooting](RTK-Troubleshooting).

## Uninstall

```bash
rtk init --uninstall   # remove the global hook
brew uninstall rtk     # or your install method
```

For UFIL users: also delete the sentinel so the next session doesn't try to re-install:

```bash
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/ufil/rtk-initialized"
```
