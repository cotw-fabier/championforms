import 'package:championforms/championforms.dart';
import 'package:championforms/default_fields/checkboxselect.dart';
import 'package:championforms/default_fields/chipselect.dart';
import 'package:championforms/default_fields/fileupload.dart';
import 'package:championforms/default_fields/optionselect.dart';
import 'package:championforms/default_fields/textfield.dart';
import 'package:championforms/models/field_types/convienence_classes/chipselect.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/colorscheme.dart';

// Generic builder function type
typedef FormFieldBuilder<T extends Field> = flutter.Widget Function(
  flutter.BuildContext context,
  FormController controller,
  T field, // The specific field definition instance
  FieldState currentState,
  FieldColorScheme currentColors,
  Function(bool focused)
      updateFocus, // Callback to update focus state in controller
);

class FormFieldRegistry {
  bool initialized = false;

  // Private constructor
  FormFieldRegistry._internal();

  // Singleton instance
  static final FormFieldRegistry instance = FormFieldRegistry._internal();

  bool get isInitialized => initialized;

  // The registry map: Type maps to a builder function
  final Map<Type, Function> _builders =
      {}; // Use Function initially for simplicity

  /// Registers a builder function for a specific Field type.
  /// Example: registerBuilder&lt;TextField&gt;(textFieldBuilder);
  void registerBuilder<T extends Field>(FormFieldBuilder<T> builder) {
    if (_builders.containsKey(T)) {
      flutter.debugPrint('Warning: Overwriting builder for type $T');
    }
    _builders[T] = builder;
    flutter.debugPrint('Registered builder for type $T');
  }

  /// Looks up and executes the builder for a given field definition.
  flutter.Widget buildField(
    flutter.BuildContext context,
    FormController controller,
    Field field, // Pass the base class instance
    FieldState currentState,
    FieldColorScheme currentColors,
    Function(bool focused) updateFocus,
  ) {
    final fieldType = field.runtimeType; // Get the actual runtime type
    final builder = _builders[fieldType];

    if (builder != null) {
      try {
        // Cast the field to its specific type for the builder
        // This relies on the builder function matching the registered type
        return builder(
          context,
          controller,
          field, // Builder function needs to accept the specific type T
          currentState,
          currentColors,
          updateFocus,
        );
      } catch (e, stackTrace) {
        flutter.debugPrint(
            'Error executing builder for type $fieldType: $e\n$stackTrace');
        return _buildErrorPlaceholder(fieldType, 'Builder execution error');
      }
    } else {
      flutter.debugPrint('Error: No builder registered for type $fieldType');
      return _buildErrorPlaceholder(fieldType, 'Builder not registered');
    }
  }

  flutter.Widget _buildErrorPlaceholder(Type fieldType, String message) {
    return flutter.Container(
      padding: const flutter.EdgeInsets.all(8),
      color: flutter.Colors.red.withValues(alpha: 0.1),
      child: flutter.Text(
        'Error building field ($fieldType): $message',
        style: const flutter.TextStyle(color: flutter.Colors.red, fontSize: 12),
      ),
    );
  }

  // Optional: Method to check if a builder is registered
  bool hasBuilderFor(Type type) {
    return _builders.containsKey(type);
  }

  // Method to register core library builders (call this internally)
  void registerCoreBuilders() {
    initialized = true;
    FormFieldRegistry.instance.registerBuilder<TextField>(buildTextField);
    FormFieldRegistry.instance
        .registerBuilder<OptionSelect>(buildOptionSelect);
    FormFieldRegistry.instance
        .registerBuilder<CheckboxSelect>(buildCheckboxSelect);
    FormFieldRegistry.instance.registerBuilder<FileUpload>(buildFileUpload);
    FormFieldRegistry.instance.registerBuilder<ChipSelect>(buildChipSelect);
  }
}

// Optional: Initialize core builders immediately
// FormFieldRegistry.instance.registerCoreBuilders();
