// نماذج البيانات المشتركة بين الخدمات والشاشات (Dart صرف بدون Flutter)

enum RiskLevel { low, medium, high, critical }

RiskLevel levelForScore(int score) {
  if (score >= 70) return RiskLevel.critical;
  if (score >= 45) return RiskLevel.high;
  if (score >= 20) return RiskLevel.medium;
  return RiskLevel.low;
}

extension RiskLevelText on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'لا مؤشرات واضحة';
      case RiskLevel.medium:
        return 'مشبوه';
      case RiskLevel.high:
        return 'خطير';
      case RiskLevel.critical:
        return 'احتيال مرجّح';
    }
  }

  String get advice {
    switch (this) {
      case RiskLevel.low:
        return 'لم نجد علامات خطر واضحة، لكن هذا لا يعني أنه آمن 100%. افتحه فقط لو كنت تتوقعه من مصدر موثوق.';
      case RiskLevel.medium:
        return 'فيه علامات تستدعي الحذر. لا تُدخل أي بيانات أو أكواد، وتأكد من المصدر أولًا.';
      case RiskLevel.high:
        return 'علامات قوية على التصيّد. الأفضل ألا تفتحه، ولا تدخل أي بيانات.';
      case RiskLevel.critical:
        return 'يشبه الاحتيال بدرجة كبيرة. لا تفتحه، لا ترد، واحذف الرسالة أو أبلغ عنها.';
    }
  }
}

enum Severity { good, info, warn, danger }

class Finding {
  const Finding({
    required this.severity,
    required this.title,
    required this.detail,
    this.points = 0,
  });

  final Severity severity;
  final String title;
  final String detail;
  final int points;
}

enum ScanKind { url, message }

class UrlParts {
  const UrlParts({
    required this.scheme,
    required this.host,
    required this.domain,
    required this.tld,
    required this.path,
    required this.query,
    required this.port,
    required this.normalizedUrl,
  });

  final String scheme;
  final String host;
  final String domain; // الدومين الأساسي (مثلاً example.com)
  final String tld;
  final String path;
  final String query;
  final String port;
  final String normalizedUrl;
}

class ScanResult {
  const ScanResult({
    required this.kind,
    required this.score,
    required this.findings,
    this.parts,
    this.links = const <ScanResult>[],
    this.title = '',
  });

  final ScanKind kind;
  final int score;
  final List<Finding> findings;
  final UrlParts? parts;
  final List<ScanResult> links; // روابط الرسالة (للرسائل فقط)
  final String title;

  RiskLevel get level => levelForScore(score);

  String toReport() {
    final b = StringBuffer();
    b.writeln('تقرير Cobra Shield');
    b.writeln('درجة الخطر: $score/100 - ${level.label}');
    if (parts != null) {
      b.writeln('الدومين: ${parts!.domain}');
    }
    b.writeln('');
    for (final f in findings) {
      var tag = '';
      if (f.points > 0) tag = ' (+${f.points})';
      if (f.points < 0) tag = ' (${f.points})';
      b.writeln('- ${f.title}$tag');
      b.writeln('  ${f.detail}');
    }
    if (links.isNotEmpty) {
      b.writeln('');
      b.writeln('الروابط داخل الرسالة:');
      for (final l in links) {
        b.writeln('* ${l.title} -> ${l.score}/100 (${l.level.label})');
      }
    }
    b.writeln('');
    b.writeln('ملاحظة: التحليل تقديري ولا يغني عن الحذر.');
    return b.toString();
  }
}

class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.score,
    required this.time,
  });

  final int id;
  final ScanKind kind;
  final String title;
  final int score;
  final DateTime time;

  RiskLevel get level => levelForScore(score);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'k': kind == ScanKind.message ? 1 : 0,
        't': title,
        's': score,
        'ms': time.millisecondsSinceEpoch,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
        id: j['id'] as int,
        kind: (j['k'] as int) == 1 ? ScanKind.message : ScanKind.url,
        title: j['t'] as String,
        score: j['s'] as int,
        time: DateTime.fromMillisecondsSinceEpoch(j['ms'] as int),
      );
}
