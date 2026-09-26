import 'rule.dart';

typedef DocRuleFromJson = DocRule Function(Map<String, dynamic> json);

/// Maps rule names to decoders so a [RuleSet] can arrive as JSON.
///
/// Built-in rules register themselves in `RuleRegistry.ensureInitialized`
/// (stage S2e). Unknown names throw [FormatException]: a rule that silently
/// disappears stops protecting the data it was written for.
abstract final class RuleRegistry {
  static final Map<String, DocRuleFromJson> _decoders = {};

  static void register(String ruleName, DocRuleFromJson fromJson) =>
      _decoders[ruleName] = fromJson;

  static bool isRegistered(String ruleName) => _decoders.containsKey(ruleName);

  static DocRule fromJson(Map<String, dynamic> json) {
    final name = json['rule'];
    final decode = name is String ? _decoders[name] : null;
    if (decode == null) throw FormatException('Unknown document rule "$name"');
    return decode(json);
  }

  static Map<String, dynamic> toJson(DocRule rule) => {
    'rule': rule.ruleName,
    ...rule.toJson(),
  };
}

/// The rules one document runs, grouped by kind.
final class RuleSet {
  const RuleSet({
    this.transforms = const [],
    this.extracts = const [],
    this.constraints = const [],
  });

  static const empty = RuleSet();

  final List<TransformRule> transforms;
  final List<ExtractRule> extracts;
  final List<ConstraintRule> constraints;

  Map<String, dynamic> toJson() => {
    'transforms': [for (final r in transforms) RuleRegistry.toJson(r)],
    'extracts': [for (final r in extracts) RuleRegistry.toJson(r)],
    'constraints': [for (final r in constraints) RuleRegistry.toJson(r)],
  };

  factory RuleSet.fromJson(Map<String, dynamic> json) {
    List<T> read<T extends DocRule>(String key) => [
      for (final r in (json[key] as List?) ?? const [])
        switch (RuleRegistry.fromJson((r as Map).cast<String, dynamic>())) {
          final T rule => rule,
          final other => throw FormatException(
            '"$key" expects ${T.toString()}, got ${other.ruleName}',
          ),
        },
    ];
    return RuleSet(
      transforms: read<TransformRule>('transforms'),
      extracts: read<ExtractRule>('extracts'),
      constraints: read<ConstraintRule>('constraints'),
    );
  }
}
