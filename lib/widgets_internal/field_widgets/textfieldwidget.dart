import 'package:championforms/fieldbuilders/textfieldbuilder.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_types/textfield.dart' as form_types;
import 'package:championforms/models/formresults.dart';
import 'package:championforms/widgets_external/stateful_field_widget.dart';
import 'package:championforms/widgets_internal/autocomplete_overlay_widget.dart';
import 'package:championforms/widgets_internal/field_interaction_animator.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart' hide TextField;
import 'package:flutter/material.dart' as material_tf show TextField;
import 'package:flutter/services.dart';

/// TextField widget implementation using [StatefulFieldWidget].
///
/// This refactored implementation eliminates ~180 lines of boilerplate by:
/// - Automatic controller and focus management via [FieldBuilderContext]
/// - Automatic value synchronization and change detection
/// - Automatic validation on focus loss (when validateLive is true)
/// - Automatic lifecycle management
///
/// The widget handles:
/// - Text input with Material TextField
/// - Autocomplete overlay integration
/// - Enter key submission via TextField.onSubmitted
/// - Custom field overrides
/// - onChange callback triggering
class TextFieldWidget extends StatefulFieldWidget {
  const TextFieldWidget({
    required super.context,
    super.key,
  });

  @override
  Widget buildWithTheme(
    BuildContext context,
    FormTheme theme,
    FieldBuilderContext ctx,
  ) {
    final field = ctx.field as form_types.TextField;

    // If a custom fieldBuilder is provided, use it instead of default rendering
    if (field.fieldBuilder != null) {
      return field.fieldBuilder!(ctx);
    }

    // Default rendering
    final textController = ctx.getTextController();
    final focusNode = ctx.getFocusNode();
    final materialTheme = Theme.of(context);

    // Resolve spellcheck / autocorrect with field → password-implicit → global
    // → package default. Field-level explicit values win, then password fields
    // implicitly disable both (so they never leak into OS spellcheck
    // dictionaries or get mangled by autocorrect), then FormFieldDefaults,
    // then package defaults (true). A consumer who really wants spellcheck on
    // a password field can still force it by passing `spellCheck: true`
    // explicitly. An explicit spellCheckConfiguration on the field overrides
    // the computed underline config but not autocorrect.
    //
    // Flutter's default spellcheck service is only wired up on iOS and
    // Android at runtime. Passing `const SpellCheckConfiguration()` on any
    // other platform (web, desktop, test VMs) throws at build time with
    // "the current platform does not have a supported spell check service".
    // We gate on the same signal Flutter's internal assertion uses
    // (`nativeSpellCheckServiceDefined`), plus explicit iOS/Android checks
    // as a belt-and-braces. Autocorrect is safe on all platforms.
    final defaults = FormFieldDefaults.instance;
    final effectiveSpellCheck =
        field.spellCheck ?? (field.password ? false : defaults.spellCheck);
    final effectiveAutocorrect =
        field.autocorrect ?? (field.password ? false : defaults.autocorrect);
    final spellCheckPlatformSupported = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android) &&
        WidgetsBinding
            .instance.platformDispatcher.nativeSpellCheckServiceDefined;
    // Password fields skip the global spellCheckConfiguration too — otherwise
    // an app-wide custom config would re-enable spellcheck on passwords.
    // Field-level explicit configs still win (consumers can opt back in).
    final effectiveSpellCheckConfig = field.spellCheckConfiguration ??
        (field.password ? null : defaults.spellCheckConfiguration) ??
        ((effectiveSpellCheck && spellCheckPlatformSupported)
            ? const SpellCheckConfiguration()
            : null);

    // Resolve keyboard auto-capitalization with field → password-implicit →
    // global → package default. Field-level explicit value wins, then
    // password fields implicitly force TextCapitalization.none (so the
    // keyboard never auto-capitalizes the first character of a secret),
    // then FormFieldDefaults, then Flutter's own TextField default is
    // TextCapitalization.none — which is why fields don't capitalize
    // sentences the way native fields do; FormFieldDefaults restores the
    // native default (sentences). A consumer who really wants capitalization
    // on a password field can still force it by passing textCapitalization
    // explicitly.
    final effectiveTextCapitalization = field.textCapitalization ??
        (field.password
            ? TextCapitalization.none
            : defaults.textCapitalization);

    // Triggers the field's onSubmit callback (shared by Enter-key submission
    // via the soft keyboard's action button and by Ctrl/Cmd+Enter on
    // physical keyboards).
    void triggerSubmit() {
      if (field.onSubmit != null) {
        final formResults = FormResults.getResults(
          controller: ctx.controller,
        );
        field.onSubmit!(formResults);
      }
    }

    // Build the TextField widget
    final textField = overrideTextField(
      context: context,
      leading: field.leading,
      trailing: field.trailing,
      icon: field.icon,
      labelText: field.textFieldTitle,
      hintText: field.hintText,
      keyboardType: field.keyboardType,
      inputFormatters: field.inputFormatters,
      controller: textController,
      focusNode: focusNode,
      obscureText: field.password,
      autofillHints: field.autofillHints,
      colorScheme: ctx.colors,
      baseField: material_tf.TextField(
        maxLines: field.maxLines,
        autocorrect: effectiveAutocorrect,
        textCapitalization: effectiveTextCapitalization,
        textInputAction: field.textInputAction,
        spellCheckConfiguration: effectiveSpellCheckConfig,
        onChanged: (value) {
          // Sync TextEditingController changes back to FormController
          ctx.setValue(value);
        },
        onSubmitted: (value) {
          // Handle Enter key submission (single-line fields, or multiline
          // fields with a submitting [textInputAction] set).
          triggerSubmit();
        },
        style: materialTheme.textTheme.bodyMedium,
      ),
    );

    // Resolve keyboard-submission behaviors with field → global → package
    // default (false), then wrap the field in a Focus ancestor that
    // intercepts the relevant Enter chord on hardware keyboards (desktop/web).
    //
    // - submitOnControlEnter: Ctrl+Enter (Cmd+Enter on macOS) submits without
    //   inserting a newline. Plain Enter still falls through and inserts a
    //   line break on multiline fields. Applies to single- and multi-line
    //   fields (single-line Ctrl+Enter never fires onSubmitted, so there's no
    //   double-submit).
    // - submitOnEnter: plain Enter submits while Shift+Enter inserts a newline
    //   ("chat input" pattern). Only applied to multiline fields — single-line
    //   fields already submit on Enter via onSubmitted, so intercepting here
    //   too would double-fire.
    final effectiveSubmitOnControlEnter =
        field.submitOnControlEnter ?? defaults.submitOnControlEnter;
    final isMultiline = field.maxLines == null || field.maxLines! > 1;
    final submitOnEnterActive =
        (field.submitOnEnter ?? defaults.submitOnEnter) && isMultiline;
    final maybeSubmittableField = ((effectiveSubmitOnControlEnter ||
                submitOnEnterActive) &&
            field.onSubmit != null)
        ? Focus(
            // This wrapper only listens for the submit chord; it must not
            // steal focus or traversal from the inner TextField.
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              final isEnter =
                  event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.numpadEnter;
              if (!isEnter) return KeyEventResult.ignored;

              final hasCtrlOrMeta =
                  HardwareKeyboard.instance.isControlPressed ||
                      HardwareKeyboard.instance.isMetaPressed;
              final hasShift = HardwareKeyboard.instance.isShiftPressed;

              // Ctrl/Cmd+Enter submits when enabled.
              if (effectiveSubmitOnControlEnter && hasCtrlOrMeta) {
                triggerSubmit();
                return KeyEventResult.handled;
              }

              // Plain Enter submits when submitOnEnter is active; Shift+Enter
              // (and any modifier combo) falls through so the newline is
              // inserted as usual.
              if (submitOnEnterActive && !hasCtrlOrMeta && !hasShift) {
                triggerSubmit();
                return KeyEventResult.handled;
              }

              return KeyEventResult.ignored;
            },
            child: textField,
          )
        : textField;

    // Resolve gentle focus-driven micro-interaction. Field-level explicit
    // value wins, then FormFieldDefaults, then package default (true).
    final effectiveAnimateInteractions =
        field.animateInteractions ?? defaults.animateInteractions;

    // Wrap the inner field with the focus animator BEFORE the autocomplete
    // wrapper so the overlay's anchor RenderBox doesn't move when the
    // field lifts on focus.
    final maybeAnimatedField = effectiveAnimateInteractions
        ? FieldInteractionAnimator(
            focusNode: focusNode,
            child: maybeSubmittableField,
          )
        : maybeSubmittableField;

    // Wrap with autocomplete if configured
    final wrappedField = field.autoComplete != null &&
            field.autoComplete!.type != AutoCompleteType.none
        ? AutocompleteWrapper(
            autoComplete: field.autoComplete!,
            context: ctx,
            child: maybeAnimatedField,
          )
        : maybeAnimatedField;

    // Wrap with field builder
    return FormFieldWrapperDesignWidget(child: wrappedField);
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    final field = context.field as form_types.TextField;

    // Sync FormController value to TextEditingController for display
    final textController = context.getTextController();
    final newText = newValue as String? ?? '';

    // Only update if text actually changed (avoid unnecessary cursor movement)
    if (textController.text != newText) {
      textController.text = newText;
    }

    // Trigger onChange callback if defined
    // Use getResultsReadOnly to avoid triggering validation during notification
    // handling, which can cause infinite loops
    if (field.onChange != null) {
      final results = FormResults.getResultsReadOnly(
        controller: context.controller,
        fields: [context.field],
      );
      field.onChange!(results);
    }
  }
}
