import 'package:championforms/functions/extensions/inputdecoration_extensions.dart';
import 'package:championforms/functions/inputdecoration_from_theme.dart';
import 'package:championforms/functions/textstyle_from_theme.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Take in a TextFormField and override specific values with important ones we want to include.
TextField overrideTextField({
  required BuildContext context,
  required TextField baseField,
  FieldColorScheme? colorScheme,
  Function(String value)? onSubmitted,
  String? labelText,
  String? hintText,
  Widget? leading,
  Widget? trailing,
  Widget? icon,
  InputDecoration? inputDecoration,
  TextStyle? textStyle,
  TextEditingController? controller,
  FocusNode? focusNode,
  bool? autofocus = false,
  bool? obscureText = false,
  bool? autocorrect = false,
  int? maxLength,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
}) {
  // Determine the current InputDecoration or use a fallback.
  final originalDecoration = baseField.decoration;

  // Lets fold down the field colors from the theme before overriding the input decoration
  final InputDecoration? themeDecoration =
      originalDecoration?.merge(getInputDecorationFromScheme(colorScheme));

  // Fold down the input decoration
  final newInputDecoration = themeDecoration?.merge(inputDecoration);

  final effectiveInputDecoration = newInputDecoration?.copyWith(
    hintText: hintText,
    labelText: labelText,
    prefixIcon: leading,
    suffixIcon: trailing,
    icon: icon,
  );

  // Fold down the text style
  final originalTextStyle = baseField.style;

  // Lets fold in the text color scheme
  final themeTextStyle =
      originalTextStyle?.merge(getTextStyleFromScheme(colorScheme));

  final newTextStyle = themeTextStyle?.merge(textStyle);

  return TextField(
    key: baseField.key,
    controller: controller ?? baseField.controller,
    focusNode: focusNode ?? baseField.focusNode,
    decoration: effectiveInputDecoration,
    keyboardType: keyboardType ?? baseField.keyboardType,
    inputFormatters: inputFormatters ?? baseField.inputFormatters,
    onSubmitted: onSubmitted ?? baseField.onSubmitted,
    textInputAction: baseField.textInputAction,
    textCapitalization: baseField.textCapitalization,
    style: newTextStyle,
    strutStyle: baseField.strutStyle,
    textAlign: baseField.textAlign,
    textAlignVertical: baseField.textAlignVertical,
    textDirection: baseField.textDirection,
    readOnly: baseField.readOnly,
    showCursor: baseField.showCursor,
    autofocus: autofocus ?? baseField.autofocus,
    obscuringCharacter: baseField.obscuringCharacter,
    obscureText: obscureText ?? baseField.obscureText,
    autocorrect: autocorrect ?? baseField.autocorrect,
    smartDashesType: baseField.smartDashesType,
    smartQuotesType: baseField.smartQuotesType,
    enableSuggestions: baseField.enableSuggestions,
    maxLines: baseField.maxLines,
    minLines: baseField.minLines,
    expands: baseField.expands,
    maxLength: maxLength ?? baseField.maxLength,
    maxLengthEnforcement: baseField.maxLengthEnforcement,
    onChanged: baseField.onChanged,
    onEditingComplete: baseField.onEditingComplete,
    onAppPrivateCommand: baseField.onAppPrivateCommand,
    enabled: baseField.enabled,
    ignorePointers: baseField.ignorePointers,
    cursorWidth: baseField.cursorWidth,
    cursorHeight: baseField.cursorHeight,
    cursorRadius: baseField.cursorRadius,
    cursorOpacityAnimates: baseField.cursorOpacityAnimates,
    cursorColor: baseField.cursorColor,
    cursorErrorColor: baseField.cursorErrorColor,
    selectionHeightStyle: baseField.selectionHeightStyle,
    selectionWidthStyle: baseField.selectionWidthStyle,
    keyboardAppearance: baseField.keyboardAppearance,
    scrollPadding: baseField.scrollPadding,
    dragStartBehavior: baseField.dragStartBehavior,
    enableInteractiveSelection: baseField.enableInteractiveSelection,
    selectionControls: baseField.selectionControls,
    onTap: baseField.onTap,
    onTapAlwaysCalled: baseField.onTapAlwaysCalled,
    onTapOutside: baseField.onTapOutside,
    mouseCursor: baseField.mouseCursor,
    buildCounter: baseField.buildCounter,
    scrollController: baseField.scrollController,
    scrollPhysics: baseField.scrollPhysics,
    autofillHints: baseField.autofillHints,
    contentInsertionConfiguration: baseField.contentInsertionConfiguration,
    clipBehavior: baseField.clipBehavior,
    restorationId: baseField.restorationId,
    scribbleEnabled: baseField.scribbleEnabled,
    enableIMEPersonalizedLearning: baseField.enableIMEPersonalizedLearning,
    contextMenuBuilder: baseField.contextMenuBuilder,
    canRequestFocus: baseField.canRequestFocus,
    spellCheckConfiguration: baseField.spellCheckConfiguration,
    magnifierConfiguration: baseField.magnifierConfiguration,
  );
}
