import 'package:championforms/providers/quillcontrollerprovider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recentquillprovider.g.dart';

class RecentQuillSelected {
  final String formId;
  final String fieldId;

  RecentQuillSelected({
    required this.formId,
    required this.fieldId,
  });
}

@Riverpod(keepAlive: true)
class RecentQuillNotifier extends _$RecentQuillNotifier {
  @override
  RecentQuillSelected build() {
    return RecentQuillSelected(
      formId: '',
      fieldId: '',
    );
  }

  void updateRecentQuillSelected({
    required String formId,
    required String fieldId,
  }) {
    state = RecentQuillSelected(
      formId: formId,
      fieldId: fieldId,
    );
  }

  // This function returns the reference to the most recent active quill
  // But only if the provider is still active.
  // This allows us to maintain the reference
  // even if we move on in the app.
  // Use this check and then fail silently if null.
  RecentQuillSelected? checkIfQuillActive() {
    final formId = state.formId;
    final fieldId = state.fieldId;

    if (ref.exists(quillControllerNotifierProvider(formId, fieldId))) {
      return state;
    }
    return null;
  }
}
