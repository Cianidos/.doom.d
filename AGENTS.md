# Agent Guide

This repository is a Doom Emacs configuration in `~/.doom.d`. Keep changes
small, read the surrounding Doom setup first, and preserve the existing
preference for Doom macros (`after!`, `use-package!`, `map!`, `setq-hook!`,
`defadvice!`) over plain eager configuration.

## Repository Map

- `init.el` enables Doom modules. Run `doom sync` after changing it.
- `packages.el` declares extra packages and long-term disabled package recipes.
  Run `doom sync` after changing it.
- `config.el` contains the main private configuration: theme, keybindings,
  Ghostel terminal integration, Docker/workspace behavior, Eglot, Go tooling,
  Org/text tooling, completion, Telega, and helper commands.
- `themes/doom-solarized-semantic-theme.el` defines the custom Solarized-derived
  theme that dims structural syntax and emphasizes semantic signal.
- `lisp/phony-projects.el` implements virtual Projectile projects with
  `.phony.el` init/deinit hooks.
- `phony/btop/.phony.el`, `phony/codex/.phony.el`, and
  `phony/telega/.phony.el` define virtual workspaces for btop, Codex CLI, and
  Telega.
- `scripts/im-select.go` is a GNOME/Shyriiwook keyboard-layout helper. The
  related Emacs hooks are currently commented out.
- `emacs-mcp/main.go` is a dependency-free Go MCP stdio server that exposes a
  running Emacs through `emacsclient`. `emacs-mcp/emacs-mcp` is the built binary.
- `snippets/go-ts-mode/` contains Yasnippet snippets for Go tree-sitter mode.

## Important Invariants

- Ghostel is the terminal backend. Doom's `:term vterm` module is intentionally
  disabled, and `ghostel` is configured as a real Doom buffer with compile and
  Docker command integrations.
- Workspaces matter. Ghostel, Magit, Docker, Dired, Telega, and phony-project
  buffers are deliberately marked or pinned so they do not leak between
  perspectives.
- Buffer names matter. Ghostel uses its compact configured ghost prefix plus
  OSC 2 titles; Docker command buffers keep their generated names.
- The theme depends on the semantic-token handoff in `config.el`: tree-sitter
  owns structural syntax while Eglot semantic tokens own definitions, variables,
  functions, types, constants, properties, and numbers.
- Go support is a first-class workflow: `go-ts-mode`, Eglot/gopls staticcheck,
  Apheleia with `golines`, Dape/Delve launch configs, coverage helper, and Go
  text objects/snippets.
- Do not edit the compiled `emacs-mcp/emacs-mcp` binary directly. Change
  `emacs-mcp/main.go`, then rebuild the binary if needed.
- This config targets both macOS and Linux.
- Local machine assumptions exist: Iosevka fonts, `harper-ls`, `golines`,
  `dlv`, `gopls`, `plantuml`, `tdlib`, `brew` on macOS, and a Linux tdlib path.

## Agent Workflow

- Use the Emacs MCP tools for live Emacs context when investigating issues.
- Verify that changed Elisp is correct. If the feature can be checked in the
  live Emacs instance, check it there.
- Update `AGENTS.md` when significant config changes are made or when existing
  guidance drifts from the repository.
- If the user gives an explicit lasting instruction about this repository, add
  the durable part to `AGENTS.md`.
- If repository context is discovered while solving a task, ask before adding it
  to `AGENTS.md`.
- Keep `AGENTS.md` schematic and factual. Record what exists and what it does;
  avoid issue-history narratives.

## Validation

Use the smallest validation that matches the change:

- `doom sync` after edits to `init.el` or `packages.el`.
- `doom doctor` for broader environment checks.
- Live Emacs checks through MCP for behavior that can be verified interactively.
- `doom build` or Doom reload for broad Elisp changes when useful.
- `go fmt ./...` and `go test ./...` inside `emacs-mcp/` after MCP server edits.
- `go fmt scripts/im-select.go` after keyboard-layout helper edits.

For Elisp-only edits, prefer checking the affected feature interactively in the
running Emacs when possible. Be careful with batch byte-compilation unless Doom
is loaded correctly, because this config uses Doom macros heavily.

## Style Notes

- Keep `lexical-binding: t` headers on Elisp files.
- Prefer lazy setup with `after!` and `use-package!` so startup behavior stays
  predictable.
- Preserve the two-space indentation defaults unless a mode requires otherwise.
- Add comments only where they explain non-obvious workspace, advice, or
  terminal behavior.
- Keep personal paths and hostnames explicit when they are part of working
  configuration; do not generalize them away without confirmation.
