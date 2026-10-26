import 'dart:math' as math;

import '../core/knowledge.dart';
import '../core/models.dart';
import 'text_utils.dart';
import 'url_analyzer.dart';

class _Pattern {
  _Pattern(this.word, this.regex);
  final String word;
  final RegExp regex;
}

class _CompiledSignal {
  _CompiledSignal(this.def)
      : patterns = def.words
            .map((w) => _Pattern(w, buildKeywordRegex(w)))
            .toList();

  final SignalDef def;
  final List<_Pattern> patterns;
}

/// محلل الرسائل: يجمع إشارات نصية (استعجال، تهديد، طلب كود ...) ويفحص كل
/// رابط داخل الرسالة بمحلل الروابط. كله محلي ولا يُرسل أي نص خارج الجهاز.
class MessageAnalyzer {
  MessageAnalyzer._();

  static const int maxChars = 5000;
  static const int maxLinks = 8;

  static final List<_CompiledSignal> _signals =
      kSignals.map((s) => _CompiledSignal(s)).toList();
  static final List<RegExp> _safeHints =
      kSafeHints.map(buildKeywordRegex).toList();

  static final RegExp _hidden =
      RegExp(r'[\u200B-\u200F\u202A-\u202E\u2060\uFEFF]');

  static final RegExp _urlRe = RegExp(
    r'(?:(?:https?://|www\.)[^\s<>"]+)'
    r'|(?<![@\w.\-/])(?:[a-z0-9](?:[a-z0-9\-]{0,61}[a-z0-9])?\.)+'
    r'(?:com|net|org|info|xyz|top|click|link|co|me|eg|ly|gl|is|cc|app|site|online|live|shop|icu|vip|club|work|support|cfd|sbs|buzz|tk|ml|ga|cf|gq|ws|to|gd)'
    r'(?:/[^\s<>"]*)?(?![\w@])',
    caseSensitive: false,
  );
  static final RegExp _trail = RegExp(r'[\.\,\;\:\!\?\)\]\}»،؛؟"]+$');

  static List<String> extractLinks(String text) {
    final seen = <String>{};
    final out = <String>[];
    for (final m in _urlRe.allMatches(text)) {
      var s = m.group(0) ?? '';
      s = s.replaceAll(_trail, '');
      if (s.isEmpty) continue;
      final key = s.toLowerCase();
      if (seen.add(key)) out.add(s);
      if (out.length >= maxLinks) break;
    }
    return out;
  }

  static ScanResult analyze(String input) {
    var text = input.trim();
    if (text.length > maxChars) text = text.substring(0, maxChars);

    final findings = <Finding>[];
    final norm = normalizeText(text);
    final hit = <String>{};

    // الروابط
    final links = extractLinks(text).map((l) {
      final r = UrlAnalyzer.analyze(l);
      return ScanResult(
        kind: ScanKind.url,
        score: r.score,
        findings: r.findings,
        parts: r.parts,
        title: l,
      );
    }).toList();

    // حروف خفية في نص الرسالة
    if (_hidden.hasMatch(text)) {
      findings.add(const Finding(
        severity: Severity.warn,
        title: 'حروف خفية داخل النص',
        detail: 'تُستخدم لتخطي فلاتر الرسائل المزعجة وتقطيع الكلمات المشبوهة.',
        points: 8,
      ));
    }

    // الإشارات النصية
    for (final s in _signals) {
      final matched = <String>[];
      for (final p in s.patterns) {
        if (p.regex.hasMatch(norm)) matched.add(p.word);
      }
      if (matched.isEmpty) continue;
      hit.add(s.def.id);
      final pts = s.def.weight + math.min(matched.length - 1, 2) * 2;
      final sev = pts >= 20
          ? Severity.danger
          : (pts >= 8 ? Severity.warn : Severity.info);
      findings.add(Finding(
        severity: sev,
        title: s.def.title,
        detail: '${s.def.detail}\nوُجد: ${matched.take(3).join('، ')}',
        points: pts,
      ));
    }

    // الروابط
    if (links.isNotEmpty) {
      final worst = links.map((r) => r.score).reduce(math.max);
      final linkPts = (worst * 0.7).round();
      if (linkPts > 0) {
        findings.add(Finding(
          severity: linkPts >= 25 ? Severity.danger : Severity.warn,
          title: 'رابط مشبوه داخل الرسالة',
          detail: 'أخطر رابط حصل على $worst/100. راجع تفاصيل الروابط بالأسفل.',
          points: linkPts,
        ));
      } else {
        findings.add(Finding(
          severity: Severity.info,
          title: 'الرسالة تحتوي ${links.length} رابط',
          detail: 'لم نجد علامات واضحة في الروابط، لكن لا تفتحها إلا لو كنت تتوقعها.',
        ));
      }
      if (hit.contains('urgency') ||
          hit.contains('threat') ||
          hit.contains('secret') ||
          hit.contains('prize')) {
        findings.add(const Finding(
          severity: Severity.danger,
          title: 'رابط مع ضغط نفسي',
          detail: 'اجتماع الرابط مع استعجال أو تهديد أو جائزة هو النمط الكلاسيكي للتصيّد.',
          points: 10,
        ));
      }
    }

    // تخفيف: رسالة كود تحقق رسمية فيها تحذير "لا تشارك" وبدون روابط
    if (hit.contains('secret') && links.isEmpty) {
      final safe = _safeHints.any((r) => r.hasMatch(norm));
      if (safe) {
        findings.add(const Finding(
          severity: Severity.good,
          title: 'تحذير من مشاركة الكود',
          detail: 'الرسائل الرسمية الحقيقية تنبّهك ألا تشارك الكود. هذه علامة مطمئنة نسبيًا.',
          points: -15,
        ));
      }
    }

    // علامات تعجب كثيرة
    final bangs = '!'.allMatches(text).length + '！'.allMatches(text).length;
    if (bangs >= 3) {
      findings.add(const Finding(
        severity: Severity.info,
        title: 'علامات تعجب كثيرة',
        detail: 'المبالغة في الترقيم أسلوب لافتعال الإثارة.',
        points: 4,
      ));
    }

    if (findings.isEmpty) {
      findings.add(const Finding(
        severity: Severity.good,
        title: 'لا مؤشرات نصية واضحة',
        detail: 'لم نجد عبارات احتيال شائعة. ابقَ حذرًا من أي طلب مفاجئ للمال أو البيانات.',
      ));
    }

    var total = 0;
    for (final f in findings) {
      total += f.points;
    }
    if (total < 0) total = 0;
    if (total > 100) total = 100;
    findings.sort((a, b) => b.points.compareTo(a.points));

    return ScanResult(
      kind: ScanKind.message,
      score: total,
      findings: findings,
      links: links,
      title: 'رسالة',
    );
  }
}
