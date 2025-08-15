[![Pub Version](https://img.shields.io/pub/v/formaestro)](https://pub.dev/packages/formaestro)
[![Pub Points](https://img.shields.io/pub/points/formaestro)](https://pub.dev/packages/formaestro/score)
[![Pub Likes](https://img.shields.io/pub/likes/formaestro)](https://pub.dev/packages/formaestro/score)
[![Pub Popularity](https://img.shields.io/pub/popularity/formaestro)](https://pub.dev/packages/formaestro/score)
[![CI](https://github.com/MarciohsjOliveira/formaestro/actions/workflows/ci.yml/badge.svg)](https://github.com/MarciohsjOliveira/formaestro/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/badge/coverage-%E2%89%A590%25-brightgreen.svg)](#testing--coverage)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

# formaestro

> Reactive, async-first **form orchestration** for Flutter/Dart with cross-field rules, debounced async validators, and a tiny, UI-agnostic core built on **SOLID** + **Clean Architecture**.

<p align="center">
  <img src="assets/hero.png" alt="formaestro hero" width="720"/>
</p>

- **Predictable**: immutable `FieldState`, explicit streams, one orchestrator (`Formaestro`)
- **Async-friendly**: debounce + async validators out of the box
- **Scalable**: cross-field rules that see the whole form
- **UI-agnostic**: plugs into any state management; optional `FieldXBuilder` for Flutter

> **Requirements**: Dart SDK ≥ 3.3, Flutter ≥ 3.19.

---

## Table of Contents

- [Install](#install)
- [Quick Start](#quick-start)
- [Concepts](#concepts)
- [Flutter Integration](#flutter-integration)
- [Cross-Field Rules](#cross-field-rules)
- [API Reference (Cheat Sheet)](#api-reference-cheat-sheet)
- [Recipes](#recipes)
- [Testing & Coverage](#testing--coverage)
- [Design & Architecture](#design--architecture)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)
- [Português (BR)](#português-br)

---

## Install

```yaml
# pubspec.yaml
dependencies:
  formaestro: ^1.1.0
```

```dart
// Your code
import 'package:formaestro/formaestro.dart';
```

---

## Quick Start

### 1) Validators and fields

```dart
// Sync/async validators return a String (error message) or null.
String? required_(String s) => s.trim().isEmpty ? 'Required' : null;

Future<String?> uniqueUsername(String s) async {
  await Future<void>.delayed(const Duration(milliseconds: 200));
  return s == 'taken' ? 'Already taken' : null;
}

final username = FieldX<String>(
  initialValue: '',
  validators: [required_],
  asyncValidators: [uniqueUsername],
  debounce: const Duration(milliseconds: 300), // debounce for async validators
);

final password = FieldX<String>(
  initialValue: '',
  validators: [(v) => v.length < 8 ? 'Min 8 chars' : null],
);

final confirm = FieldX<String>(initialValue: '');
```

### 2) Compose a schema + cross-field rules

```dart
final form = Formaestro(
  FormaestroSchema({
    'username': username,
    'password': password,
    'confirm' : confirm,
  }, rules: [
    // Fail if password != confirm
    Rule.cross(['password', 'confirm'], (values) {
      return values['password'] == values['confirm']
          ? null
          : 'Passwords do not match';
    }),
  ]),
);
```

### 3) Validate

```dart
final ok = await form.validateAll();
if (!ok) {
  // Read snapshots
  final errors = form.errors;  // Map<String, String?>
  final values = form.values;  // Map<String, dynamic>
}
```

---

## Concepts

### `FieldX<T>`

Holds a single field’s **value**, last **error**, and emits **broadcast** streams:

- `valueStream` → `T`  
- `errorStream` → `String?`  
- `stateStream` → `FieldState<T>` (value + error + `isDirty` + `isValidating`)

Behavior:

- **Sync validators** run immediately on `setValue(...)`.
- **Async validators** run **after debounce**; first failing async validator wins.
- `isValid` is `true` iff there’s no error and not validating.
- Call `dispose()` to close streams and cancel timers (safe & idempotent).

```dart
field.setValue('new value');              // validate = true by default
field.setValue('draft', validate: false); // update without validating
```

### `Rule`

Cross-field rule that sees the **entire form** (`Map<String, dynamic>`):

```dart
Rule.cross(['a','b'], (values) => values['a'] == values['b'] ? null : 'a != b');
Rule.crossAsync(['email'], (values) async => await checkEmail(values['email']));
```

### `Formaestro`

The form orchestrator:

- `field<T>(key)` → typed access to a `FieldX<T>`
- `values` / `errors` → snapshots
- `validateAll()` → triggers each field’s validation then applies cross-field rules
- `dispose()` → disposes all fields (and cancels debounced timers)

---

## Flutter Integration

The core is UI-agnostic. For a minimal Flutter integration, use the optional `FieldXBuilder<T>`:

```dart
FieldXBuilder<String>(
  field: username,
  builder: (context, state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (v) => username.setValue(v),
          decoration: InputDecoration(
            labelText: 'Username',
            errorText: state.error,
          ),
        ),
        if (state.isValidating)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Checking...', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  },
)
```

Prefer **dumb widgets** and drive everything via `FieldX` streams. Integrate with Bloc, Riverpod, ValueNotifier, etc.—`FieldX` is just streams + simple methods.

---

## Cross-Field Rules

Rules run **after** fields have validated:

```dart
final form = Formaestro(FormaestroSchema({
  'pass': pass,
  'confirm': confirm,
}, rules: [
  Rule.cross(['pass','confirm'], (v) {
    return v['pass'] == v['confirm'] ? null : 'Passwords do not match';
  }),
  Rule.crossAsync(['username'], (v) async {
    // Optionally check server-side invariants here
    return null;
  }),
]));
```

- `validateAll()` returns `false` if **any** field fails **or** a rule returns a message.
- Show cross-field errors wherever you want (a banner, a field helper, etc.).

---

## API Reference (Cheat Sheet)

```dart
// ---------- FieldState ----------
class FieldState<T> {
  const FieldState({
    required T value,
    String? error,
    bool isDirty = false,
    bool isValidating = false,
  });
  T get value;
  String? get error;
  bool get isDirty;
  bool get isValidating;
  FieldState<T> copyWith({T? value, String? error, bool? isDirty, bool? isValidating});
}

// ---------- FieldX ----------
class FieldX<T> {
  FieldX({
    required T initialValue,
    List<String? Function(T)> validators = const [],
    List<Future<String?> Function(T)> asyncValidators = const [],
    Duration? debounce,
  });

  // Snapshots
  T get value;
  String? get error;
  bool get isValid;

  // Streams (broadcast)
  Stream<T> get valueStream;
  Stream<String?> get errorStream;
  Stream<FieldState<T>> get stateStream;

  // Actions
  void setValue(T value, {bool validate = true});
  void dispose();
}

// ---------- Rule ----------
typedef Values = Map<String, dynamic>;
abstract interface class Rule {
  List<String> get keys;
  FutureOr<String?> call(Values values);
  factory Rule.cross(List<String> keys, FutureOr<String?> Function(Values) fn);
  factory Rule.crossAsync(List<String> keys, Future<String?> Function(Values) fn);
}

// ---------- Schema ----------
class FormaestroSchema {
  const FormaestroSchema(Map<String, Object> fields, {List<Rule> rules = const []});
  final Map<String, Object> fields; // expects FieldX at runtime
  final List<Rule> rules;
}

// ---------- Orchestrator ----------
class Formaestro {
  Formaestro(FormaestroSchema schema, {Duration debounce = const Duration(milliseconds: 300)});
  FieldX<T> field<T>(String key);
  Map<String, dynamic> get values;
  Map<String, String?> get errors;
  Future<bool> validateAll();
  void dispose();
}

// ---------- Flutter adapter ----------
typedef FieldBuilder<T> = Widget Function(BuildContext, FieldState<T>);
class FieldXBuilder<T> extends StatefulWidget { /* ... */ }
```

---

## Recipes

- **Validate on submit (not on every keystroke)**

  ```dart
  onChanged: (v) => field.setValue(v, validate: false);
  // Later, e.g. onPressed:
  final ok = await form.validateAll();
  ```

- **Async username uniqueness**

  ```dart
  Future<String?> unique(String s) async =>
      await api.exists(s) ? 'Already taken' : null;

  final username = FieldX<String>(
    initialValue: '',
    asyncValidators: [unique],
    debounce: const Duration(milliseconds: 250),
  );
  ```

- **Disable submit while validating**

  ```dart
  // state.isValidating is exposed on FieldState<T> inside FieldXBuilder
  final isBusy = passwordState.isValidating || usernameState.isValidating;
  // Disable button: onPressed: isBusy ? null : () async { ... }
  ```

- **Map cross-field error to a specific field (UI choice)**

  ```dart
  final ok = await form.validateAll();
  if (!ok) {
    final msg = /* evaluate rules again or surface a stored banner */;
    // show under 'confirm' field, for example
  }
  ```

---

## Testing & Coverage

Target **≥ 90%** coverage.

```bash
flutter test --coverage
# Optional: HTML report (requires lcov/genhtml)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**CI**: see [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

---

## Design & Architecture

**Clean Architecture + SOLID** separation:

```
lib/
  src/
    core/              # Debouncer and small primitives
    domain/            # FieldX, FieldState, Rule, Formaestro, Schema
    flutter_adapters/  # Optional: FieldXBuilder (thin UI adapter)
```

Principles:

- **SRP**: `FieldX` manages a single field; `Formaestro` orchestrates the form.  
- **OCP**: compose new validators/rules without modifying core types.  
- **DIP**: domain is Flutter-free; adapters are thin and optional.  
- **Testability**: deterministic streams and clear state snapshots.

Performance:

- Broadcast streams + `FieldState` snapshots minimize rebuilds.
- Debounced async validators reduce backend pressure.

Reliability:

- `dispose()` cancels timers and ignores late emissions (safe & idempotent).

---

## FAQ

**Is this a replacement for `Form`/`TextFormField`?**  
No—`formaestro` focuses on domain logic (validation, rules, state). Use any widgets you like.

**Where should I show cross-field errors?**  
Anywhere—banner, under a specific field, or both. The library doesn’t enforce one style.

**Can I use Bloc / Riverpod?**  
Yes. `FieldX` exposes streams; subscribe and map to your state management of choice.

**How do I prevent validation on every keystroke?**  
Call `setValue(value, validate: false)` while typing and run `validateAll()` on submit.

---

## Pub.dev polish checklist

Add this to your `pubspec.yaml` for better pub.dev presence:

```yaml
name: formaestro
description: Reactive, async-first form orchestration for Flutter/Dart with cross-field rules and debounced validators.
homepage: https://github.com/MarciohsjOliveira/formaestro
repository: https://github.com/MarciohsjOliveira/formaestro
issue_tracker: https://github.com/MarciohsjOliveira/formaestro/issues
documentation: https://pub.dev/documentation/formaestro/latest/

topics:
  - forms
  - validation
  - reactive
  - flutter

screenshots:
  - description: "Hero"
    path: assets/hero.png
  - description: "Async validation with debounce"
    path: assets/validators.png
```

---

## Contributing

PRs are welcome. Please:

1. Run `flutter analyze`
2. Keep/extend tests (goal ≥ 90% coverage)
3. Update `CHANGELOG.md` when relevant
4. Keep public API docs in **English**

---

## License

MIT © 2025 MarciohsjOliveira — see [LICENSE](./LICENSE).

---

## Português (BR)

> Leia a versão traduzida: **[README.pt-BR.md](README.pt-BR.md)**.
