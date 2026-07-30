# Serena Usage Notes

## Configuration
- Language: **dart** (configured in root `.serena/project.yml`)
- Project name: `gm-aiagent-plugins`
- The Dart LSP is mainly useful when working on Flutter code in target projects, not this plugin repo itself

## When working in this plugin repo
- This repo is mostly Markdown + Bash, so symbolic tools (`find_symbol`, `get_symbols_overview`) are limited
- Use `find_file` / `search_for_pattern` for discovery across plugin directories
- Use `replace_content` for regex edits inside Markdown / Bash files

## When working in a consumed Flutter project
- Use Serena symbolic tools for Dart code: `get_symbols_overview` first, then `find_symbol` with `include_body=True`
- For Dart edits, prefer `replace_symbol_body` / `insert_*_symbol` over Read+Edit
- Use `find_referencing_symbols` to understand call graphs before refactoring

## Memory line numbers
Serena tools return **0-based** line numbers — adjust for editor displays (1-based).
