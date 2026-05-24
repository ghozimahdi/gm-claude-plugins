# RTK (Rust Token Killer)

[RTK](https://github.com/rtk-ai/rtk) is a token-optimized CLI proxy that wraps shell commands invoked through Claude Code's `Bash` tool. By trimming verbose output **before** it reaches the model, RTK cuts LLM token consumption by **60–90%** on common dev commands (`git`, `flutter`, `dart`, `melos`, `npm`, etc.) without changing the user-facing behaviour.

It's shipped as part of the [`ufil`](https://github.com/ghozimahdi/gm-claude-plugins/tree/main/plugins/ufil) plugin — auto-installed on first session — and works with any Claude Code project, plugin or not.

> ⚠️ **Name collision:** there is an unrelated tool also called `rtk` at `reachingforthejack/rtk` (Rust Type Kit). Make sure the binary you have is the one from [`rtk-ai/rtk`](https://github.com/rtk-ai/rtk) — see [RTK-Troubleshooting](RTK-Troubleshooting).

## How it works

RTK installs a Claude Code **hook** that transparently rewrites Bash commands:

```
You ask Claude:  "run git status"
Claude calls:    Bash("git status")
Hook rewrites:   Bash("rtk git status")       # ← 0 tokens overhead
RTK runs:        git status, filters output, returns trimmed result
```

You never type `rtk` yourself — the rewrite is transparent. You also never lose information you actually need: RTK filters known-noisy output sections (file lists in `git status`, asset compilation logs in `flutter build`, etc.), not the parts a developer cares about.

## Quick start

```bash
# 1. Install the binary (macOS via Homebrew is easiest)
brew install rtk
# or, cross-platform:
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh

# 2. Register the Claude Code hook globally (one-time)
rtk init -g

# 3. Restart Claude Code for the hook to take effect

# 4. Verify
rtk --version
rtk gain          # show token savings analytics
```

UFIL users get steps 1 and 2 done automatically on first session — see [RTK-Usage-in-Plugins](RTK-Usage-in-Plugins).

## Read next

- [Installation](RTK-Installation) — manual install + verify.
- [Commands](RTK-Commands) — meta commands (`gain`, `discover`, `proxy`, `init`).
- [Usage in Plugins](RTK-Usage-in-Plugins) — how UFIL auto-installs and exposes `/rtk-*` commands.
- [Troubleshooting](RTK-Troubleshooting) — name collision, hook not active, sentinel out of sync.
