import 'dart:async';
import 'dart:convert';

import 'package:jsonl/jsonl.dart';
import 'package:test/test.dart';

class Post implements JsonlEncodable {
  final int id;
  final String title;

  const Post({required this.id, required this.title});

  factory Post.fromJsonl(Map<String, dynamic> jsonl) => Post(
        id: jsonl['id'],
        title: jsonl['title'],
      );

  @override
  Map<String, dynamic> toJsonl() => {'id': id, 'title': title};
}

void main() {
  group('JSONL record decoding', () {
    test('decodes one record into a Map', () {
      final Map<String, dynamic> record = jsonl.decode('{"id":1,"title":"A"}');
      expect(record, {'id': 1, 'title': 'A'});
      expect(record['id'], isA<int>());
    });

    test('decodes multiple records into a list of Maps', () {
      final List<Map<String, dynamic>> records = jsonl.decode(
        '{"id":1,"title":"A"}\n{"id":2,"title":"B"}',
      );
      expect(records, [
        {'id': 1, 'title': 'A'},
        {'id': 2, 'title': 'B'},
      ]);
    });

    test('returns an empty list for empty input', () {
      expect(jsonl.decode(''), isEmpty);
      expect(jsonl.decode('\n  \n'), isEmpty);
    });

    test('preserves nested arrays and objects', () {
      final Map<String, dynamic> record = jsonl.decode(
        '{"items":[{"id":1}],"meta":{"ok":true}}',
      );
      expect(record['items'], [
        {'id': 1}
      ]);
      expect(record['meta'], {'ok': true});
    });

    test('parses primitive JSON values into Dart primitive types', () {
      final Map<String, dynamic> record = jsonl.decode(
        '{"int":12,"double":19.5,"string":"x","bool":true,"nil":null}',
      );
      expect(record['int'], isA<int>());
      expect(record['double'], isA<double>());
      expect(record['string'], isA<String>());
      expect(record['bool'], isA<bool>());
      expect(record['nil'], isNull);
    });

    test('rejects non-object JSONL records', () {
      expect(
        () => jsonl.decode('42'),
        throwsA(isA<JsonlFormatException>()),
      );
    });

    test('reports malformed line number', () {
      expect(
        () => jsonl.decode('{"id":1}\n{bad}'),
        throwsA(isA<JsonlFormatException>().having(
          (error) => error.lineNumber,
          'lineNumber',
          2,
        )),
      );
    });

    test('skips invalid records when onError is supplied', () {
      final errors = <JsonlFormatException>[];
      final List<Map<String, dynamic>> records = jsonl.decode(
        '{"id":1}\n{bad}\n{"id":2}',
        onError: errors.add,
      );
      expect(records.length, 2);
      expect(errors.single.lineNumber, 2);
    });

    test('maps decoded records to models in application code', () {
      final List<Map<String, dynamic>> records = jsonl.decode(
        '{"id":4,"title":"Dart"}\n{"id":5,"title":"Flutter"}',
      );

      final posts = records.map(Post.fromJsonl).toList();

      expect(posts, hasLength(2));

      expect(posts[0].id, 4);
      expect(posts[0].title, 'Dart');

      expect(posts[1].id, 5);
      expect(posts[1].title, 'Flutter');
    });
  });

  group('JSONL record encoding', () {
    test('encodes one Map as one record', () {
      expect(
        jsonl.encode({'id': 1, 'title': 'A'}),
        '{"id":1,"title":"A"}\n',
      );
    });

    test('encodes an iterable of Maps as multiple records', () {
      expect(
        jsonl.encode([
          {'id': 1},
          {'id': 2},
        ]),
        '{"id":1}\n{"id":2}\n',
      );
    });

    test('encodes a model directly through JsonlEncodable', () {
      const post = Post(id: 1, title: 'A');
      expect(jsonl.encode(post), '{"id":1,"title":"A"}\n');
    });

    test('encodes a list of models directly through JsonlEncodable', () {
      final posts = [
        const Post(id: 1, title: 'A'),
        const Post(id: 2, title: 'B'),
      ];
      expect(
        jsonl.encode(posts),
        '{"id":1,"title":"A"}\n{"id":2,"title":"B"}\n',
      );
    });

    test('keeps nested arrays and objects within a record', () {
      expect(
        jsonl.encode({
          'items': [
            {'id': 1}
          ],
          'meta': {'ok': true},
        }),
        '{"items":[{"id":1}],"meta":{"ok":true}}\n',
      );
    });

    test('rejects a non-map record in a top-level iterable', () {
      expect(
        () => jsonl.encode([
          {'id': 1},
          2,
        ]),
        throwsArgumentError,
      );
    });
  });

  group('JSON and JSONL format conversion', () {
    test('converts a JSON array to JSONL', () {
      expect(
        jsonl.jsonToJsonl('[{"id":1},{"id":2}]'),
        '{"id":1}\n{"id":2}\n',
      );
    });

    test('converts a JSON object to one JSONL record', () {
      expect(jsonl.jsonToJsonl('{"id":1}'), '{"id":1}\n');
    });

    test('converts JSONL to a JSON array string', () {
      expect(
        jsonDecode(jsonl.jsonlToJson('{"id":1}\n{"id":2}')),
        [
          {'id': 1},
          {'id': 2}
        ],
      );
    });

    test('jsonlToJson returns an array for a single record', () {
      expect(jsonDecode(jsonl.jsonlToJson('{"id":1}')), [
        {'id': 1}
      ]);
    });
  });

  group('streaming JSONL', () {
    test('emits a record before the source stream completes', () async {
      final controller = StreamController<String>();
      final firstRecord = Completer<Map<String, dynamic>>();
      final subscription = controller.stream.decodeJsonl().listen((record) {
        if (!firstRecord.isCompleted) firstRecord.complete(record);
      });
      final done = subscription.asFuture<void>();

      controller.add('{"id":1}\n');

      final record = await firstRecord.future.timeout(
        const Duration(seconds: 1),
      );
      expect(record, {'id': 1});

      await controller.close();
      await done;
    });

    test('decodes records arriving over time from a simulated source',
        () async {
      final received = <Map<String, dynamic>>[];

      await for (final record in _delayedJsonlChunks().decodeJsonl()) {
        received.add(record);
      }

      expect(received, [
        {'id': 1, 'source': 'local'},
        {'id': 2, 'source': 'local'},
        {'id': 3, 'source': 'local'},
      ]);
    });

    test('decodes text chunks split in the middle of records', () async {
      final chunks = Stream<String>.fromIterable([
        '{"id":',
        '1,"title":"A"}\n{"id":2,',
        '"title":"B"}',
      ]);
      final records = await chunks.decodeJsonl().toList();
      expect(records, [
        {'id': 1, 'title': 'A'},
        {'id': 2, 'title': 'B'},
      ]);
    });

    test('maps streamed records to models without re-encoding JSON', () async {
      final chunks = Stream<String>.value('{"id":5,"title":"Stream"}\n');
      final posts = await chunks.decodeJsonl().map(Post.fromJsonl).toList();
      expect(posts.single.title, 'Stream');
    });

    test('encodes a stream of maps', () async {
      final output = await Stream<Map<String, dynamic>>.value({'id': 1})
          .encodeJsonl()
          .toList();
      expect(output.single, '{"id":1}\n');
    });

    test('encodes a stream of model objects', () async {
      final output = await Stream<Post>.value(
        const Post(id: 9, title: 'Stream model'),
      ).encodeJsonl().toList();
      expect(output.single, '{"id":9,"title":"Stream model"}\n');
    });

    test('decodes UTF-8 byte streams', () async {
      final bytes = utf8.encode('{"title":"olá"}\n');
      final records =
          await Stream<List<int>>.value(bytes).decodeUtf8Jsonl().toList();
      expect(records.single['title'], 'olá');
    });

    test('handles a UTF-8 character split across byte chunks', () async {
      final bytes = utf8.encode('{"title":"olá"}\n');
      final firstByteOfAccent = bytes.indexOf(0xC3);
      final chunks = Stream<List<int>>.fromIterable([
        bytes.sublist(0, firstByteOfAccent + 1),
        bytes.sublist(firstByteOfAccent + 1),
      ]);

      final records = await chunks.decodeUtf8Jsonl().toList();
      expect(records.single['title'], 'olá');
    });

    test('handles CRLF and a final record without a trailing newline',
        () async {
      final records = await Stream<String>.value(
        '{"id":1}\r\n{"id":2}',
      ).decodeJsonl().toList();

      expect(records, [
        {'id': 1},
        {'id': 2},
      ]);
    });
  });
}

Stream<String> _delayedJsonlChunks() async* {
  yield '{"id":1,"source":"local"}\n';
  await Future<void>.delayed(const Duration(milliseconds: 10));
  yield '{"id":2,"source":"local"}\n';
  await Future<void>.delayed(const Duration(milliseconds: 10));
  yield '{"id":3,"source":"local"}\n';
}
