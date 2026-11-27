## 0.0.1

- Initial public release of the JSONL / NDJSON toolkit.
- Add synchronous encoding and decoding for individual records and multiple newline-delimited records.
- Add conversion between JSON arrays/objects and JSONL strings.
- Add typed model mapping through `fromJsonl` and `toJsonl` callbacks.
- Add the `JsonlEncodable` interface for model-owned serialization and support direct encoding of models and model collections.
- Add convenience extensions for strings, maps, and iterables.
- Add stream transformers and extensions for text chunks and UTF-8 byte streams, including HTTP response bodies.
- Add JSONL stream encoding for maps and `JsonlEncodable` models.
- Add `JsonlFormatException` with line number and source information.
- Add separate import libraries and the complete `package:jsonl/jsonl.dart` library.
- Add a unified example in `example/main.dart` covering model mapping, encoding, JSON/JSONL conversion, local delayed streams, and optional HTTPBin/HTTPBingo streaming.
- Add tests for incremental stream delivery, delayed records, split text chunks, split UTF-8 multibyte sequences, CRLF, and final unterminated records.
- Add optional live HTTP integration tests for HTTPBin and HTTPBingo, disabled by default.
- Document installation, API usage, streaming examples, unit tests, integration tests, Flutter/Dart workflows, and platform limitations.
- Clarify that `fromJsonl` is a model factory, not a package extension.
- Remove redundant map and iterable `toJsonlString` convenience extensions.

## 0.0.2

- Open github project to reachable reference.
- Fix unecessary library names to get max pub points
