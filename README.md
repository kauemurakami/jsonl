# jsonl

A lightweight JSON Lines (JSONL / NDJSON) parser, encoder, converter, and streaming toolkit for Dart and Flutter.

The package works directly with JSONL records represented as `Map<String, dynamic>`.
It does not convert a JSONL stream into JSON text and back again.

## Install

```yaml
dependencies:
  jsonl: ^0.0.3
```

```dart
import 'package:jsonl/jsonl.dart';
```

## Decode JSONL into maps

`jsonl.decode` parses each JSONL line directly into a map:

```dart
final record = jsonl.decode('{"id":1,"title":"Hello"}');
// Map<String, dynamic>

final records = jsonl.decode('''
{"id":1,"title":"Hello"}
{"id":2,"title":"World"}
''');
// List<Map<String, dynamic>>
```

The return shape follows the number of records:
- No records: an empty `List<Map<String, dynamic>>`.
- One record: a `Map<String, dynamic>`.
- More than one record: a `List<Map<String, dynamic>>`.

Every JSONL record must be a JSON object. JSON values inside a record are
already parsed into Dart values: integers become `int`, decimal numbers
become `double`, strings become `String`, booleans become `bool`, arrays
become `List`, nested objects become maps, and `null` becomes `null`.

Top-level JSONL records must have string keys, as required by JSON.

## Map records to your Dart models

The package does not need to know your model classes. Define the factory and
instance method in your model:

```dart
class Post implements JsonlEncodable {
  final int id;
  final String title;

  const Post({required this.id, required this.title});

  factory Post.fromJsonl(Map<String, dynamic> jsonl) => Post(
        id: jsonl['id'],
        title: jsonl['title'],
      );

  @override
  Map<String, dynamic> toJsonl() => {
        'id': id,
        'title': title,
      };
}
```

Map one decoded record:

```dart
final Map<String, dynamic> record =
    jsonl.decode('{"id":1,"title":"Hello"}');

final post = Post.fromJsonl(record);
```

Map multiple records:

```dart
final List<Map<String, dynamic>> records = jsonl.decode(jsonlText);

final posts = records.map(Post.fromJsonl).toList();
```

To let `jsonl.encode` accept model objects directly, implement the
package's `JsonlEncodable` interface. This requires the model to provide its
own `toJsonl()` method:

```dart
class Post implements JsonlEncodable {
  // Fields, constructor, and fromJsonl factory omitted here.

  @override
  Map<String, dynamic> toJsonl() => {
    'id': id,
    'title': title,
  };
}

final oneRecord = jsonl.encode(post);
final multipleRecords = jsonl.encode(posts);
```

If you do not want your model to implement `JsonlEncodable`, you can still
pass its map explicitly: `jsonl.encode(post.toJsonl())`. `jsonl.encode` does
not use reflection or guess how arbitrary objects should be serialized.

This keeps the responsibilities explicit:
- `jsonl.decode`: JSONL text → record map(s).
- `Post.fromJsonl`: record map → `Post`.
- `post.toJsonl`: `Post` → record map.
- `jsonl.encode`: record map(s) → JSONL text.

The package intentionally does not try to discover a static `T.fromJsonl`
factory automatically. Dart generic type parameters cannot invoke arbitrary
factory constructors by reflection. Calling `Post.fromJsonl` or using
`.map(Post.fromJsonl)` is explicit and type-safe.

## Encode maps directly

`jsonl.encode` accepts one map, one `JsonlEncodable` model, or an iterable of either:

```dart
final oneRecord = jsonl.encode({
  'id': 1,
  'title': 'Hello',
});

final multipleRecords = jsonl.encode([
  {'id': 1, 'title': 'Hello'},
  {'id': 2, 'title': 'World'},
]);

// Models implementing JsonlEncodable are also accepted.
final modelRecords = jsonl.encode([firstPost, secondPost]);
```

Each top-level map becomes one line. Nested maps and lists remain inside
their record; only a top-level iterable is treated as multiple records.
All record keys must be strings.

## JSON ↔ JSONL format conversion

These are separate format-conversion helpers. They do not map records to
Dart model classes.

```dart
// JSON object or array -> JSONL.
final jsonlText = jsonl.jsonToJsonl(
  '[{"id":1},{"id":2}]',
);

// JSONL -> JSON array string.
final jsonText = jsonl.jsonlToJson(jsonlText, pretty: true);
```

A top-level JSON object becomes one JSONL record. A top-level JSON array
becomes one record per array item. Each array item must be an object.
`jsonlToJson` always returns a JSON array because JSONL represents a sequence.

For ordinary JSON parsing/encoding unrelated to JSONL, use Dart's
`jsonDecode` and `jsonEncode` from `dart:convert`.

## HTTP and streaming

The byte-stream extension parses an HTTP response body incrementally.
It decodes UTF-8 and emits a map for each completed JSONL line. It does not
build a JSON string containing the entire response.

```dart
import 'dart:io';
import 'package:jsonl/jsonl.dart';

final client = HttpClient();
try {
  final request = await client.getUrl(
    Uri.parse('https://example.com/posts.jsonl'),
  );
  final response = await request.close();

  await for (final record in response.decodeUtf8Jsonl()) {
    final post = Post.fromJsonl(record);
    print(post.title);
  }
} finally {
  client.close(force: true);
}
```

For a stream that already emits text chunks:

```dart
await for (final record in textChunks.decodeJsonl()) {
  // One Map<String, dynamic> per JSONL record.
}
```

To encode a stream of maps or `JsonlEncodable` models:

```dart
final Stream<String> jsonlChunks = mapStream.encodeJsonl();
```

The decoder handles chunks that end in the middle of a record and UTF-8
characters split across byte chunks.

## Complete example

All package examples are combined in a single file: `example/main.dart`.
It demonstrates model mapping, encoding, JSON/JSONL conversion, a local
delayed stream, and optional live HTTP streaming with HTTPBin and HTTPBingo.

Run the local examples (no internet connection required):

```bash
dart run example/main.dart
```

Run the HTTP streaming examples as well:

```bash
dart run example/main.dart --network
```

The `--network` option enables requests to:

1. `https://httpbin.org/stream/3`, which returns newline-delimited JSON objects.
2. `https://httpbingo.org/jsonl?count=3&duration=3s`, which sends JSONL records gradually over the response.

The HTTP examples use `dart:io` and `HttpClient`. They run on the Dart VM
and Flutter native targets (Android, iOS, Windows, Linux, and macOS), but not
in Flutter Web. The package's core encode/decode and text-stream APIs do not
require `dart:io`; the HTTP client example is intentionally kept in this
VM/native-only example.

## Testing

The package has local unit tests and optional live HTTP integration tests.
The default test suite does not require an internet connection.

### 1. Get dependencies

With the Dart SDK:

```bash
dart pub get
```

With the Flutter SDK:

```bash
flutter pub get
```

### 2. Run the package unit tests

Run the package's own unit tests with the Dart test runner:

```bash
dart test
```

This package is a pure Dart library designed to be consumed by Dart and
Flutter applications. Its own test suite uses `package:test`, so `dart test`
is the canonical command at the package root.

If you are testing the package from a Flutter application, add it as a
regular dependency and use `flutter_test` in that application's
`dev_dependencies`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
```

Then run the consumer application's tests from that application's directory:

```bash
flutter pub get
flutter test
```

The local package test suite covers:

- Decoding one record, multiple records, and empty input.
- Nested objects and arrays, primitive values, and invalid top-level records.
- Malformed-line reporting, line numbers, and the error callback.
- Mapping records to models and encoding maps or `JsonlEncodable` models.
- JSON ↔ JSONL conversion.
- Incremental stream delivery and delayed local records.
- Text chunks split in the middle of a JSONL record.
- UTF-8 multibyte characters split across byte chunks.
- CRLF line endings and a final record without a trailing newline.
- Stream mapping to models and stream encoding of maps/models.

### 3. Run HTTP integration tests

Two optional integration tests in `integration_test/http_jsonl_test.dart`
call HTTPBin and HTTPBingo. They are skipped by default so normal tests do
not depend on external services.

Linux / macOS:

```bash
JSONL_RUN_NETWORK_TESTS=true dart test integration_test
```

Windows PowerShell:

```powershell
$env:JSONL_RUN_NETWORK_TESTS = "true"
dart test integration_test
```

Windows CMD:

```cmd
set JSONL_RUN_NETWORK_TESTS=true
dart test integration_test
```

These tests use `dart:io`, so run them on the Dart VM or a native development
host. They are not Flutter Web tests. A network connection is required.

### 4. Run all checks

Dart:

```bash
dart format .
dart analyze
dart test
JSONL_RUN_NETWORK_TESTS=true dart test integration_test
```

Flutter application consuming this package:

```bash
flutter pub get
flutter analyze
flutter test
```

Run the package's own unit and HTTP integration suites from the package root
with the Dart commands above. The HTTP integration tests remain a separate
Dart VM command because they use `HttpClient` and an environment variable to
opt in to live network calls.

## Errors and blank lines

Malformed records throw `JsonlFormatException` by default. It includes the
one-based line number and offending source line.

```dart
final errors = <JsonlFormatException>[];

final records = jsonl.decode(
  jsonlText,
  onError: errors.add,
);
```

When `onError` is provided, invalid records are skipped and parsing continues.
Blank lines are ignored by default. Set `skipEmptyLines: false` to treat a
blank line as an invalid record.

## API overview

| API | Responsibility |
| --- | --- |
| `jsonl.decode(text)` | JSONL → one Map or a list of Maps |
| `jsonl.encode(mapOrModels)` | Map(s) or JsonlEncodable model(s) → JSONL |
| `jsonl.jsonToJsonl(json)` | JSON → JSONL |
| `jsonl.jsonlToJson(text)` | JSONL → JSON array text |
| `stream.decodeJsonl()` | Text stream → stream of Maps |
| `stream.decodeUtf8Jsonl()` | UTF-8 byte stream → stream of Maps |
| `stream.encodeJsonl()` | Stream of Maps/models → JSONL text chunks |

## Focused imports

- `package:jsonl/jsonl_codec.dart`
- `package:jsonl/jsonl_converter.dart`
- `package:jsonl/jsonl_decode.dart`
- `package:jsonl/jsonl_encode.dart`
- `package:jsonl/jsonl_exception.dart`
- `package:jsonl/jsonl_extensions.dart`
- `package:jsonl/jsonl_stream.dart`

Or import the complete API with `package:jsonl/jsonl.dart`.

## Development

Format and analyze the package before submitting changes:

```bash
dart format .
dart analyze
dart test
```

## References

- [NDJSON specification](https://github.com/ndjson/ndjson-spec) — framing,
  UTF-8 encoding, line delimiters, and parsing behavior.
- [HTTPBin](https://httpbin.org/) — `/stream/:n` endpoint for testing
  newline-delimited JSON responses.
- [HTTPBingo](https://httpbingo.org/) — `/jsonl` endpoint for timed JSONL
  streaming responses.
