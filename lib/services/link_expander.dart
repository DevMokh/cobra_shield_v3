import 'dart:async';
import 'dart:io';

class ExpandResult {
  const ExpandResult({required this.chain, this.statusCode, this.error});

  final List<String> chain; // الرابط الأصلي ثم كل تحويلة
  final int? statusCode;
  final String? error;

  String get finalUrl => chain.last;
  bool get redirected => chain.length > 1;
}

class _Probe {
  const _Probe(this.status, this.location);
  final int status;
  final String? location;
}

/// يتتبع تحويلات الرابط (HEAD فقط، بدون تحميل أي محتوى) ليكشف الوجهة الحقيقية.
/// تنبيه: ده بيتصل فعليًا بالسيرفر، فالتطبيق يطلب موافقة المستخدم قبله.
class LinkExpander {
  LinkExpander._();

  static const int maxHops = 8;
  static const Duration _timeout = Duration(seconds: 8);

  static Future<_Probe> _probe(HttpClient client, Uri uri, String method) async {
    final req = await client.openUrl(method, uri).timeout(_timeout);
    req.followRedirects = false;
    req.headers.set(HttpHeaders.acceptHeader, '*/*');
    final res = await req.close().timeout(_timeout);
    final loc = res.headers.value(HttpHeaders.locationHeader);
    final status = res.statusCode;
    // لا نحمّل أي محتوى: نقطع الاتصال فورًا
    final sub = res.listen((_) {});
    await sub.cancel();
    return _Probe(status, loc);
  }

  static Future<ExpandResult> expand(String url) async {
    final chain = <String>[url];
    final client = HttpClient()
      ..connectionTimeout = _timeout
      ..userAgent = 'Mozilla/5.0 (Linux; Android 14) CobraShield/1.0';
    int? status;
    try {
      var current = Uri.parse(url);
      for (var hop = 0; hop < maxHops; hop++) {
        if (current.scheme != 'http' && current.scheme != 'https') {
          return ExpandResult(
            chain: chain,
            statusCode: status,
            error: 'الوجهة ليست رابط ويب عادي (${current.scheme}).',
          );
        }
        var p = await _probe(client, current, 'HEAD');
        if (p.status == 405 ||
            p.status == 501 ||
            p.status == 400 ||
            p.status == 403) {
          // بعض السيرفرات ترفض HEAD
          p = await _probe(client, current, 'GET');
        }
        status = p.status;
        final loc = p.location;
        if (p.status >= 300 && p.status < 400 && loc != null && loc.isNotEmpty) {
          current = current.resolve(loc);
          chain.add(current.toString());
          continue;
        }
        return ExpandResult(chain: chain, statusCode: status);
      }
      return ExpandResult(
        chain: chain,
        statusCode: status,
        error: 'عدد التحويلات كبير (أكثر من $maxHops) وهذا مريب.',
      );
    } on TimeoutException {
      return ExpandResult(
        chain: chain,
        statusCode: status,
        error: 'انتهت المهلة: السيرفر لم يرد.',
      );
    } on HandshakeException {
      return ExpandResult(
        chain: chain,
        statusCode: status,
        error: 'شهادة الأمان (SSL) غير صالحة لهذا الموقع.',
      );
    } on SocketException {
      return ExpandResult(
        chain: chain,
        statusCode: status,
        error: 'تعذر الاتصال: الموقع غير موجود أو لا يوجد إنترنت.',
      );
    } catch (_) {
      return ExpandResult(
        chain: chain,
        statusCode: status,
        error: 'تعذر فحص الرابط (رد غير متوقع).',
      );
    } finally {
      client.close(force: true);
    }
  }
}
