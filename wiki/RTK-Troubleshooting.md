# RTK — Troubleshooting

## ⚠️ Name collision: `rtk-ai/rtk` vs `reachingforthejack/rtk`

There are **two unrelated CLI tools** both named `rtk`:

| Binary                       | What it is                            | What you want |
| ---------------------------- | ------------------------------------- | ------------- |
| [`rtk-ai/rtk`](https://github.com/rtk-ai/rtk)                 | Rust **Token Killer** — the proxy this wiki documents | ✅ Yes        |
| [`reachingforthejack/rtk`](https://github.com/reachingforthejack/rtk)  | Rust **Type Kit** — unrelated codegen tool             | ❌ No         |

### Diagnose

```bash
which rtk         # confirm the path
rtk --version     # both will print something; not conclusive
rtk gain          # ← THIS is the tell
```

- `rtk-ai/rtk` → prints token-savings analytics.
- `reachingforthejack/rtk` → prints "unknown subcommand" or a Type Kit help screen.

### Fix

If you have the wrong one, remove it:

```bash
# If installed via cargo
cargo uninstall rtk

# If installed via brew under a different formula name
brew list | grep rtk
brew uninstall <wrong-formula>

# Then install the correct one
brew install rtk
# or:
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
```

Verify again with `rtk gain` — that command **must** work for the right binary.

## `rtk init -g` failed

Failure usually means:
- `~/.claude/settings.json` is malformed (RTK refuses to overwrite invalid JSON).
- The path doesn't exist yet because Claude Code has never run on this machine.

Fix:

```bash
# Make sure the dir + file exist
mkdir -p ~/.claude
[ -f ~/.claude/settings.json ] || echo '{}' > ~/.claude/settings.json

# Re-run
rtk init -g
```

If it still fails, capture the **exact stderr** and open an issue at [rtk-ai/rtk](https://github.com/rtk-ai/rtk/issues).

## Hook seems inactive

Symptoms: `rtk gain --history` is empty even though you've run several Bash commands in Claude Code.

Check in order:

1. **Restart required.** Did you restart Claude Code after `rtk init -g`? The hook is read at start-up.
2. **Hook actually registered?**
   ```bash
   rtk init --show
   ```
   This is the authoritative answer. If it says "not active", run `rtk init -g` (or `/rtk-activate` in UFIL) and restart.
3. **Wrong binary on PATH?** See the name-collision section above.
4. **Claude Code config overridden by project settings.** If your project's `.claude/settings.json` redefines the `PreToolUse` hooks without the RTK entry, you'll bypass the global hook. Merge RTK's hook into the project config or remove the override.

## UFIL sentinel out of sync

UFIL's sentinel `${XDG_CACHE_HOME:-$HOME/.cache}/ufil/rtk-initialized` answers "has UFIL already run `rtk init -g`?" — it is **not** the source of truth for whether RTK is active.

If `/rtk-status` reports drift:
- Sentinel **present**, hook **inactive** → user (or another tool) uninstalled the hook outside UFIL. Run `/rtk-activate`.
- Sentinel **missing**, hook **active** → cache was cleared; harmless. Run `/rtk-activate` to recreate the sentinel, or ignore.

Manual reset:

```bash
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/ufil/rtk-initialized"
# next Claude Code session will re-run `rtk init -g`
```

## Output looks **wrong** after RTK filters it

RTK is conservative by default but it does drop content (that's the whole point). If a command's output looks truncated or misleading inside Claude:

1. Reproduce the raw output: `rtk proxy <command>` — this is what Claude actually saw.
2. Compare against the un-proxied: `<command>` directly.
3. If RTK's filter is too aggressive for your case, report it upstream with the diff.

Short-term workaround: disable the hook for that session via `/rtk-deactivate`, run the command, then re-activate.

## Reporting bugs

RTK bugs (filter behaviour, init failures, binary crashes) → [`rtk-ai/rtk` issues](https://github.com/rtk-ai/rtk/issues). Include:

- `rtk --version`
- OS + shell
- `rtk init --show` output
- Minimal reproduction (`rtk proxy <command>` plus the raw command output)

Bugs specific to **UFIL's** auto-installer (sentinel logic, install-rtk.sh) → [gm-claude-plugins issues](https://github.com/ghozimahdi/gm-claude-plugins/issues).
