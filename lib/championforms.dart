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

// Export FieldOption (formerly MultiselectOption)
export 'package:championforms/models/multiselect_option.dart';

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

// Export Autocomplete Classes (includes CompleteOption, formerly AutoCompleteOption)
export 'package:championforms/models/autocomplete/autocomplete_class.dart';
export 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
export 'package:championforms/models/autocomplete/autocomplete_type.dart';

// Export Field Layout Functions
export 'package:championforms/widgets_external/field_layouts/simple_layout.dart';

// Export Field Background Functions
export 'package:championforms/widgets_external/field_backgrounds/simplewrapper.dart';
export 'package:championforms/widgets_external/field_backgrounds/coloredbox.dart';
