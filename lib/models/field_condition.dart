import 'package:championforms/models/multiselect_option.dart';

/// How the rules of a [FieldCondition] combine.
enum ConditionMatch {
  /// Every rule must hold.
  all,

  /// At least one rule must hold.
  any;

  /// Parses a wire name, defaulting to [all].
  static ConditionMatch parse(String? name) => ConditionMatch.values.firstWhere(
        (value) => value.name == name,
        orElse: () => ConditionMatch.all,
      );
}

/// What a satisfied [FieldCondition] does to its field.
enum ConditionAction {
  /// Show the field when the rules match; hide it otherwise.
  show,

  /// Hide the field when the rules match; show it otherwise.
  hide;

  /// Parses a wire name, defaulting to [show].
  static ConditionAction parse(String? name) =>
      ConditionAction.values.firstWhere(
        (value) => value.name == name,
        orElse: () => ConditionAction.show,
      );
}

/// The comparison one [ConditionRule] performs.
enum ConditionOperator {
  /// Loosely equal — see [ConditionRule.evaluate] for what "loosely" means.
  equals,

  /// The negation of [equals].
  notEquals,

  /// Substring, for text; membership, for a selection.
  contains,

  /// Text prefix.
  startsWith,

  /// Text suffix.
  endsWith,

  /// Null, blank, or an empty selection.
  isEmpty,

  /// The negation of [isEmpty].
  isNotEmpty,

  /// Numerically greater than.
  gt,

  /// Numerically less than.
  lt;

  /// Parses a wire name.
  ///
  /// Throws [FormatException] on anything else, rather than defaulting. A
  /// misspelled operator must not quietly become "always false": a
  /// silently-false rule under a `hide` action *shows* a field that should have
  /// been hidden, and nobody notices until the wrong person answers the wrong
  /// question.
  static ConditionOperator parse(String name) {
    for (final value in ConditionOperator.values) {
      if (value.name == name) return value;
    }
    throw FormatException(
      'Unknown condition operator "$name". Expected one of: '
      '${ConditionOperator.values.map((v) => v.name).join(', ')}.',
    );
  }
}

/// One comparison against another field's current answer.
class ConditionRule {
  /// Creates a rule.
  const ConditionRule({
    required this.fieldId,
    required this.operator,
    this.value,
  });

  /// The id of the field whose answer is read.
  ///
  /// Not required to exist. A rule naming a field that has been deleted
  /// evaluates against `null` rather than throwing, because a form has to keep
  /// working while its author is halfway through editing it.
  final String fieldId;

  /// The comparison to perform.
  final ConditionOperator operator;

  /// The right-hand side. Ignored by [ConditionOperator.isEmpty] and
  /// [ConditionOperator.isNotEmpty].
  final dynamic value;

  /// Decodes `{"fieldId": ..., "operator": ..., "value": ...}`.
  factory ConditionRule.fromJson(Map<String, dynamic> json) {
    final fieldId = json['fieldId'];
    if (fieldId is! String || fieldId.isEmpty) {
      throw FormatException(
        'A condition rule needs a non-empty "fieldId"; got ${json['fieldId']}.',
      );
    }
    final operator = json['operator'];
    if (operator is! String) {
      throw FormatException(
        'Condition rule on "$fieldId" needs an "operator"; got $operator.',
      );
    }
    return ConditionRule(
      fieldId: fieldId,
      operator: ConditionOperator.parse(operator),
      value: json['value'],
    );
  }

  /// The JSON form.
  Map<String, dynamic> toJson() => {
        'fieldId': fieldId,
        'operator': operator.name,
        if (value != null) 'value': value,
      };

  /// Whether this rule holds for [values].
  ///
  /// Comparison is deliberately loose, and the reason is that the two sides
  /// arrive from different worlds. The left side is whatever the controller is
  /// holding — a `String` from a text field, a `List<FieldOption>` from a
  /// select, a `bool` from a checkbox. The right side came out of a document
  /// and is a JSON scalar. A strict `==` between `'2'` and `2` is false, and a
  /// form author who wrote `{"fieldId": "qty", "operator": "gt", "value": 1}`
  /// would watch their rule never fire with no indication why.
  ///
  /// So: selections are reduced to their option values, everything is compared
  /// as text unless both sides parse as numbers, and `gt`/`lt` are numeric
  /// only.
  bool evaluate(Map<String, dynamic> values) {
    final actual = values[fieldId];

    switch (operator) {
      case ConditionOperator.isEmpty:
        return _isEmpty(actual);
      case ConditionOperator.isNotEmpty:
        return !_isEmpty(actual);
      case ConditionOperator.gt:
        final a = _asNumber(actual);
        final b = _asNumber(value);
        return a != null && b != null && a > b;
      case ConditionOperator.lt:
        final a = _asNumber(actual);
        final b = _asNumber(value);
        return a != null && b != null && a < b;
      case ConditionOperator.equals:
        return _looselyEquals(actual, value);
      case ConditionOperator.notEquals:
        return !_looselyEquals(actual, value);
      case ConditionOperator.contains:
        // Membership for a selection, substring for text. Both are what a
        // form author means by "contains" for the field they are looking at.
        final selected = _selection(actual);
        if (selected != null) {
          return selected.contains(_asText(value));
        }
        return _asText(actual).contains(_asText(value));
      case ConditionOperator.startsWith:
        return _asText(actual).startsWith(_asText(value));
      case ConditionOperator.endsWith:
        return _asText(actual).endsWith(_asText(value));
    }
  }

  static bool _looselyEquals(dynamic actual, dynamic expected) {
    final selected = _selection(actual);
    if (selected != null) {
      // A single-select holding one option equals that option's value; a
      // multi-select equals nothing scalar, which is what `contains` is for.
      return selected.length == 1 && selected.first == _asText(expected);
    }
    if (actual is bool || expected is bool) {
      return _asBool(actual) == _asBool(expected);
    }
    final a = _asNumber(actual);
    final b = _asNumber(expected);
    if (a != null && b != null) return a == b;
    return _asText(actual) == _asText(expected);
  }

  static bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is Iterable) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    if (value is bool) return !value;
    return false;
  }

  /// The option values behind a selection, or null when [value] is not one.
  static List<String>? _selection(dynamic value) {
    if (value is FieldOption) return [value.value];
    if (value is Iterable) {
      return value
          .map((entry) => entry is FieldOption ? entry.value : '$entry')
          .toList();
    }
    return null;
  }

  static String _asText(dynamic value) {
    if (value == null) return '';
    if (value is FieldOption) return value.value;
    return '$value';
  }

  static num? _asNumber(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim());
    return null;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is Iterable) return value.isNotEmpty;
    return value != null;
  }

  @override
  String toString() => 'ConditionRule($fieldId ${operator.name} $value)';
}

/// Serializable show/hide logic for a field, evaluated against the form's live
/// values.
///
/// Before this existed, a `Field` could only be hidden by the static
/// `hideField` flag, decided once when the field was constructed. Anything
/// dynamic meant rebuilding the field list yourself on every change — which
/// works, but cannot be expressed in a document, so a form that arrives as data
/// had no way to say "ask for the team size only if they said they are a team".
///
/// ```dart
/// TextField(
///   id: 'team_size',
///   title: 'How many people?',
///   conditional: const FieldCondition(
///     rules: [
///       ConditionRule(
///         fieldId: 'role',
///         operator: ConditionOperator.equals,
///         value: 'team',
///       ),
///     ],
///   ),
/// )
/// ```
///
/// The controller evaluates this on every value change; a field the condition
/// hides is not rendered **and is not validated**, on the same argument that
/// `hideField` already made — a required field behind a false condition must
/// never block a submission the person was never given a chance to satisfy.
class FieldCondition {
  /// Creates a condition.
  const FieldCondition({
    required this.rules,
    this.match = ConditionMatch.all,
    this.action = ConditionAction.show,
  });

  /// How [rules] combine.
  final ConditionMatch match;

  /// What a match does.
  final ConditionAction action;

  /// The rules.
  ///
  /// An empty list makes the condition inert — [isVisible] returns true — so a
  /// half-written condition in a builder shows its field rather than making it
  /// disappear with no way to get it back.
  final List<ConditionRule> rules;

  /// Decodes `{"match": ..., "action": ..., "rules": [...]}`.
  factory FieldCondition.fromJson(Map<String, dynamic> json) {
    final rules = json['rules'];
    if (rules != null && rules is! List) {
      throw FormatException('A condition\'s "rules" must be a list; got $rules.');
    }
    return FieldCondition(
      match: ConditionMatch.parse(json['match'] as String?),
      action: ConditionAction.parse(json['action'] as String?),
      rules: [
        for (final rule in (rules as List? ?? const []))
          ConditionRule.fromJson(Map<String, dynamic>.from(rule as Map)),
      ],
    );
  }

  /// The JSON form.
  Map<String, dynamic> toJson() => {
        'match': match.name,
        'action': action.name,
        'rules': rules.map((rule) => rule.toJson()).toList(),
      };

  /// Whether the field carrying this condition should be visible for [values].
  bool isVisible(Map<String, dynamic> values) {
    if (rules.isEmpty) return true;
    final matched = match == ConditionMatch.all
        ? rules.every((rule) => rule.evaluate(values))
        : rules.any((rule) => rule.evaluate(values));
    return action == ConditionAction.show ? matched : !matched;
  }

  /// The ids this condition reads.
  ///
  /// Useful to a builder that wants to warn about a rule pointing at a field
  /// that no longer exists, and to anything that needs to know which changes
  /// can affect this field's visibility.
  Set<String> get dependencies => rules.map((rule) => rule.fieldId).toSet();

  @override
  String toString() =>
      'FieldCondition(${action.name} if ${match.name} of $rules)';
}
