import 'package:flutter/material.dart';

extension InputDecorationMerge on InputDecoration {
  InputDecoration merge(InputDecoration? overrides) {
    if (overrides == null) return this;
    return copyWith(
      icon: overrides.icon ?? icon,
      iconColor: overrides.iconColor ?? iconColor,
      label: overrides.label ?? label,
      labelText: overrides.labelText ?? labelText,
      labelStyle: overrides.labelStyle ?? labelStyle,
      floatingLabelStyle: overrides.floatingLabelStyle ?? floatingLabelStyle,
      helper: overrides.helper ?? helper,
      helperText: overrides.helperText ?? helperText,
      helperStyle: overrides.helperStyle ?? helperStyle,
      helperMaxLines: overrides.helperMaxLines ?? helperMaxLines,
      hintText: overrides.hintText ?? hintText,
      hintStyle: overrides.hintStyle ?? hintStyle,
      hintTextDirection: overrides.hintTextDirection ?? hintTextDirection,
      hintMaxLines: overrides.hintMaxLines ?? hintMaxLines,
      hintFadeDuration: overrides.hintFadeDuration ?? hintFadeDuration,
      error: overrides.error ?? error,
      errorText: overrides.errorText ?? errorText,
      errorStyle: overrides.errorStyle ?? errorStyle,
      errorMaxLines: overrides.errorMaxLines ?? errorMaxLines,
      floatingLabelBehavior:
          overrides.floatingLabelBehavior ?? floatingLabelBehavior,
      floatingLabelAlignment:
          overrides.floatingLabelAlignment ?? floatingLabelAlignment,
      isCollapsed: overrides.isCollapsed ?? isCollapsed,
      isDense: overrides.isDense ?? isDense,
      contentPadding: overrides.contentPadding ?? contentPadding,
      prefixIcon: overrides.prefixIcon ?? prefixIcon,
      prefixIconConstraints:
          overrides.prefixIconConstraints ?? prefixIconConstraints,
      prefix: overrides.prefix ?? prefix,
      prefixText: overrides.prefixText ?? prefixText,
      prefixStyle: overrides.prefixStyle ?? prefixStyle,
      prefixIconColor: overrides.prefixIconColor ?? prefixIconColor,
      suffixIcon: overrides.suffixIcon ?? suffixIcon,
      suffix: overrides.suffix ?? suffix,
      suffixText: overrides.suffixText ?? suffixText,
      suffixStyle: overrides.suffixStyle ?? suffixStyle,
      suffixIconColor: overrides.suffixIconColor ?? suffixIconColor,
      suffixIconConstraints:
          overrides.suffixIconConstraints ?? suffixIconConstraints,
      counter: overrides.counter ?? counter,
      counterText: overrides.counterText ?? counterText,
      counterStyle: overrides.counterStyle ?? counterStyle,
      filled: overrides.filled ?? filled,
      fillColor: overrides.fillColor ?? fillColor,
      focusColor: overrides.focusColor ?? focusColor,
      hoverColor: overrides.hoverColor ?? hoverColor,
      errorBorder: overrides.errorBorder ?? errorBorder,
      focusedBorder: overrides.focusedBorder ?? focusedBorder,
      focusedErrorBorder: overrides.focusedErrorBorder ?? focusedErrorBorder,
      disabledBorder: overrides.disabledBorder ?? disabledBorder,
      enabledBorder: overrides.enabledBorder ?? enabledBorder,
      border: overrides.border ?? border,
      enabled: overrides.enabled ?? enabled,
      semanticCounterText: overrides.semanticCounterText ?? semanticCounterText,
      alignLabelWithHint: overrides.alignLabelWithHint ?? alignLabelWithHint,
      constraints: overrides.constraints ?? constraints,
    );
  }
}
