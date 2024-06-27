import 'package:championforms/models/fleathercustomautoformats.dart';
import 'package:championforms/models/fleathercustomheuristics.dart';
import 'package:fleather/fleather.dart';
import 'package:parchment_delta/parchment_delta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quillcontrollerprovider.g.dart';

@riverpod
class QuillControllerNotifier extends _$QuillControllerNotifier {
  @override
  FleatherController build(
    String formId,
    String fieldId,
  ) {
    // We need to insert custom heuristics here.
    // This will crash the app if you use const.
    // ignore: prefer_const_constructors
    final heuristics = ParchmentHeuristics(
      formatRules: [],
      insertRules: [
        const YoutubeEmbedInsertRule(),
      ],
      deleteRules: [],
    ).merge(ParchmentHeuristics.fallback);

    // TODO: Convert the heuistics rule to autoformat
    final autoFormats = AutoFormats(autoFormats: [
      const AutoFormatYoutubeEmbed(),
    ]);

    final document = ParchmentDocument();

    final controller =
        FleatherController(document: document, autoFormats: autoFormats);
    //final controller = QuillController.basic();

    ref.onDispose(() => controller.dispose());
    return controller;
  }

  void setValue(Delta? value) {
    if (value == null) return;

    final controller = state;
    controller.document.compose(value, ChangeSource.local);
    //controller.document..insert(0, value);
    //controller.document.insert(0, value);
    //controller.document.insert(0, value);
    state = controller;
  }
}
