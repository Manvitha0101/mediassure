import 'dart:convert';
import 'dart:io';

class DebugLogger {
  static const String _sessionId = 'fb0cde';
  static const String _logPath = 'debug-fb0cde.log';
  static const String _endpoint =
      'http://127.0.0.1:7804/ingest/7a73ee13-3295-4d5d-b413-eb3116f8ac7f';

  static void log({
    required String hypothesisId,
    required String location,
    required String message,
    Map<String, dynamic>? data,
    String runId = 'nav-check',
  }) {
    // Avoid ever logging secrets/PII beyond coarse identifiers.
    final payload = <String, dynamic>{
      'sessionId': _sessionId,
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data ?? const <String, dynamic>{},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Fire-and-forget: send to host-side log collector (works with `adb reverse`).
    try {
      final client = HttpClient();
      client.postUrl(Uri.parse(_endpoint)).then((req) {
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        req.headers.set('X-Debug-Session-Id', _sessionId);
        req.write(jsonEncode(payload));
        return req.close();
      }).then((res) {
        res.drain();
      }).catchError((_) {
        // Ignore collector failures (e.g., no adb reverse / endpoint down).
      }).whenComplete(() => client.close());
    } catch (_) {
      // Ignore collector failures.
    }

    try {
      final file = File(_logPath);
      file.writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {
      // Swallow logging failures to avoid impacting runtime behavior.
    }
  }
}

