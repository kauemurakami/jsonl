import 'dart:convert';

import 'jsonl_encodable.dart';

/// Encodes a map, a [JsonlEncodable] model, or an iterable of either as JSONL.
///
/// Each top-level item becomes one line. Nested maps and lists stay inside
/// their containing record.
String encodeJsonl(Object data) {
  final records = data is Map || data is JsonlEncodable
      ? <Object?>[data]
      : data is Iterable
          ? data.cast<Object?>()
          : throw ArgumentError.value(
              data,
              'data',
              'Expected a Map, JsonlEncodable model, or an Iterable of them.',
            );

  final buffer = StringBuffer();
  for (final record in records) {
    final map = _recordToMap(record);
    buffer.writeln(jsonEncode(map));
  }
  return buffer.toString();
}

Map<String, dynamic> _recordToMap(Object? record) {
  final Map value;
  if (record is Map) {
    value = record;
  } else if (record is JsonlEncodable) {
    value = record.toJsonl();
  } else {
    throw ArgumentError.value(
      record,
      'record',
      'Every JSONL record must be a Map or implement JsonlEncodable.',
    );
  }

  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw ArgumentError.value(
        entry.key,
        'record key',
        'JSON object keys must be strings.',
      );
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}
