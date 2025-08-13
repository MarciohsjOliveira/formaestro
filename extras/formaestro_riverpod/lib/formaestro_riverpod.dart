import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formaestro/formaestro.dart';

/// Provides the Formaestro instance.
final formaestroProvider = Provider<Formaestro>((ref) {
  throw UnimplementedError('Override formaestroProvider at the top of your tree');
});

/// Watches a field value as a stream.
AutoDisposeStreamProvider<T> fieldValueProvider<T>(String name) =>
    StreamProvider.autoDispose<T>((ref) {
      final form = ref.watch(formaestroProvider);
      final field = form.field<T>(name);
      return field.valueStream;
    });

/// Watches a field error as a stream.
AutoDisposeStreamProvider<String?> fieldErrorProvider(String name) =>
    StreamProvider.autoDispose<String?>((ref) {
      final form = ref.watch(formaestroProvider);
      final field = form.field<dynamic>(name);
      return field.errorStream;
    });
