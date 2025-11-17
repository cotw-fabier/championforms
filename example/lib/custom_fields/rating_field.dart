import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/widgets_external/stateful_field_widget.dart';
import 'package:flutter/material.dart';

/// A custom field that displays a star rating widget.
///
/// Demonstrates the simplified custom field API using [StatefulFieldWidget].
/// This implementation shows:
/// - File-based custom field approach (new field type)
/// - Integration with FormController via FieldBuilderContext
/// - Theme-aware styling
/// - Custom validation (minimum rating)
/// - ~30-50 lines implementation (vs old ~120-150 lines)
///
/// ## Usage
///
/// First, register the field type:
/// ```dart
/// registerRatingField();
/// ```
///
/// Then use it in forms:
/// ```dart
/// final ratingField = RatingField(
///   id: 'satisfaction_rating',
///   title: 'How satisfied are you?',
///   maxStars: 5,
///   defaultValue: 3,
///   validators: [
///     form.Validator(
///       validator: (results) => results.grab('satisfaction_rating').asInt() >= 3,
///       reason: 'Please rate at least 3 stars',
///     ),
///   ],
/// );
/// ```
class RatingField extends Field {
  /// Maximum number of stars to display.
  final int maxStars;

  /// Whether to allow half-star ratings.
  final bool allowHalfStars;

  @override
  final int? defaultValue;

  RatingField({
    required super.id,
    super.title,
    super.description,
    super.disabled = false,
    super.hideField = false,
    super.requestFocus = false,
    super.validators,
    super.validateLive = false,
    super.onSubmit,
    super.onChange,
    super.theme,
    super.fieldLayout,
    super.fieldBackground,
    this.maxStars = 5,
    this.allowHalfStars = false,
    this.defaultValue,
  });

  @override
  RatingField copyWith({
    String? id,
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    bool? requestFocus,
    List<form.Validator>? validators,
    bool? validateLive,
    Function(form.FormResults results)? onSubmit,
    Function(form.FormResults results)? onChange,
    FormTheme? theme,
    Widget Function(
      BuildContext context,
      Field fieldDetails,
      form.FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldLayout,
    Widget Function(
      BuildContext context,
      Field fieldDetails,
      form.FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldBackground,
    Widget? icon,
    int? maxStars,
    bool? allowHalfStars,
    int? defaultValue,
  }) {
    return RatingField(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      disabled: disabled ?? this.disabled,
      hideField: hideField ?? this.hideField,
      requestFocus: requestFocus ?? this.requestFocus,
      validators: validators ?? this.validators,
      validateLive: validateLive ?? this.validateLive,
      onSubmit: onSubmit ?? this.onSubmit,
      onChange: onChange ?? this.onChange,
      theme: theme ?? this.theme,
      fieldLayout: fieldLayout ?? this.fieldLayout,
      fieldBackground: fieldBackground ?? this.fieldBackground,
      maxStars: maxStars ?? this.maxStars,
      allowHalfStars: allowHalfStars ?? this.allowHalfStars,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  // --- Converter Implementations ---
  // These converters handle type conversion for FormResults

  @override
  String Function(dynamic value) get asStringConverter => (value) {
        if (value is int) return '$value/$maxStars stars';
        if (value == null) return '0/$maxStars stars';
        throw TypeError();
      };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
        if (value is int) return ['$value'];
        if (value == null) return ['0'];
        throw TypeError();
      };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
        if (value is int) return value > 0;
        if (value == null) return false;
        throw TypeError();
      };

  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter => null;
}

/// Widget implementation for RatingField.
///
/// Extends [StatefulFieldWidget] to automatically handle controller integration,
/// lifecycle management, and validation.
class RatingFieldWidget extends StatefulFieldWidget {
  const RatingFieldWidget({required super.context, super.key});

  @override
  Widget buildWithTheme(
    BuildContext context,
    FormTheme theme,
    FieldBuilderContext ctx,
  ) {
    final field = ctx.field as RatingField;

    // Get current rating, handling case where field not yet initialized
    int currentRating;
    try {
      currentRating = ctx.getValue<int>() ?? field.defaultValue ?? 0;
    } catch (e) {
      // Field not yet registered, use default
      currentRating = field.defaultValue ?? 0;
    }

    // Access theme colors for styling
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final disabledColor = theme.disabledColor;
    final color = field.disabled ? disabledColor : primaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        field.maxStars,
        (index) {
          final starValue = index + 1;
          final isFilled = starValue <= currentRating;

          return GestureDetector(
            onTap: field.disabled
                ? null
                : () {
                    // Update the field value when star is tapped
                    ctx.setValue(starValue);

                    // Trigger onChange callback if defined
                    if (field.onChange != null) {
                      final results =
                          form.FormResults.getResults(controller: ctx.controller);
                      field.onChange!(results);
                    }
                  },
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              color: color,
              size: 32.0,
            ),
          );
        },
      ),
    );
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    // Handle value changes if needed
    // For RatingField, we trigger onChange in the tap handler
  }
}

/// Registers the RatingField type with the FormFieldRegistry.
///
/// Call this function once during app initialization (e.g., in main.dart)
/// before using RatingField in forms.
///
/// Example:
/// ```dart
/// void main() {
///   registerRatingField();
///   runApp(MyApp());
/// }
/// ```
void registerRatingField() {
  FormFieldRegistry.register<RatingField>(
    'rating',
    (context) => RatingFieldWidget(context: context),
  );
}
