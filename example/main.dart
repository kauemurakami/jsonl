import 'dart:async';
import 'dart:io';

import 'package:jsonl/jsonl.dart';

/// A small application model that can serialize itself as a JSONL record.
class Post implements JsonlEncodable {
  final int id;
  final String title;

  const Post({required this.id, required this.title});

  /// Creates a [Post] from a decoded JSONL record.
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

/// Runs the synchronous, local-stream, and optionally live HTTP examples.
///
/// By default, this example does not access the network. Pass `--network` to
/// also run the HTTPBin and HTTPBingo streaming demonstrations.
Future<void> main(List<String> args) async {
  demonstrateModelAndConversionApis();
  await consumeSimulatedStream();

  if (args.contains('--network')) {
    await consumeHttpbinStream();
    await consumeHttpbingoJsonlStream();
  } else {
    print('\nSkipping live HTTP examples. Run with --network to enable them.');
  }
}

/// Demonstrates decoding, model mapping, encoding, and format conversion.
void demonstrateModelAndConversionApis() {
  print('--- Decode, model mapping, and encode ---');

  const source = '''
{"id":1,"title":"First"}
{"id":2,"title":"Second"}
''';

  // Decode JSONL directly into record maps.
  final records = jsonl.decode(source) as List<Map<String, dynamic>>;

  // The application model owns the Map -> Post mapping.
  final posts = records.map(Post.fromJsonl).toList();
  for (final post in posts) {
    print('${post.id}: ${post.title}');
  }

  // JsonlEncodable lets the package encode models directly.
  final encoded = jsonl.encode(posts);
  print('\nEncoded JSONL:\n$encoded');

  // Convert JSON text to JSONL text independently of model mapping.
  const json = '[{"id":3,"title":"Third"},{"id":4,"title":"Fourth"}]';
  final convertedToJsonl = jsonl.jsonToJsonl(json);
  final convertedBackToJson = jsonl.jsonlToJson(convertedToJsonl, pretty: true);
  print('Converted back to JSON:\n$convertedBackToJson');
}

/// Consumes a local delayed stream without requiring a network connection.
Future<void> consumeSimulatedStream() async {
  print('\n--- Simulated delayed JSONL stream ---');

  await for (final record in _delayedJsonlChunks().decodeJsonl()) {
    print('Received local record: $record');
  }
}

/// Emits JSONL chunks over time, without relying on a network connection.
Stream<String> _delayedJsonlChunks() async* {
  yield '{"id":1,"source":"local"}\n';
  await Future<void>.delayed(const Duration(milliseconds: 500));
  yield '{"id":2,"source":"local"}\n';
  await Future<void>.delayed(const Duration(milliseconds: 500));
  yield '{"id":3,"source":"local"}\n';
}

/// Reads three newline-delimited JSON objects from HTTPBin.
///
/// This live example requires internet access and the Dart VM (or a Flutter
/// native target), because it uses [HttpClient] from `dart:io`.
Future<void> consumeHttpbinStream() async {
  print('\n--- HTTPBin line-delimited response ---');

  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('https://httpbin.org/stream/3'),
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final response = await request.close();
    _checkSuccessfulResponse(response.statusCode);

    await for (final record in response.decodeUtf8Jsonl()) {
      print('HTTPBin record id: ${record['id']}');
    }
  } finally {
    client.close(force: true);
  }
}

/// Reads timed JSONL records from HTTPBingo.
///
/// The endpoint supports `count` and `duration` query parameters and sends
/// records gradually over the response.
Future<void> consumeHttpbingoJsonlStream() async {
  print('\n--- HTTPBingo timed JSONL response ---');

  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('https://httpbingo.org/jsonl?count=3&duration=3s'),
    );
    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/x-ndjson',
    );

    final response = await request.close();
    _checkSuccessfulResponse(response.statusCode);

    await for (final record in response.decodeUtf8Jsonl()) {
      print('HTTPBingo record: $record');
    }
  } finally {
    client.close(force: true);
  }
}

/// Throws when an HTTP endpoint responds with a non-success status code.
void _checkSuccessfulResponse(int statusCode) {
  if (statusCode < 200 || statusCode >= 300) {
    throw HttpException('Unexpected HTTP status: $statusCode');
  }
}
