import 'package:championforms/championforms.dart' as form;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for a field that buffers input, like a document editor on a
/// throttle: [type] only records text; [flush] writes it to the controller.
class _BufferedField {
  _BufferedField(this.controller, this.id) {
    controller.registerPendingEditFlusher(this, flush);
  }

  final form.FormController controller;
  final String id;
  String? pending;
  int flushes = 0;

  void type(String text) => pending = text;

  void flush() {
    flushes++;
    final text = pending;
    if (text == null) return;
    pending = null;
    controller.updateFieldValue<String>(id, text);
  }

  void dispose() => controller.unregisterPendingEditFlusher(this);
}

void main() {
  late form.FormController controller;

  setUp(() {
    controller = form.FormController();
    controller.addFields([
      form.TextField(
        id: 'doc',
        validators: [
          form.Validator(
            validator: (value) => (value as String? ?? '').isNotEmpty,
            reason: 'required',
          ),
        ],
      ),
    ]);
  });

  tearDown(() => controller.dispose());

  test('getResults sees edits the field was still buffering', () {
    final field = _BufferedField(controller, 'doc')..type('latest');
    final results = form.FormResults.getResults(controller: controller);
    expect(results.grab('doc').asString(), 'latest');
    expect(results.errorState, isFalse);
    expect(field.pending, isNull);
  });

  test('read-only results flush too', () {
    _BufferedField(controller, 'doc').type('draft');
    final results = form.FormResults.getResultsReadOnly(controller: controller);
    expect(results.grab('doc').asString(), 'draft');
  });

  test('validateForm and validatePage flush before validating', () {
    final field = _BufferedField(controller, 'doc')..type('x');
    expect(controller.validateForm(), isTrue);
    expect(field.flushes, 1);

    controller.updatePageFields('p1', [controller.registeredFields.single]);
    field.type('y');
    expect(controller.validatePage('p1'), isTrue);
    expect(controller.getFieldValue<String>('doc'), 'y');
  });

  test('a results read from inside a flush does not recurse', () {
    var depth = 0;
    var maxDepth = 0;
    controller.registerPendingEditFlusher('reader', () {
      depth++;
      if (depth > maxDepth) maxDepth = depth;
      // A flusher (or a listener it notifies synchronously) reading results.
      form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );
      depth--;
    });
    form.FormResults.getResults(controller: controller);
    expect(maxDepth, 1);
  });

  test('one throwing flusher is reported and the others still run', () {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);

    controller.registerPendingEditFlusher(
      'broken',
      () => throw StateError('boom'),
    );
    _BufferedField(controller, 'doc').type('still flushed');

    final results = form.FormResults.getResults(controller: controller);
    expect(results.grab('doc').asString(), 'still flushed');
    expect(reported.single.exception, isA<StateError>());
  });

  test('an unregistered flusher no longer runs', () {
    final field = _BufferedField(controller, 'doc')..type('never');
    field.dispose();
    form.FormResults.getResults(controller: controller, checkForErrors: false);
    expect(field.flushes, 0);
  });
}
