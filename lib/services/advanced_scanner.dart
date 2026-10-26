import '../core/knowledge.dart';
import '../core/models.dart';
import 'link_expander.dart';
import 'online_intel.dart';
import 'settings_store.dart';
import 'url_analyzer.dart';

class AdvancedReport {
  const AdvancedReport({
    required this.expand,
    required this.finalLocal,
    required this.intel,
    required this.combinedScore,
  });

  final ExpandResult expand;
  final ScanResult? finalLocal; // تحليل الوجهة النهائية لو اختلفت عن الأصل
  final List<IntelResult> intel;
  final int combinedScore;

  /// نتيجة موحدة: درجة مجمّعة + كل المؤشرات بدون تكرار
  ScanResult toResult(ScanResult local) {
    final seen = <String>{};
    final all = <Finding>[];
    void add(Iterable<Finding> list) {
      for (final f in list) {
        if (seen.add(f.title)) all.add(f);
      }
    }

    for (final r in intel) {
      add(r.findings);
    }
    add(finalLocal?.findings ?? const <Finding>[]);
    add(local.findings);
    all.sort((a, b) => b.points.compareTo(a.points));
    return ScanResult(
      kind: ScanKind.url,
      score: combinedScore,
      findings: all,
      parts: finalLocal?.parts ?? local.parts,
      title: local.title,
    );
  }
}

/// الفحص المتقدم: تتبع التحويلات ثم استعلام مصادر التهديدات عن الوجهة النهائية.
class AdvancedScanner {
  AdvancedScanner._();

  static final RegExp _ipLike = RegExp(r'^[\d.]+$');

  static Future<AdvancedReport> run(
    ScanResult local, {
    void Function(String step)? onStep,
  }) async {
    final parts = local.parts;
    if (parts == null) {
      throw StateError('no parts');
    }

    onStep?.call('تتبع التحويلات...');
    final expand = await LinkExpander.expand(parts.normalizedUrl);

    ScanResult? fin;
    var targetUrl = parts.normalizedUrl;
    var target = parts;
    if (expand.error == null && expand.redirected) {
      fin = UrlAnalyzer.analyze(expand.finalUrl);
      targetUrl = expand.finalUrl;
      target = fin.parts ?? parts;
    }

    onStep?.call('الاستعلام من مصادر التهديدات...');
    final s = SettingsStore.instance;
    final host = target.host;
    final isIp = _ipLike.hasMatch(host) || host.contains(':');
    final skipAge = isIp || kShorteners.contains(host);

    final results = <Future<IntelResult>>[
      Future<IntelResult>.value(OnlineIntel.feed(targetUrl)),
      if (!skipAge)
        OnlineIntel.rdap(target.domain)
      else
        Future<IntelResult>.value(const IntelResult(
          source: 'عمر الدومين (RDAP)',
          status: IntelStatus.skipped,
          message: 'لا ينطبق على عنوان IP أو رابط مختصر.',
        )),
      OnlineIntel.safeBrowsing(targetUrl, s.gsbKey),
      OnlineIntel.virusTotal(targetUrl, s.vtKey),
    ];
    final intel = await Future.wait<IntelResult>(results);

    var add = 0;
    for (final r in intel) {
      for (final f in r.findings) {
        add += f.points;
      }
    }
    final base = fin != null && fin.score > local.score ? fin.score : local.score;
    var combined = base + add;
    if (combined < 0) combined = 0;
    if (combined > 100) combined = 100;

    return AdvancedReport(
      expand: expand,
      finalLocal: fin,
      intel: intel,
      combinedScore: combined,
    );
  }
}
