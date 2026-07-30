# Suggested Commands

## Plugin development (this repo)

This repo contains plugin definitions; there's no build/test step for the plugins themselves. Editing is the workflow.

### Install & test a plugin locally
```bash
# Quick start (no marketplace)
cd /path/to/your-flutter-project
claude --plugin-dir /path/to/gm-aiagent-plugins/plugins/ufil

# Or via local marketplace
/plugin marketplace add /path/to/gm-aiagent-plugins
/plugin install ufil@gm-aiagent-plugins
/reload-plugins                          # after editing plugin files

# From GitHub
/plugin marketplace add ghozimahdi/gm-aiagent-plugins
/plugin install ufil@gm-aiagent-plugins
```

### Release a plugin
```bash
/release ufil              # auto-bump patch
/release ufil minor        # bump minor
/release ufil 2.0.0        # explicit version
```

### Test scripts (ufil example)
```bash
bash plugins/ufil/scripts/init-modular.sh <args>
bash plugins/ufil/scripts/init-single.sh <args>
bash plugins/ufil/scripts/generate-module.sh <module_name>
```

## Git workflow
- Branch from `main`: `feat/...`, `fix/...`, `docs/...`, `refactor/...`
- Commits: `feat(ufil): ...`, `fix(ufil): ...`, `chore: ...`
- Push to fork, open PR against `main`

## Darwin (macOS) shell utilities
- `ls -la`, `find`, `grep -r`, `cd`, `pwd` — standard
- `brew install <pkg>` — package manager
- `pbcopy` / `pbpaste` — clipboard
- `open <file>` — open in default app
- BSD `sed` differs from GNU — prefer Edit/replace_content tools
