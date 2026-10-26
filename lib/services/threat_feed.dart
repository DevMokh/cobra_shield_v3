import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'http_util.dart';
import 'url_analyzer.dart';

class FeedMatch {
  const FeedMatch(this.kind, this.points);

  final String kind; // exact | host | domain
  final int points;
}

/// قاعدة روابط التصيّد (OpenPhish Community Feed) محفوظة محليًا.
/// بعد التحديث يتم الفحص بدون إنترنت ولا يُرسل أي رابط لأي جهة.
/// تنبيه: الخلاصة للاستخدام غير التجاري فقط حسب شروط OpenPhish.
class ThreatFeed extends ChangeNotifier {
  ThreatFeed._();

  static final ThreatFeed instance = ThreatFeed._();

  static const String feedUrl =
      'https://raw.githubusercontent.com/openphish/public_feed/main/feed.txt';

  final Set<String> _urls = <String>{};
  final Set<String> _hosts = <String>{};
  final Set<String> _domains = <String>{};
  DateTime? _updated;
  bool _busy = false;
  String? lastError;

  int get count => _urls.length;
  DateTime? get updated => _updated;
  bool get busy => _busy;

  File get _file => File('${Directory.systemTemp.path}/cobra_openphish.txt');

  Future<void> load() async {
    try {
      final f = _file;
      if (!await f.exists()) return;
      _ingest(await f.readAsString());
      _updated = await f.lastModified();
      notifyListeners();
    } catch (_) {
      // ملف تالف: نتجاهله وسيُعاد التحميل عند التحديث
    }
  }

  static String normalize(String url) {
    var s = url.trim().toLowerCase();
    s = s.replaceFirst(RegExp(r'^[a-z][a-z0-9+.\-]*://'), '');
    final hash = s.indexOf('#');
    if (hash >= 0) s = s.substring(0, hash);
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  static String _hostOf(String normalized) {
    final end = normalized.indexOf(RegExp(r'[/?]'));
    var host = end >= 0 ? normalized.substring(0, end) : normalized;
    final at = host.lastIndexOf('@');
    if (at >= 0) host = host.substring(at + 1);
    final colon = host.indexOf(':');
    if (colon >= 0) host = host.substring(0, colon);
    return host;
  }

  void _ingest(String text) {
    _urls.clear();
    _hosts.clear();
    _domains.clear();
    var n = 0;
    for (final line in text.split('\n')) {
      final l = line.trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      if (!l.toLowerCase().startsWith('http')) continue;
      final u = normalize(l);
      if (u.isEmpty) continue;
      _urls.add(u);
      final host = _hostOf(u);
      if (host.isNotEmpty) {
        _hosts.add(host);
        _domains.add(UrlAnalyzer.registrableDomain(host));
      }
      n++;
      if (n >= 100000) break;
    }
  }

  Future<bool> update() async {
    if (_busy) return false;
    _busy = true;
    lastError = null;
    notifyListeners();
    try {
      final r = await httpRequest(
        'GET',
        Uri.parse(feedUrl),
        timeout: const Duration(seconds: 30),
        maxBytes: 12 * 1024 * 1024,
      );
      if (r.status != 200) {
        lastError = 'رد غير متوقع من السيرفر (${r.status})';
        return false;
      }
      _ingest(r.body);
      if (_urls.isEmpty) {
        lastError = 'الملف فارغ أو بصيغة غير معروفة';
        return false;
      }
      try {
        await _file.writeAsString(r.body);
      } catch (_) {
        // لو تعذر الحفظ نكمل بالنسخة التي في الذاكرة
      }
      _updated = DateTime.now();
      return true;
    } on TimeoutException {
      lastError = 'انتهت المهلة';
      return false;
    } on SocketException {
      lastError = 'لا يوجد اتصال بالإنترنت';
      return false;
    } catch (_) {
      lastError = 'تعذر التحديث';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// يفحص رابطًا: تطابق كامل ← مضيف ← دومين أساسي.
  FeedMatch? match(String url) {
    if (_urls.isEmpty) return null;
    final n = normalize(url);
    if (_urls.contains(n)) return const FeedMatch('exact', 90);
    final host = _hostOf(n);
    if (host.isEmpty || UrlAnalyzer.isSharedHost(host)) return null;
    if (_hosts.contains(host)) return const FeedMatch('host', 70);
    final d = UrlAnalyzer.registrableDomain(host);
    if (_domains.contains(d)) return const FeedMatch('domain', 45);
    return null;
  }
}
