// Export the form builder sugar syntax widget

export 'package:championforms/widgets_external/championform.dart';
// TODO: Create provider container widget for projects which don't implement riverpod but want to use this project

// Export Form Field Base Classes
export 'package:championforms/models/field_types/formfieldbase.dart';
export 'package:championforms/models/field_types/formfieldclass.dart';

export 'package:championforms/models/field_types/championtextfield.dart';
export 'package:championforms/models/field_types/championoptionselect.dart';
export 'package:championforms/models/field_types/championfileupload.dart';

// Export rows and columns
export 'package:championforms/models/field_types/championrow.dart';
export 'package:championforms/models/field_types/championcolumn.dart';

// Export additional field convenience classes
export 'package:championforms/models/field_types/convienence_classes/championcheckboxselect.dart';

// Export default validators
export 'package:championforms/models/validatorclass.dart';

// Export form Controller
export 'package:championforms/controllers/form_controller.dart';

// Export Field Builders for crafting different types of fields.

// export themes for use
export 'package:championforms/themes/export_themes.dart';

// Export functions to get results and validate forms
export 'package:championforms/functions/geterrors.dart';

// This is the list of default validators you can use for field validation
export 'package:championforms/functions/defaultvalidators/defaultvalidators.dart';

// Export the global theme singleton
export 'package:championforms/models/theme_singleton.dart';

// Export FormResults type
export 'package:championforms/models/formresults.dart';
