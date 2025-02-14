import 'package:championforms/models/autocomplete/autocomplete_type.dart';
import 'package:flutter/widgets.dart';

/// An AutoCompleteOption houses the details of autocompletedata recieved into
/// ChampionForms. This could arrive from an initial supplied list, or be fetched
/// through the AutoCompleteBuilder updateOptions callback function.
/// This object represents a single autocomplete suggestion. It offers several
/// ways to build out options. Store just the value of each option, or give them custom titles.
/// use the isSet bool to track option settings which you could use in building the
/// option. Or pass entire objects through the additionalData object.
/// Defaults to buiding as a ListTile, but pass a custom builder if you prefer
/// a different look and feel.
/// You can also pass an option builder through the AutoCompleteBuilder. Passing a builder here
/// would override that builder.
///
/// Typically you only need to set the value for standard use cases. The additional
/// options exist for more advanced use cases of this setup.
class AutoCompleteOption {
  /// Define a custom title to display with the default builder.
  /// If none is given then it will default to the value.
  final String title;

  /// Define a custom value to pass when this is selected.
  final String value;

  /// Bool which can be used to track settings for inline options on auto suggestions
  final bool isSet;

  /// A custom object associated with this autosuggestion. Used for callbacks.
  /// Will need to validate the object at run time.
  /// Typically not used except for advanced usecases.
  final Object? additionalData;

  /// Callback function
  final Function(AutoCompleteOption option)? callback;

  /// the optionBuilder overrides the optionBuilder from the AutoCompleteBuilder
  /// Builds the internal widget a different way. Make sure to call the championCallback
  /// so the field updates when selected.
  final Widget Function(AutoCompleteOption option,
          String Function(AutoCompleteOption option) championCallback)?
      optionBuilder;

  AutoCompleteOption({
    String? title,
    required this.value,
    this.isSet = false,
    this.additionalData,
    this.callback,
    this.optionBuilder,
  }) : title = title ?? value;
}
