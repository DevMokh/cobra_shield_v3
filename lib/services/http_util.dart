import 'dart:async';
import 'dart:convert';
import 'dart:io';

class HttpResult {
  const HttpResult(this.status, this.body);

  final int status;
  final String body;
}

/// طلب HTTP بسيط بمهلة وحد أقصى لحجم الرد (بدون أي حزمة خارجية).
Future<HttpResult> httpRequest(
  String method,
  Uri uri, {
  Map<String, String>? headers,
  String? body,
  Duration timeout = const Duration(seconds: 10),
  int maxBytes = 2 * 1024 * 1024,
  bool follow = true,
}) async {
  final client = HttpClient()
    ..connectionTimeout = timeout
    ..userAgent = 'CobraShield/1.2';
  try {
    final req = await client.openUrl(method, uri).timeout(timeout);
    req.followRedirects = follow;
    req.maxRedirects = 5;
    if (headers != null) {
      for (final e in headers.entries) {
        req.headers.set(e.key, e.value);
      }
    }
    if (body != null) {
      final bytes = utf8.encode(body);
      req.headers.contentLength = bytes.length;
      req.add(bytes);
    }
    final res = await req.close().timeout(timeout);
    final chunks = <int>[];
    await for (final c in res.timeout(timeout)) {
      chunks.addAll(c);
      if (chunks.length > maxBytes) break;
    }
    return HttpResult(res.statusCode, utf8.decode(chunks, allowMalformed: true));
  } finally {
    client.close(force: true);
  }
}
