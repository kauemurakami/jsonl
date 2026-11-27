import '../exceptions/jsonl_format_exception.dart';
import 'jsonl_converter_impl.dart';
import 'jsonl_encodable.dart';
import 'jsonl_decode_impl.dart';
import 'jsonl_encode_impl.dart';

/// Default JSONL codec instance.
const JsonlCodec jsonl = JsonlCodec();

/// Parses JSONL text into record maps and encodes maps or model objects.
///
/// `decode` returns a map for one record and a list of maps for multiple
/// records. `encode` accepts maps and iterables of maps. It also accepts
/// models that implement [JsonlEncodable].
class JsonlCodec with JsonlConverterMixin {
  /// Creates a JSONL codec.
  const JsonlCodec();

  /// Decodes JSONL text into a record map or a list of record maps.
  ///
  /// Each non-empty line must contain a JSON object.
  /// Returns an empty list for empty input.
  dynamic decode(
    String source, {
    bool skipEmptyLines = true,
    void Function(JsonlFormatException error)? onError,
  }) =>
      decodeJsonl(
        source,
        skipEmptyLines: skipEmptyLines,
        onError: onError,
      );

  /// Encodes one map/model or an iterable of maps/models as JSONL text.
  ///
  /// Models must implement [JsonlEncodable], providing their own `toJsonl`
  /// method. Alternatively, pass the result of `model.toJsonl()` directly.
  String encode(Object data) => encodeJsonl(data);
}
