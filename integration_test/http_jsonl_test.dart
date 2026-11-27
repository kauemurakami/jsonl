import 'dart:io';

import 'package:jsonl/jsonl.dart';
import 'package:test/test.dart';

void main() {
  final runNetworkTests =
      Platform.environment['JSONL_RUN_NETWORK_TESTS'] == 'true';

  group('live HTTP JSONL integration', () {
    test(
      'reads three NDJSON lines from HTTPBin',
      () async {
        final client = HttpClient();
        try {
          final request = await client.getUrl(
            Uri.parse('https://httpbin.org/stream/3'),
          );
          final response = await request.close();
          expect(response.statusCode, 200);

          final records = await response.decodeUtf8Jsonl().toList();
          expect(records, hasLength(3));
          expect(records.map((record) => record['id']).toList(), [0, 1, 2]);
        } finally {
          client.close(force: true);
        }
      },
      skip: !runNetworkTests,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'reads timed JSONL records from HTTPBingo',
      () async {
        final client = HttpClient();
        try {
          final request = await client.getUrl(
            Uri.parse('https://httpbingo.org/jsonl?count=3&duration=2s'),
          );
          final response = await request.close();
          expect(response.statusCode, 200);

          final records = await response.decodeUtf8Jsonl().toList();
          expect(records, hasLength(3));
        } finally {
          client.close(force: true);
        }
      },
      skip: !runNetworkTests,
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
