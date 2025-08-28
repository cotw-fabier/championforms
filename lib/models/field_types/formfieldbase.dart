// New base class for any element that can be in the form's `fields` list.
abstract class ChampionFormElement {
  const ChampionFormElement();
}

abstract class FormFieldBase extends ChampionFormElement {
  final String id;
  final String? title;
  final String? description;

  FormFieldBase({
    required this.id,
    this.title,
    this.description,
  });
}
