/// Conversion API between JSONL text and standard JSON text.
///
/// ```dart
/// import 'package:jsonl/jsonl_converter.dart';
///
/// final jsonlText = jsonl.jsonToJsonl(jsonText);
/// final jsonText = jsonl.jsonlToJson(jsonlText);
/// ```
library jsonl_converter;

export 'src/codec/jsonl_converter_impl.dart';
export 'src/codec/jsonl_codec_impl.dart' show JsonlCodec, jsonl;
export 'src/exceptions/jsonl_format_exception.dart';
