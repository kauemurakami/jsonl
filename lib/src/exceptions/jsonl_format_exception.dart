/// Exception raised when a JSONL record cannot be parsed as a JSON object.
///
/// The [lineNumber] is one-based and refers to the line in the original
/// JSONL payload. [source] contains the offending line when available.
/// [offset] is the character offset supplied by the JSON decoder, when the
/// failure is a JSON syntax error.
class JsonlFormatException extends FormatException {
  /// The one-based line number containing the invalid record.
  final int lineNumber;

  /// Creates a JSONL format exception.
  const JsonlFormatException(
    String message, {
    required this.lineNumber,
    String? source,
    int? offset,
  }) : super(message, source, offset);

  @override
  String toString() => 'JsonlFormatException at line $lineNumber: $message'
      '${source == null ? '' : '\\nSource: $source'}';
}
