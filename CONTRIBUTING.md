# Contributing

Thanks for your interest in improving **formaestro**!

## Development setup

1. Install Flutter (stable) and Dart.
2. Get dependencies:
   ```bash
   flutter pub get
   (cd example && flutter pub get || true)
   ```
3. Analyze & format:
   ```bash
   flutter analyze
   dart format --set-exit-if-changed .
   ```
4. Run tests with coverage:
   ```bash
   flutter test --coverage
   ```

## Pull Requests

- Use **Conventional Commits**: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- Add/keep **unit/widget tests**. Target coverage ≥ 90%.
- Update **CHANGELOG.md** for user-facing changes.
- Keep public API docs in **English**.

## Commit message examples

- `feat: add cross-field async rule support`
- `fix: prevent late emission after dispose`
- `docs: expand README with recipes`
- `test: add FieldXBuilder async validation test`

## Code style

The repo uses `lints/recommended` plus a few additional rules (see `analysis_options.yaml`).

## Security

See **SECURITY.md** for how to report vulnerabilities.
