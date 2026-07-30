---
name: keep-alive
description: "Prevent macOS from auto-sleeping. Run /ufil:keep-alive off to stop."
---

Use the current user request as this skill's input. In Claude Code invoke it as
`/ufil:keep-alive`; in Codex invoke it as `$ufil:keep-alive`.

Toggle macOS sleep prevention using `caffeinate`. The process runs detached so it survives this Claude Code session — it only stops when you run `/ufil:keep-alive off` or reboot.

Arguments: <requested arguments> (`on`, `off`, `status`, or empty which defaults to `on`)

## PID file

`/tmp/ufil-keep-alive.pid`

## Steps

### 1. Parse argument

- Empty or `on` → start
- `off` → stop
- `status` → report current state

### 2. `on` — start caffeinate

1. If PID file exists and the PID is alive (`kill -0 <pid> 2>/dev/null`), report "already running (PID <pid>)" and exit.
2. If PID file exists but the process is dead, remove the stale file.
3. Start caffeinate detached so it outlives this session:
   ```bash
   nohup caffeinate -dimsu >/dev/null 2>&1 &
   echo $! > /tmp/ufil-keep-alive.pid
   disown
   ```
   Flags: `-d` display, `-i` idle, `-m` disk, `-s` system (AC only), `-u` user-active assertion.
4. Verify the PID is alive, then report "keep-alive ON (PID <pid>) — run `/ufil:keep-alive off` to stop".

### 3. `off` — stop caffeinate

1. If PID file is missing, report "keep-alive is not running" and exit.
2. Read the PID, run `kill <pid>` (fall back to `kill -9` only if the process is still alive after a moment).
3. Remove the PID file.
4. Report "keep-alive OFF".

### 4. `status` — report state

1. If PID file is missing → "keep-alive is OFF".
2. If PID file exists but process is dead → "keep-alive is OFF (stale PID file removed)" and remove the file.
3. If process is alive → "keep-alive is ON (PID <pid>)".

## Notes

- macOS only — `caffeinate` is not available on Linux.
- The lid-closed case requires `-s`, which only takes effect on AC power. On battery, closing the lid will still sleep the machine — this is a macOS limitation.
- Do not background this with `&` alone inside the shell tool; always use `nohup ... & disown` so the process is not killed when the shell exits.
