import 'package:championforms/default_fields/championoptionselect.dart';
import 'package:championforms/default_fields/championtextfield.dart';
import 'package:championforms/models/field_types/championoptionselect.dart';
import 'package:championforms/models/field_types/championtextfield.dart';
import 'package:flutter/material.dart';
import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/colorscheme.dart';

// Generic builder function type
typedef FormFieldBuilder<T extends FormFieldDef> = Widget Function(
  BuildContext context,
  ChampionFormController controller,
  T field, // The specific field definition instance
  FieldState currentState,
  FieldColorScheme currentColors,
  Function(bool focused)
      updateFocus, // Callback to update focus state in controller
);

class ChampionFormFieldRegistry {
  bool initialized = false;

  // Private constructor
  ChampionFormFieldRegistry._internal();

  // Singleton instance
  static final ChampionFormFieldRegistry instance =
      ChampionFormFieldRegistry._internal();

  bool get isInitialized => initialized;

  // The registry map: Type maps to a builder function
  final Map<Type, Function> _builders =
      {}; // Use Function initially for simplicity

  /// Registers a builder function for a specific FormFieldDef type.
  /// Example: registerBuilder<ChampionTextField>(textFieldBuilder);
  void registerBuilder<T extends FormFieldDef>(FormFieldBuilder<T> builder) {
    if (_builders.containsKey(T)) {
      debugPrint('Warning: Overwriting builder for type $T');
    }
    _builders[T] = builder;
    debugPrint('Registered builder for type $T');
  }

  /// Looks up and executes the builder for a given field definition.
  Widget buildField(
    BuildContext context,
    ChampionFormController controller,
    FormFieldDef field, // Pass the base class instance
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
        debugPrint(
            'Error executing builder for type $fieldType: $e\n$stackTrace');
        return _buildErrorPlaceholder(fieldType, 'Builder execution error');
      }
    } else {
      debugPrint('Error: No builder registered for type $fieldType');
      return _buildErrorPlaceholder(fieldType, 'Builder not registered');
    }
  }

  Widget _buildErrorPlaceholder(Type fieldType, String message) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.red.withValues(alpha: 0.1),
      child: Text(
        'Error building field ($fieldType): $message',
        style: const TextStyle(color: Colors.red, fontSize: 12),
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
    ChampionFormFieldRegistry.instance
        .registerBuilder<ChampionTextField>(buildChampionTextField);
    ChampionFormFieldRegistry.instance
        .registerBuilder<ChampionOptionSelect>(buildChampionOptionSelect);
  }
}

// Optional: Initialize core builders immediately
// ChampionFormFieldRegistry.instance.registerCoreBuilders();
