/// Synchronous JSONL record encoding API and the [JsonlEncoder] stream transformer.
///
/// ```dart
/// import 'package:jsonl/jsonl_encode.dart';
/// ```
library jsonl_encode;

export 'src/codec/jsonl_encode_impl.dart';
export 'src/codec/jsonl_encodable.dart';
export 'src/codec/jsonl_codec_impl.dart' show JsonlCodec, jsonl;
export 'src/stream/jsonl_encoder.dart';
