# Hotfix notes

- Fixed package imports to `package:formaestro/...` to satisfy lints.
- Removed direct `FieldX` reference from `FormaestroSchema` to avoid cycles.
- Guarded nullability in `values`/`errors` mapping.
- To silence analyzer errors from **legacy examples** not in this package,
  remove `example/advanced/**` and `extras/**` or add the required external deps.
