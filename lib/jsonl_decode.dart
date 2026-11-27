/// Synchronous JSONL record parsing API and the [JsonlDecoder] stream transformer.
///
/// ```dart
/// import 'package:jsonl/jsonl_decode.dart';
/// ```
library jsonl_decode;

export 'src/codec/jsonl_decode_impl.dart';
export 'src/codec/jsonl_codec_impl.dart' show JsonlCodec, jsonl;
export 'src/exceptions/jsonl_format_exception.dart';
export 'src/stream/jsonl_decoder.dart';
