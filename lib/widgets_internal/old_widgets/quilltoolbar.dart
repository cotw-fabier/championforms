import 'package:championforms/providers/quillcontrollerprovider.dart';
import 'package:championforms/providers/recentquillprovider.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parchment_delta/parchment_delta.dart';

class QuillToolbarWidget extends ConsumerWidget {
  const QuillToolbarWidget({
    super.key,
    required this.fieldId,
    required this.formId,
    this.followLastActiveQuill = false,
    this.hideField = false,
    this.disableField = false,
    this.toolbarBuilder,
    this.initialValue,
  });

  final String fieldId;
  final String formId;
  final bool followLastActiveQuill;
  final bool hideField;
  final bool disableField;
  final Delta? initialValue;
  final FleatherToolbar Function(FleatherController controller)? toolbarBuilder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FleatherController? controller;

    if (followLastActiveQuill) {
      final lastActiveQuill = ref.watch(recentQuillNotifierProvider);
      if (lastActiveQuill != null) {
        controller = ref.watch(quillControllerNotifierProvider(
          lastActiveQuill.formId,
          lastActiveQuill.fieldId,
        ));
      }
    }

    controller ??= ref.watch(quillControllerNotifierProvider(
      formId,
      fieldId,
    ));

    if (toolbarBuilder != null) {
      return toolbarBuilder!(controller!);
    }
    return FleatherToolbar.basic(
      controller: controller!,
    );
  }
}
