/// If autocomplete is enabled or not, and if it is, what form does it take
enum AutoCompleteType {
  /// No Autocomplete
  none,

  /// The autocomplete will take the form of a dropdown below the field
  /// With suggested options determined by an options builder
  dropdown

  /// The autocomplete will show as ghosted text suggesting how to complete
  /// the thing being typed.
  /// TODO: Implement this
  // autosuggest
}
