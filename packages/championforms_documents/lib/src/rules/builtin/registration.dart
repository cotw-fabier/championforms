import '../rule.dart';
import '../rule_set.dart';
import 'constraints.dart';
import 'extracts.dart';
import 'transforms.dart';

/// Registers every built-in rule's decoder with [RuleRegistry].
///
/// Safe to call repeatedly. Most code should call
/// [DocumentRules.ensureInitialized] instead.
void registerBuiltinRules() {
  // Transforms.
  RuleRegistry.register(MarkdownPrefixRule.name, MarkdownPrefixRule.fromJson);
  RuleRegistry.register(EnterSplitsRule.name, EnterSplitsRule.fromJson);
  RuleRegistry.register(BackspaceMergesRule.name, BackspaceMergesRule.fromJson);
  // Extracts.
  RuleRegistry.register(MentionsExtract.name, MentionsExtract.fromJson);
  RuleRegistry.register(DatesExtract.name, DatesExtract.fromJson);
  RuleRegistry.register(SectionTextExtract.name, SectionTextExtract.fromJson);
  RuleRegistry.register(RegexExtract.name, RegexExtract.fromJson);
  RuleRegistry.register(TaskStatusExtract.name, TaskStatusExtract.fromJson);
  RuleRegistry.register(HasSectionExtract.name, HasSectionExtract.fromJson);
  // Constraints.
  RuleRegistry.register(RequiredSectionRule.name, RequiredSectionRule.fromJson);
  RuleRegistry.register(MinLengthRule.name, MinLengthRule.fromJson);
  RuleRegistry.register(MaxLengthRule.name, MaxLengthRule.fromJson);
  RuleRegistry.register(
    ForbiddenPatternRule.name,
    ForbiddenPatternRule.fromJson,
  );
}

/// Entry point for the built-in document rules.
abstract final class DocumentRules {
  static bool _initialized = false;

  /// Registers the built-in rules so `RuleSet.fromJson` can decode them.
  /// Idempotent; call it once at startup (e.g. in `main()`), before loading
  /// any rule set from JSON.
  static void ensureInitialized() {
    if (_initialized) return;
    registerBuiltinRules();
    _initialized = true;
  }

  /// The editing behavior most documents want, in priority order: markdown
  /// shortcuts (including `---` + Enter), then Enter splitting, then
  /// Backspace merging.
  static const List<TransformRule> defaultTransforms = [
    MarkdownPrefixRule(),
    EnterSplitsRule(),
    BackspaceMergesRule(),
  ];
}
