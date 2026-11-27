import 'dart:convert';

import '../exceptions/jsonl_format_exception.dart';
import 'jsonl_decode_impl.dart';
import 'jsonl_encode_impl.dart';

/// Helpers for converting between standard JSON and JSONL text.
///
/// These functions convert formats. They do not map records to application
/// model classes.
mixin JsonlConverterMixin {
  /// Converts JSONL text into a standard JSON array string.
  ///
  /// JSONL represents a sequence, so this always returns a JSON array,
  /// including when the source contains one record.
  String jsonlToJson(
    String source, {
    bool skipEmptyLines = true,
    bool pretty = false,
    void Function(JsonlFormatException error)? onError,
  }) {
    final decoded = decodeJsonl(
      source,
      skipEmptyLines: skipEmptyLines,
      onError: onError,
    );
    final records = decoded is Map<String, dynamic>
        ? <Map<String, dynamic>>[decoded]
        : decoded as List<Map<String, dynamic>>;
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(records)
        : jsonEncode(records);
  }

  /// Converts a JSON object or array into JSONL text.
  ///
  /// A top-level JSON object becomes one line. Each object in a top-level
  /// array becomes a line. Nested objects and arrays remain nested.
  String jsonToJsonl(Object jsonSource) {
    final value = jsonSource is String ? jsonDecode(jsonSource) : jsonSource;
    if (value is Map) return encodeJsonl(value);
    if (value is List) return encodeJsonl(value);
    throw FormatException(
      'Expected a JSON object or an array of objects; '
      'received ${value.runtimeType}.',
    );
  }
}
