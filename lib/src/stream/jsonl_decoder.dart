import 'dart:async';
import 'dart:convert';

import '../exceptions/jsonl_format_exception.dart';

/// Parses incoming text chunks into JSONL record maps.
class JsonlDecoder extends StreamTransformerBase<String, Map<String, dynamic>> {
  /// Whether blank records are ignored.
  final bool skipEmptyLines;

  /// Receives malformed-record errors when supplied.
  final void Function(JsonlFormatException error)? onError;

  /// Creates a JSONL stream decoder.
  const JsonlDecoder({
    this.skipEmptyLines = true,
    this.onError,
  });

  @override
  Stream<Map<String, dynamic>> bind(Stream<String> stream) {
    var lineNumber = 0;
    return stream.transform(const LineSplitter()).transform(
      StreamTransformer<String, Map<String, dynamic>>.fromHandlers(
        handleData: (line, sink) {
          lineNumber++;
          if (skipEmptyLines && line.trim().isEmpty) return;
          try {
            final value = jsonDecode(line);
            if (value is! Map) {
              throw FormatException(
                'Each JSONL record must be a JSON object; '
                'received ${value.runtimeType}.',
              );
            }
            final record = <String, dynamic>{};
            for (final entry in value.entries) {
              if (entry.key is! String) {
                throw const FormatException(
                  'JSON object keys must be strings.',
                );
              }
              record[entry.key as String] = entry.value;
            }
            sink.add(record);
          } on FormatException catch (error) {
            final exception = JsonlFormatException(
              error.message,
              lineNumber: lineNumber,
              source: line,
              offset: error.offset,
            );
            if (onError == null) {
              sink.addError(exception);
            } else {
              onError!(exception);
            }
          }
        },
      ),
    );
  }
}
