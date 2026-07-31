/// ChampionForms - Form Lifecycle Classes
///
/// This file exports all classes needed for building and managing forms
/// throughout your application.
///
/// ## Recommended Usage:
/// ```dart
/// import 'package:championforms/championforms.dart' as form;
/// ```
///
/// This namespace approach prevents collisions with Flutter's built-in
/// Form, Row, and Column widgets.
///
/// ## Quick Examples:
/// ```dart
/// // Create a controller
/// final controller = form.FormController();
///
/// // Build a form
/// form.Form(
///   controller: controller,
///   fields: [
///     form.TextField(id: 'email', title: 'Email'),
///     form.Row(
///       children: [
///         form.TextField(id: 'first', title: 'First Name'),
///         form.TextField(id: 'last', title: 'Last Name'),
///       ],
///     ),
///     form.OptionSelect(id: 'country', title: 'Country', options: [...]),
///   ],
/// )
/// ```
///
/// For theming and custom field registration, use:
/// ```dart
/// import 'package:championforms/championforms_themes.dart';
/// ```
library;

// Export Form widget
export 'package:championforms/widgets_external/form.dart';

// Export Form Controller
export 'package:championforms/controllers/form_controller.dart';

// Export Base Classes
export 'package:championforms/models/field_types/formfieldbase.dart';
export 'package:championforms/models/field_types/formfieldclass.dart';
export 'package:championforms/models/field_types/formfielddefnull.dart';

// Export Field Types
export 'package:championforms/models/field_types/textfield.dart';
export 'package:championforms/models/field_types/optionselect.dart';
export 'package:championforms/models/field_types/fileupload.dart';
export 'package:championforms/models/field_types/convienence_classes/checkboxselect.dart';
export 'package:championforms/models/field_types/convienence_classes/chipselect.dart';
export 'package:championforms/models/field_types/convienence_classes/radioselect.dart';

// Export Compound Field Types
export 'package:championforms/models/field_types/compound_field.dart';
export 'package:championforms/default_fields/name_field.dart';
export 'package:championforms/default_fields/address_field.dart';

// Export FieldOption (formerly MultiselectOption)
export 'package:championforms/models/multiselect_option.dart';

// Export Field Colors (emphasis/role palette)
export 'package:championforms/models/field_colors.dart';

// Export Layout Classes
export 'package:championforms/models/field_types/row.dart';
export 'package:championforms/models/field_types/column.dart';

// Export Validator (formerly FormBuilderValidator) and Validators (formerly DefaultValidators)
export 'package:championforms/models/validatorclass.dart';
export 'package:championforms/functions/defaultvalidators/defaultvalidators.dart';

// Export Form Results
export 'package:championforms/models/formresults.dart';

// Export Functions to Get Errors
export 'package:championforms/functions/geterrors.dart';

// Export FormBuilderError.
//
// `FormResults.formErrors`, `FormController.findErrors`, `getErrors` and every
// `rollUpErrors` layout builder all hand out `FormBuilderError`s — so it was
// possible to *receive* one from the public API and impossible to *name* one
// without a deep import into `models/`. Anything that wanted to hold the errors
// in a variable, pass them to a helper, or write a typed test had to reach past
// the barrel.
//
// Note there is a second, unrelated class of the same name in
// `models/formcontroller/form_builder_error.dart` with a different shape. It is
// unused and unexported; this is the one the whole package actually produces.
export 'package:championforms/models/formbuildererrorclass.dart';

// Export the serializable rule types (v0.7.0+).
//
// Together with `FormFieldRegistry.fieldFromJson` these are what let a form be
// stored, versioned and edited as data rather than written as code.
export 'package:championforms/models/field_condition.dart';
export 'package:championforms/models/named_validator.dart';
export 'package:championforms/core/validator_registry.dart';
export 'package:championforms/core/field_json.dart';
export 'package:championforms/core/field_builder_registry.dart';

// Export Autocomplete Classes (includes CompleteOption, formerly AutoCompleteOption)
export 'package:championforms/models/autocomplete/autocomplete_class.dart';
export 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
export 'package:championforms/models/autocomplete/autocomplete_type.dart';

// Export Field Layout Functions
export 'package:championforms/widgets_external/field_layouts/simple_layout.dart';
export 'package:championforms/widgets_external/field_layouts/simple_description_below_layout.dart';

// Export Default Field Layouts Index
export 'package:championforms/functions/defaultlayouts/defaultlayouts.dart';

// Export Field Background Functions
export 'package:championforms/widgets_external/field_backgrounds/simplewrapper.dart';
export 'package:championforms/widgets_external/field_backgrounds/coloredbox.dart';

// Export Custom Field API (v0.6.0+)
export 'package:championforms/models/field_builder_context.dart';
export 'package:championforms/widgets_external/stateful_field_widget.dart';
export 'package:championforms/models/field_converters.dart';
export 'package:championforms/models/file_model.dart';
export 'package:championforms/models/themes.dart';

// Export FileType from file_picker for use with FileUpload
export 'package:file_picker/file_picker.dart' show FileType;
