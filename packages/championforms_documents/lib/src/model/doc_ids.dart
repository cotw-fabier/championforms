import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A fresh node id (uuid v4). Every node a rule, a paste or a deserializer
/// creates gets one of these, so ids never collide across documents or
/// pastes.
String newNodeId() => _uuid.v4();

/// The shape an id segment must have to be embedded in a `FormController`
/// field id such as `{docId}.{key}`: ASCII letters, digits and underscores.
final RegExp idSegmentPattern = RegExp(r'^[A-Za-z0-9_]+$');

/// Whether [segment] is a valid id segment (see [idSegmentPattern]).
bool isValidIdSegment(String segment) => idSegmentPattern.hasMatch(segment);

/// Returns [segment], or throws [ArgumentError] unless it is a valid id
/// segment. [name] names the parameter in the error (e.g. `"key"`).
String checkIdSegment(String segment, [String name = 'segment']) {
  if (!isValidIdSegment(segment)) {
    throw ArgumentError.value(
      segment,
      name,
      'must match ${idSegmentPattern.pattern}',
    );
  }
  return segment;
}
