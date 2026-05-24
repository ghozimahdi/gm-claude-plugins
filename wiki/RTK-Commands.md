# RTK — Commands

You almost never invoke `rtk` directly in normal use — the hook rewrites Bash commands for you transparently. The commands below are the **meta** commands you'd type yourself for analytics, debugging, or hook management.

## Analytics

### `rtk gain`

Show cumulative token-savings analytics across all sessions.

```bash
rtk gain
```

Sample output (shape, not exact format):

```
Total commands proxied: 1,284
Tokens saved:          1,372,440
Estimated cost saved:  $5.49
Top filtered commands: git status, flutter build, melos run
```

### `rtk gain --history`

Same metrics, plus a per-command history.

```bash
rtk gain --history
```

Useful when you want to see *which* commands actually triggered RTK in recent sessions — handy debugging step when you're not sure the hook is firing.

### `rtk discover`

Scan your Claude Code transcript history for commands that RTK **could have** filtered but didn't (because RTK wasn't active yet, or the binary was missing).

```bash
rtk discover
```

Treat the output as a hint list of commands worth keeping under the RTK umbrella.

## Hook management

### `rtk init -g`

Register RTK's hook globally (writes to `~/.claude/settings.json`). One-time, idempotent — safe to run again.

### `rtk init --show`

Display the current hook state. Authoritative source for "is RTK active?" — preferred over checking files manually.

### `rtk init --uninstall`

Remove the global hook. The binary stays installed.

## Debugging

### `rtk proxy <command>`

Run a command **through** RTK's filter without going through Claude Code's hook rewrite. Useful when you want to see exactly what RTK would return to Claude for a given command.

```bash
rtk proxy git status
rtk proxy flutter build apk
```

If `rtk proxy git status` returns something sensible but Claude still sees the unfiltered output, the issue is in the **hook**, not in RTK's filtering.

### `rtk --version`

Self-explanatory. Always include this in any bug report.

## Reference

- [rtk-ai/rtk](https://github.com/rtk-ai/rtk) — upstream source & release notes.
