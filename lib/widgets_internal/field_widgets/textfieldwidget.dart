import 'package:championforms/fieldbuilders/textfieldbuilder.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_types/textfield.dart' as form_types;
import 'package:championforms/models/formresults.dart';
import 'package:championforms/widgets_external/stateful_field_widget.dart';
import 'package:championforms/widgets_internal/autocomplete_overlay_widget.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart' hide TextField;
import 'package:flutter/material.dart' as material_tf show TextField;

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
        spellCheckConfiguration: effectiveSpellCheckConfig,
        onChanged: (value) {
          // Sync TextEditingController changes back to FormController
          ctx.setValue(value);
        },
        onSubmitted: (value) {
          // Handle Enter key submission
          if (field.onSubmit != null) {
            final formResults = FormResults.getResults(
              controller: ctx.controller,
            );
            field.onSubmit!(formResults);
          }
        },
        style: materialTheme.textTheme.bodyMedium,
      ),
    );

    // Wrap with autocomplete if configured
    final wrappedField = field.autoComplete != null &&
            field.autoComplete!.type != AutoCompleteType.none
        ? AutocompleteWrapper(
            autoComplete: field.autoComplete!,
            context: ctx,
            child: textField,
          )
        : textField;

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
