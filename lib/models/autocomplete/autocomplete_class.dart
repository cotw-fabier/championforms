import 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';
import 'package:flutter/widgets.dart';

/// This builds an autocomplete function into text inputs
/// add an autocomplete function to your forms when you are drawing from a
/// remote resource or have a pre-defined list of options
/// optionally supply a callback for each option to run arbitrary functions
/// pass through text or entire objects if you want to perform special functions.
class AutoCompleteBuilder {
  /// Define the type of autocomplete.
  ///  - AutoCompleteType.None disables the autocomplete but you can leave the code
  /// useful for troubleshooting
  ///  - AutoCompleteType.dropdown enables a dropdown style box below the field
  /// populated with results from the autocomplete.
  final AutoCompleteType type;

  /// Represent the height of the autocomplete popup as a percentage of available
  /// space from the field to the margin of the window.
  /// The minHeight will override if it is smaller. maxHeight will override if it is
  /// too tall. So this is a good way to get somewhere in the middle.
  /// If this is unset then the popup will shrinkwrap to the contents, honoring the
  /// min and max height.
  final int? percentageHeight;

  /// Sets the minimum height of the autocomplete popup. The popup attempts to
  /// appear below the text field it is attached to. However, if the field is near
  /// the bottom of the screen and there is not enough space for this popup to fit
  /// its minimum height, then it will instead render above the text field.
  final int? minHeight;

  /// Sets the maximum height of the autocomplete popup. If the popup doesn't have
  /// enough room to reach this height, then it will remain shorter.
  final int? maxHeight;

  /// Provide an initial list of autocomplete options.
  /// This can be left blank if you plan to populate with the updateOptions callback.
  final List<CompleteOption> initialOptions;

  /// Runs a function and returns a list of CompleteOption objects. Runs async
  /// to support network requests and other options. This will run as the field is changed.
  /// if debounceDuration is set then this function will be limited until the duration
  /// timer expires.
  final Future<List<CompleteOption>> Function(String val)? updateOptions;

  /// Sets a timer which blocks reruns of the autocomplete updateOptions callback.
  /// If the timer expires and this hasn't recieved a result yet from the
  /// previous callback, but another call has been requested
  /// then it will cancel the previous callback and try again with the updated data.
  /// defaults to a 1 second timer
  final Duration debounceDuration;

  /// Set a duration to wait between field updates before attempting the
  /// updateOptions callback. This prevents excessive runs of updateOptions.
  /// Defaults to a low Duration of 100ms
  final Duration debounceWait;

  /// A custom builder for options. Will fallback to a default if none is given.
  /// Takes in the CompleteOption and allows you to define your own custom
  /// behavior when the option is selected.
  /// If defining a custom builder, make sure to fire the championCallback function
  /// when the option is selected so ChampionForms knows when an option has been selected.
  final Widget Function(CompleteOption option,
          String Function(CompleteOption option) championCallback)?
      optionBuilder;

  /// Autocomplete Dropdown Box Margin. Spacing from the field of the
  /// autocomplete dropdown box (if set to AutoCompleteType.dropdown)
  /// defaults to 8 for some natural spacing.
  final int dropdownBoxMargin;

  AutoCompleteBuilder({
    this.type = AutoCompleteType.dropdown,
    this.initialOptions = const [],
    this.updateOptions,
    this.debounceDuration = const Duration(seconds: 1),
    this.debounceWait = const Duration(milliseconds: 100),
    this.optionBuilder,
    this.dropdownBoxMargin = 8,

    // Height inputs for dropdown view
    this.maxHeight,
    this.minHeight,
    this.percentageHeight,
  });
}
