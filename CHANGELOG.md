# Changelog

All notable changes to this project will be documented in this file.

## 1.1.1
- Docs: README/PT-BR, badges, checklist pub.dev
- CI: analyze/test + coverage gate (>=90%)
- Core: Clean Arch + SOLID no domínio
- Example: app executável em `example/`
- Lints modernas e templates de comunidade

## 1.1.0 — 2025-08-14
- Clean Architecture domain core (`FieldX`, `FieldState`, `Rule`, `Formaestro`).
- Debounced async validators + synchronous validators.
- Cross-field rules (sync/async).
- `FieldXBuilder` Flutter adapter.
- Test suite targeting ≥ 90% coverage.
- Safety around `dispose()` for debounced timers and late emissions.
