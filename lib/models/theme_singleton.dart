// lib/models/theme_singleton.dart
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/themes.dart';
import 'package:flutter/material.dart';

/// A singleton class to hold global theme overrides for ChampionForms.
///
/// This theme is applied *after* the default Theme.of(context) colors
/// but *before* any theme specified directly on a Form widget
/// or an individual form field.
///
/// Use `FormThemeSingleton.instance.setTheme(...)` to apply
/// overrides globally.
class FormThemeSingleton {
  // --- Singleton Setup ---
  static final FormThemeSingleton _instance = FormThemeSingleton._internal();

  factory FormThemeSingleton() {
    return _instance;
  }

  FormThemeSingleton._internal();

  static FormThemeSingleton get instance => _instance;

  // --- Theme Properties (Nullable) ---
  // Mirroring FormTheme properties, but nullable

  // Color Schemes
  FieldColorScheme? _colorScheme;
  FieldColorScheme? _errorColorScheme;
  FieldColorScheme? _activeColorScheme;
  FieldColorScheme? _disabledColorScheme;
  FieldColorScheme? _selectedColorScheme;

  // InputDecoration
  InputDecoration? _inputDecoration;

  // Text Styles
  TextStyle? _titleStyle;
  TextStyle? _descriptionStyle;
  TextStyle? _hintTextStyle;
  TextStyle? _chipTextStyle;

  // --- Getters for direct access (read-only view) ---
  FieldColorScheme? get colorScheme => _colorScheme;
  FieldColorScheme? get errorColorScheme => _errorColorScheme;
  FieldColorScheme? get activeColorScheme => _activeColorScheme;
  FieldColorScheme? get disabledColorScheme => _disabledColorScheme;
  FieldColorScheme? get selectedColorScheme => _selectedColorScheme;
  InputDecoration? get inputDecoration => _inputDecoration;
  TextStyle? get titleStyle => _titleStyle;
  TextStyle? get descriptionStyle => _descriptionStyle;
  TextStyle? get hintTextStyle => _hintTextStyle;
  TextStyle? get chipTextStyle => _chipTextStyle;

  /// Applies a FormTheme's properties as global overrides.
  ///
  /// Only non-null properties from the provided [theme] will override
  /// the current singleton settings. To clear specific overrides,
  /// you might need to call `reset()` first or set properties individually
  /// (if setters were implemented).
  void setTheme(FormTheme theme) {
    _colorScheme = theme.colorScheme ?? _colorScheme;
    _errorColorScheme = theme.errorColorScheme ?? _errorColorScheme;
    _activeColorScheme = theme.activeColorScheme ?? _activeColorScheme;
    _disabledColorScheme = theme.disabledColorScheme ?? _disabledColorScheme;
    _selectedColorScheme = theme.selectedColorScheme ?? _selectedColorScheme;
    _inputDecoration = theme.inputDecoration ?? _inputDecoration;
    _titleStyle = theme.titleStyle ?? _titleStyle;
    _descriptionStyle = theme.descriptionStyle ?? _descriptionStyle;
    _hintTextStyle = theme.hintTextStyle ?? _hintTextStyle;
    _chipTextStyle = theme.chipTextStyle ?? _chipTextStyle;
    // Note: No listener notification needed as widgets will rebuild based on usage context.
  }

  /// Resets all global overrides, reverting to Theme.of(context) defaults.
  void reset() {
    _colorScheme = null;
    _errorColorScheme = null;
    _activeColorScheme = null;
    _disabledColorScheme = null;
    _selectedColorScheme = null;
    _inputDecoration = null;
    _titleStyle = null;
    _descriptionStyle = null;
    _hintTextStyle = null;
    _chipTextStyle = null;
  }

  /// Helper to get the current singleton state as a FormTheme object.
  FormTheme get asFormTheme => FormTheme(
        colorScheme: _colorScheme,
        errorColorScheme: _errorColorScheme,
        activeColorScheme: _activeColorScheme,
        disabledColorScheme: _disabledColorScheme,
        selectedColorScheme: _selectedColorScheme,
        inputDecoration: _inputDecoration,
        titleStyle: _titleStyle,
        descriptionStyle: _descriptionStyle,
        hintTextStyle: _hintTextStyle,
        chipTextStyle: _chipTextStyle,
        // layoutBuilder, fieldBuilder, nonTextFieldBuilder are not typically global
      );
}
