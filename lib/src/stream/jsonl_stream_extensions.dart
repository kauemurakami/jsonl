import 'dart:convert';

import '../exceptions/jsonl_format_exception.dart';
import '../codec/jsonl_encodable.dart';
import 'jsonl_decoder.dart';
import 'jsonl_encoder.dart';

/// JSONL parsing extension for streams of text chunks.
extension JsonlStringStreamExtension on Stream<String> {
  /// Parses incoming JSONL text incrementally into record maps.
  Stream<Map<String, dynamic>> decodeJsonl({
    bool skipEmptyLines = true,
    void Function(JsonlFormatException error)? onError,
  }) =>
      transform(JsonlDecoder(
        skipEmptyLines: skipEmptyLines,
        onError: onError,
      ));
}

/// JSONL parsing extension for UTF-8 byte streams, including HTTP bodies.
extension JsonlByteStreamExtension on Stream<List<int>> {
  /// Decodes UTF-8 chunks and parses JSONL records incrementally.
  Stream<Map<String, dynamic>> decodeUtf8Jsonl({
    bool skipEmptyLines = true,
    void Function(JsonlFormatException error)? onError,
    bool allowMalformedUtf8 = false,
  }) =>
      transform(Utf8Decoder(allowMalformed: allowMalformedUtf8)).decodeJsonl(
        skipEmptyLines: skipEmptyLines,
        onError: onError,
      );
}

/// JSONL encoding extension for streams of maps or JsonlEncodable models.
extension JsonlRecordStreamExtension<T> on Stream<T> {
  /// Encodes every map or model event as one JSONL record.
  ///
  /// Model events must implement [JsonlEncodable].
  Stream<String> encodeJsonl() => transform(JsonlEncoder<T>());
}
