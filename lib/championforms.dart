// Export the form builder sugar syntax widget
import 'package:fleather/fleather.dart';

export 'package:championforms/widgets_external/championform.dart';
// TODO: Create provider container widget for projects which don't implement riverpod but want to use this project

// Export Form Classes
export 'package:championforms/models/formfieldclass.dart';
export 'package:championforms/models/formfieldtoolbar.dart';

// Export functions to get results and validate forms
export 'package:championforms/functions/getresults.dart';
export 'package:championforms/functions/geterrors.dart';

// export this type so you can work with form results such as building custom validation.
export 'package:championforms/models/formresultstype.dart';

// Export some default validators
export 'package:championforms/functions/defaultvalidators/defaultvalidators.dart';

export 'package:fleather/fleather.dart';
export 'package:parchment/parchment.dart';
export 'package:parchment_delta/parchment_delta.dart';

// TODO: Build some basic form styles to use in light or dark mode