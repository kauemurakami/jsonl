import 'dart:async';

import '../codec/jsonl_encode_impl.dart';

/// Encodes each map or JsonlEncodable model from a stream as one JSONL line.
class JsonlEncoder<T> extends StreamTransformerBase<T, String> {
  /// Creates a JSONL stream encoder.
  const JsonlEncoder();

  @override
  Stream<String> bind(Stream<T> stream) =>
      stream.map((record) => encodeJsonl(record as Object));
}
