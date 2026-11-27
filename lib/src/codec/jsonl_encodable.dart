/// Contract for Dart model objects that can be encoded as JSONL records.
///
/// Implement this interface when you want to pass a model directly to
/// `jsonl.encode(model)` or include it in `jsonl.encode([models])`.
abstract interface class JsonlEncodable {
  /// Returns the JSON object representing this model as one JSONL record.
  Map<String, dynamic> toJsonl();
}
