---
description: "Run code generation (freezed, injectable, auto_route, envied). Use after adding annotations or modifying annotated code."
argument-hint: ""
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
model: haiku
---

Run code generation for the Flutter project.

Steps:
1. Check if melos is available (look for `melos:` key in root `pubspec.yaml`) — if yes use `melos run build`, otherwise use `fvm dart run build_runner build --delete-conflicting-outputs`
2. If build fails, check for syntax errors in annotated files and fix
3. Run `fvm dart fix --apply lib/`
4. Run analyzer to verify no issues remain
