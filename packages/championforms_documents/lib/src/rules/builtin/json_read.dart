/// Strict readers for rule configuration JSON. Rule sets can arrive from a
/// server, so a wrong shape is a [FormatException], never a silent default.
library;

T readRequired<T>(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! T) {
    throw FormatException(
      'Rule "${json['rule']}" needs "$key" of type $T, got ${v.runtimeType}',
    );
  }
  return v;
}

T readOptional<T>(Map<String, dynamic> json, String key, T fallback) {
  final v = json[key];
  if (v == null) return fallback;
  if (v is! T) {
    throw FormatException(
      'Rule "${json['rule']}": "$key" must be $T, got ${v.runtimeType}',
    );
  }
  return v;
}

T? readNullable<T>(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v == null) return null;
  if (v is! T) {
    throw FormatException(
      'Rule "${json['rule']}": "$key" must be $T, got ${v.runtimeType}',
    );
  }
  return v;
}
