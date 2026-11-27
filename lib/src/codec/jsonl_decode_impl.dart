import 'dart:convert';

import '../exceptions/jsonl_format_exception.dart';

/// Decodes JSONL text into a record map or a list of record maps.
///
/// A single record returns `Map<String, dynamic>`. Multiple records return
/// `List<Map<String, dynamic>>`. Empty input returns an empty list.
dynamic decodeJsonl(
  String source, {
  bool skipEmptyLines = true,
  void Function(JsonlFormatException error)? onError,
}) {
  final records = <Map<String, dynamic>>[];
  final lines = const LineSplitter().convert(source);

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (skipEmptyLines && line.trim().isEmpty) continue;

    try {
      final value = jsonDecode(line);
      if (value is! Map) {
        throw FormatException(
          'Each JSONL record must be a JSON object; '
          'received ${value.runtimeType}.',
        );
      }
      records.add(_stringKeyedMap(value));
    } on FormatException catch (error) {
      final exception = JsonlFormatException(
        error.message,
        lineNumber: i + 1,
        source: line,
        offset: error.offset,
      );
      if (onError == null) throw exception;
      onError(exception);
    }
  }

  if (records.length == 1) return records.single;
  return records;
}

/// Converts a decoded JSON object into a string-keyed record map.
Map<String, dynamic> _stringKeyedMap(Map value) {
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException(
        'JSON object keys must be strings; '
        'received ${entry.key.runtimeType}.',
      );
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}
