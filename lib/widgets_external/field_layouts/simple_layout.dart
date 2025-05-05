import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/widgets_external/helper_widgets/fading_opacity.dart';
import 'package:flutter/material.dart';

Widget fieldSimpleLayout(
  BuildContext context,
  FormFieldDef fieldDetails,
  ChampionFormController controller,
  FieldColorScheme currentColors,
  Widget renderedField,
) {
  final errors = controller.findErrors(fieldDetails.id);
  return AnimatedSize(
    duration: Duration(milliseconds: 300),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fieldDetails.title != null)
          Padding(
            padding:
                const EdgeInsets.only(bottom: 0, left: 8, right: 8, top: 8.0),
            child: Text(
              fieldDetails.title!,
              style: TextStyle(
                color: currentColors.textColor,
                fontSize:
                    Theme.of(context).textTheme.titleMedium?.fontSize ?? 17,
              ),
            ),
          ),
        if (fieldDetails.description != null)
          Padding(
            padding:
                const EdgeInsets.only(top: 0, left: 8, right: 8, bottom: 8.0),
            child: Text(
              fieldDetails.description!,
              style: TextStyle(
                color: currentColors.textColor,
                fontSize:
                    Theme.of(context).textTheme.titleSmall?.fontSize ?? 14,
              ),
            ),
          ),
        renderedField,
        ...errors.map((error) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: FadingWidget(
                child: Text(
                  error.reason,
                  style: TextStyle(color: currentColors.borderColor),
                ),
              ),
            )),
      ],
    ),
  );
}
