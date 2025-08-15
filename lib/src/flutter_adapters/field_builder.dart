library;

import 'package:flutter/widgets.dart';
import 'package:formaestro/src/domain/field.dart';

typedef FieldBuilder<T> = Widget Function(
    BuildContext context, FieldState<T> state);

class FieldXBuilder<T> extends StatefulWidget {
  const FieldXBuilder({
    super.key,
    required this.field,
    required this.builder,
  });
  final FieldX<T> field;
  final FieldBuilder<T> builder;

  @override
  State<FieldXBuilder<T>> createState() => _FieldXBuilderState<T>();
}

class _FieldXBuilderState<T> extends State<FieldXBuilder<T>> {
  late FieldState<T> _state;
  @override
  void initState() {
    super.initState();
    _state =
        FieldState<T>(value: widget.field.value, error: widget.field.error);
    widget.field.stateStream.listen((s) {
      if (mounted) setState(() => _state = s);
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _state);
}
