import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/core/field_builder_registry.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/field_types/textfield.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_converters.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Custom field for testing registration
class CustomTestField extends Field with TextFieldConverters {
  CustomTestField({required super.id, super.title});

  @override
  dynamic get defaultValue => '';

  @override
  CustomTestField copyWith({
    String? id,
    material.Widget? icon,
    FormTheme? theme,
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    bool? requestFocus,
    List<Validator>? validators,
    bool? validateLive,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    material.Widget Function(
      material.BuildContext context,
      Field fieldDetails,
      FormController controller,
      FieldColorScheme currentColors,
      material.Widget renderedField,
    )? fieldLayout,
    material.Widget Function(
      material.BuildContext context,
      Field fieldDetails,
      FormController controller,
      FieldColorScheme currentColors,
      material.Widget renderedField,
    )? fieldBackground,
  }) {
    return CustomTestField(
      id: id ?? this.id,
      title: title ?? this.title,
    );
  }
}

// Custom converters for testing
class CustomTestConverters with TextFieldConverters {}

void main() {
  group('FormFieldRegistry Static API', () {
    setUp(() {
      // Note: Since FormFieldRegistry is a singleton, we need to be careful
      // about test isolation. In a real scenario, you might need a way to
      // reset the registry between tests, but for now we'll use unique types.
    });

    test('register should add builder for custom field type', () {
      // Arrange
      material.Widget testBuilder(FieldBuilderContext context) {
        return material.Container();
      }

      // Act
      FormFieldRegistry.register<CustomTestField>(
        'customTest',
        testBuilder,
      );

      // Assert - Should be able to check if builder is registered
      expect(
        FormFieldRegistry.instance.hasBuilderForType(CustomTestField),
        isTrue,
      );
    });

    test('register should accept optional converters parameter', () {
      // Arrange
      material.Widget testBuilder(FieldBuilderContext context) {
        return material.Container();
      }
      final converters = CustomTestConverters();

      // Act - Should not throw
      expect(
        () => FormFieldRegistry.register<CustomTestField>(
          'customTestWithConverters',
          testBuilder,
          converters: converters,
        ),
        returnsNormally,
      );
    });

    test('hasBuilderFor should return true for registered types', () {
      // Arrange
      material.Widget testBuilder(FieldBuilderContext context) {
        return material.Container();
      }
      FormFieldRegistry.register<CustomTestField>(
        'customForHasBuilder',
        testBuilder,
      );

      // Act
      final hasBuilder = FormFieldRegistry.hasBuilderFor<CustomTestField>();

      // Assert
      expect(hasBuilder, isTrue);
    });

    test('hasBuilderFor should return false for unregistered types', () {
      // Arrange - Create a unique custom field type that's not registered

      // Act - Using a generic Field type that shouldn't be registered
      final hasBuilder = FormFieldRegistry.instance.hasBuilderForType(Field);

      // Assert
      expect(hasBuilder, isFalse);
    });

    test('instance accessor should return singleton instance', () {
      // Act
      final instance1 = FormFieldRegistry.instance;
      final instance2 = FormFieldRegistry.instance;

      // Assert - Should be the same instance
      expect(instance1, equals(instance2));
    });

    test('instance accessor should provide backward compatibility', () {
      // Arrange
      material.Widget testBuilder(FieldBuilderContext context) {
        return material.Container();
      }

      // Act - Register via static method
      FormFieldRegistry.register<CustomTestField>(
        'backwardCompat',
        testBuilder,
      );

      // Assert - Should be accessible via instance
      expect(
        FormFieldRegistry.instance.hasBuilderForType(CustomTestField),
        isTrue,
      );
    });

    test('register should overwrite existing builder with warning', () {
      // Arrange
      material.Widget firstBuilder(FieldBuilderContext context) {
        return material.Container(key: const material.ValueKey('first'));
      }
      material.Widget secondBuilder(FieldBuilderContext context) {
        return material.Container(key: const material.ValueKey('second'));
      }

      // Act - Register twice
      FormFieldRegistry.register<CustomTestField>(
        'overwrite',
        firstBuilder,
      );
      FormFieldRegistry.register<CustomTestField>(
        'overwrite',
        secondBuilder,
      );

      // Assert - Should still be registered (last registration wins)
      expect(
        FormFieldRegistry.instance.hasBuilderForType(CustomTestField),
        isTrue,
      );
    });

    test('static register method should work with built-in field types', () {
      // Arrange
      material.Widget customTextFieldBuilder(FieldBuilderContext context) {
        return material.Container();
      }

      // Act - Should be able to register a custom builder for TextField
      expect(
        () => FormFieldRegistry.register<TextField>(
          'customTextField',
          customTextFieldBuilder,
        ),
        returnsNormally,
      );

      // Assert
      expect(
        FormFieldRegistry.instance.hasBuilderForType(TextField),
        isTrue,
      );
    });
  });
}
