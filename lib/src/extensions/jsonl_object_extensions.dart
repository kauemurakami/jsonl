import '../codec/jsonl_codec_impl.dart';
import '../exceptions/jsonl_format_exception.dart';

/// Convenience parsing and format-conversion extensions for JSONL strings.
extension JsonlStringExtensions on String {
  /// Decodes this JSONL text into one record map or a list of record maps.
  dynamic decodeJsonl({
    bool skipEmptyLines = true,
    void Function(JsonlFormatException error)? onError,
  }) =>
      jsonl.decode(
        this,
        skipEmptyLines: skipEmptyLines,
        onError: onError,
      );

  /// Converts this JSONL text into a JSON array string.
  String jsonlToJson({
    bool skipEmptyLines = true,
    bool pretty = false,
    void Function(JsonlFormatException error)? onError,
  }) =>
      jsonl.jsonlToJson(
        this,
        skipEmptyLines: skipEmptyLines,
        pretty: pretty,
        onError: onError,
      );
}
