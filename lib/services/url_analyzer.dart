import 'dart:math' as math;

import '../core/knowledge.dart';
import '../core/models.dart';

/// محلل الروابط: كله يعمل على الجهاز بدون اتصال بالإنترنت.
/// كل فحص بيضيف "نقاط خطر"، والمجموع (0-100) يحدد المستوى.
class UrlAnalyzer {
  UrlAnalyzer._();

  static final RegExp _hasScheme =
      RegExp(r'^[a-z][a-z0-9+.\-]*://', caseSensitive: false);
  static final RegExp _dangerScheme = RegExp(
      r'^(javascript|data|vbscript|file|intent|blob):',
      caseSensitive: false);
  static final RegExp _ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');
  static final RegExp _numericIp = RegExp(r'^(\d{8,10}|0x[0-9a-f]+)$');
  static final RegExp _hidden =
      RegExp(r'[\u200B-\u200F\u202A-\u202E\u2060\uFEFF]');
  static final RegExp _embedded = RegExp(r'https?://', caseSensitive: false);
  static final RegExp _redirectValue =
      RegExp(r'^(https?:)?//', caseSensitive: false);

  /// الدومين الأساسي بدون قائمة اللاحقات العامة الكاملة (تقريبي لكنه كافٍ هنا)
  static String registrableDomain(String host) {
    final parts = host.split('.');
    if (parts.length <= 2) return host;
    final last = parts[parts.length - 1];
    final second = parts[parts.length - 2];
    if (last.length == 2 && kSecondLevel.contains(second)) {
      return parts.sublist(parts.length - 3).join('.');
    }
    return parts.sublist(parts.length - 2).join('.');
  }

  /// المضيف كما كُتب في النص الخام (قبل أي تحويل) لفحص الحروف غير اللاتينية
  /// في الدومين فقط وليس في المسار (مثل ويكيبيديا بالعربي).
  static String _rawHost(String raw) {
    var s = raw.replaceFirst(_hasScheme, '');
    final end = s.indexOf(RegExp(r'[/?#]'));
    if (end >= 0) s = s.substring(0, end);
    final at = s.lastIndexOf('@');
    if (at >= 0) s = s.substring(at + 1);
    return s;
  }

  static Brand? _officialOf(String host) {
    for (final b in kBrands) {
      for (final d in b.domains) {
        if (host == d || host.endsWith('.$d')) return b;
      }
    }
    return null;
  }

  /// نطاق إقليمي لعلامة كبيرة (google.de / amazon.co.uk): label.cctld
  static Brand? _regionalOf(String domain, String tld) {
    if (tld.length != 2 || kRiskyTlds.contains(tld) || kAbusedCc.contains(tld)) {
      return null;
    }
    final label = domain.split('.').first;
    for (final b in kBrands) {
      if (b.regional && b.keys.contains(label)) return b;
    }
    return null;
  }

  /// مضيف مشترك (مختصِر روابط / استضافة مجانية / دومين علامة رسمية):
  /// لا نحكم عليه كله بسبب رابط واحد مدرج في قائمة تهديدات.
  static bool isSharedHost(String host) {
    if (kShorteners.contains(host)) return true;
    for (final d in kFreeHosts) {
      if (host == d || host.endsWith('.$d')) return true;
    }
    return _officialOf(host) != null;
  }

  static int _lev(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0);
      cur[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        cur[j] = math.min(
          math.min(cur[j - 1] + 1, prev[j] + 1),
          prev[j - 1] + cost,
        );
      }
      prev = cur;
    }
    return prev[b.length];
  }

  /// يحوّل الأرقام والحروف المتشابهة لحروفها (paypa1 -> paypal)
  static List<String> _deob(String t) {
    String conv(String s, String one) => s
        .replaceAll('rn', 'm')
        .replaceAll('vv', 'w')
        .replaceAll('0', 'o')
        .replaceAll('1', one)
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('7', 't')
        .replaceAll('\$', 's');
    return <String>[conv(t, 'l'), conv(t, 'i')];
  }

  static ScanResult _finish(List<Finding> f, UrlParts? parts, String title) {
    var total = 0;
    for (final x in f) {
      total += x.points;
    }
    if (total < 0) total = 0;
    if (total > 100) total = 100;
    f.sort((a, b) => b.points.compareTo(a.points));
    return ScanResult(
      kind: ScanKind.url,
      score: total,
      findings: f,
      parts: parts,
      title: title,
    );
  }

  static ScanResult analyze(String input) {
    final raw = input.trim();
    final f = <Finding>[];

    if (raw.isEmpty) {
      return const ScanResult(kind: ScanKind.url, score: 0, findings: <Finding>[]);
    }

    // 1) أنواع روابط خطيرة
    if (_dangerScheme.hasMatch(raw)) {
      f.add(const Finding(
        severity: Severity.danger,
        title: 'نوع رابط خطير',
        detail:
            'ده مش عنوان موقع عادي (javascript / data / file ...). ممكن ينفّذ كودًا أو يفتح ملفًا محليًا.',
        points: 70,
      ));
      return _finish(f, null, raw);
    }

    final hadScheme = _hasScheme.hasMatch(raw);
    final candidate = hadScheme ? raw : 'https://$raw';
    final rawHost = _rawHost(raw);
    final hasNonAscii = rawHost.runes.any((r) => r > 127);

    if (_hidden.hasMatch(raw)) {
      f.add(const Finding(
        severity: Severity.danger,
        title: 'حروف خفية داخل الرابط',
        detail: 'وجود حروف غير مرئية أسلوب لتمويه الرابط الحقيقي.',
        points: 20,
      ));
    }

    final u = Uri.tryParse(candidate);
    if (u == null || u.host.isEmpty) {
      f.add(const Finding(
        severity: Severity.warn,
        title: 'شكل الرابط غير صالح',
        detail: 'الرابط فيه مسافات أو رموز غير مسموحة أو بدون دومين واضح.',
        points: 25,
      ));
      if (hasNonAscii) {
        f.add(const Finding(
          severity: Severity.danger,
          title: 'حروف غير لاتينية',
          detail: 'قد تكون حروفًا مشابهة للاتينية (Homograph) لتقليد دومين معروف.',
          points: 25,
        ));
      }
      return _finish(f, null, raw);
    }

    final scheme = u.scheme.toLowerCase();
    final host = u.host.toLowerCase().replaceAll(RegExp(r'\.$'), '');
    final labels = host.split('.');
    final tld = labels.last;
    final isIpv4 = _ipv4.hasMatch(host);
    final isIpv6 = host.contains(':');
    final isNumericIp = _numericIp.hasMatch(host);
    final isIp = isIpv4 || isIpv6 || isNumericIp;
    final domain = isIp ? host : registrableDomain(host);

    final Brand? exact = isIp ? null : _officialOf(host);
    final Brand? regionalBrand =
        (isIp || exact != null) ? null : _regionalOf(domain, tld);
    final Brand? official = exact ?? regionalBrand;
    final bool isRegional = regionalBrand != null;
    var freeHost = false;
    for (final d in kFreeHosts) {
      if (host == d || host.endsWith('.$d')) {
        freeHost = true;
        break;
      }
    }

    // 2) البروتوكول
    if (scheme == 'http') {
      f.add(const Finding(
        severity: Severity.warn,
        title: 'بدون تشفير (HTTP)',
        detail: 'البيانات المرسلة لهذا الموقع تُنقل بدون حماية. المواقع الجادة تستخدم HTTPS.',
        points: 10,
      ));
    } else if (scheme != 'https') {
      f.add(Finding(
        severity: Severity.warn,
        title: 'بروتوكول غير معتاد ($scheme)',
        detail: 'الروابط العادية تبدأ بـ http أو https.',
        points: 15,
      ));
    }

    // 3) عنوان IP بدل اسم دومين
    if (isNumericIp) {
      f.add(const Finding(
        severity: Severity.danger,
        title: 'عنوان IP مموّه',
        detail: 'العنوان مكتوب كرقم طويل أو هيكساديسيمال لإخفاء أنه IP.',
        points: 35,
      ));
    } else if (isIp) {
      f.add(const Finding(
        severity: Severity.danger,
        title: 'الرابط يستخدم عنوان IP',
        detail: 'المواقع الحقيقية نادرًا ما تطلب بياناتك عبر عنوان IP مباشر.',
        points: 30,
      ));
    }

    // 4) بيانات مستخدم قبل @
    if (u.userInfo.isNotEmpty) {
      f.add(const Finding(
        severity: Severity.danger,
        title: 'يحتوي على @ قبل الدومين',
        detail:
            'كل ما قبل علامة @ يتجاهله المتصفح، والمحتال يضع هناك اسمًا مألوفًا ليخدعك.',
        points: 35,
      ));
    }

    // 5) حروف دولية / punycode
    final hasPuny = labels.any((l) => l.startsWith('xn--'));
    if (hasPuny || hasNonAscii || host.contains('%')) {
      f.add(const Finding(
        severity: Severity.danger,
        title: 'دومين بحروف غير لاتينية',
        detail:
            'قد يكون تقليدًا لدومين معروف بحروف متشابهة الشكل (مثل a الروسية بدل a اللاتينية).',
        points: 25,
      ));
    }

    // 5-ب) حروف سيريلية أو يونانية (تقليد شائع لحروف لاتينية)
    if (RegExp(r'[\u0400-\u04FF\u0370-\u03FF]').hasMatch(rawHost)) {
      f.add(const Finding(
        severity: Severity.danger,
        title: 'حروف سيريلية/يونانية في الدومين',
        detail:
            'هذه الحروف تشبه اللاتينية (a, o, e, p ...) وتُستخدم لتقليد دومينات معروفة.',
        points: 15,
      ));
    }

    // 6) منطق الدومين (لا ينطبق على IP)
    if (!isIp) {
      if (kShorteners.contains(host) || kShorteners.contains(domain)) {
        f.add(const Finding(
          severity: Severity.warn,
          title: 'رابط مختصر',
          detail:
              'الرابط المختصر يخفي الوجهة الحقيقية. استخدم زر "فحص الوجهة الفعلية" لمعرفة أين يذهب.',
          points: 20,
        ));
      }

      if (freeHost) {
        f.add(const Finding(
          severity: Severity.warn,
          title: 'منصة استضافة مجانية',
          detail:
              'المحتالون يرفعون صفحات مزيفة على منصات مجانية. الدومين نفسه موثوق لكن المحتوى قد لا يكون.',
          points: 15,
        ));
      }

      if (official == null) {
        // انتحال اسم علامة معروفة
        final tokens = host
            .split(RegExp(r'[.\-_]'))
            .where((t) => t.length >= 3)
            .toList();
        final hayHost = '$host ${u.path} ${u.query}'.toLowerCase();
        final sensitive = kUrlWords.any((w) => hayHost.contains(w)) ||
            kRiskyTlds.contains(tld);
        Brand? hit;
        outer:
        for (final b in kBrands) {
          for (final key in b.keys) {
            for (final t in tokens) {
              if (t == key || (key.length >= 5 && t.startsWith(key))) {
                // أسماء مثل apple/orange كلمات عادية: لا نحكم إلا مع علامات أخرى
                if (b.ambiguous && !sensitive) continue;
                hit = b;
                break outer;
              }
            }
          }
        }
        if (hit != null) {
          f.add(Finding(
            severity: Severity.danger,
            title: 'ينتحل اسم ${hit.name}',
            detail:
                'الاسم موجود في الرابط لكن الدومين الحقيقي هنا هو "$domain"، وهو ليس ضمن الدومينات الرسمية المعروفة لـ ${hit.name} (مثل ${hit.domains.first}).',
            points: 40,
          ));
        } else {
          // تقليد بحروف/أرقام متشابهة
          var found = false;
          for (final t in tokens) {
            if (t.length < 4 || found) continue;
            final variants = _deob(t);
            for (final b in kBrands) {
              for (final key in b.keys) {
                if (key.length < 5 || found) continue;
                if (t != key && variants.contains(key)) {
                  f.add(Finding(
                    severity: Severity.danger,
                    title: 'تقليد لاسم ${b.name}',
                    detail:
                        '"$t" يشبه "$key" باستبدال أرقام/حروف متشابهة (مثل 1 بدل l).',
                    points: 40,
                  ));
                  found = true;
                  break;
                }
                if (!b.ambiguous &&
                    (t.length - key.length).abs() <= 1 &&
                    _lev(t, key) == 1) {
                  f.add(Finding(
                    severity: Severity.danger,
                    title: 'خطأ إملائي مقصود في ${b.name}؟',
                    detail: '"$t" قريب جدًا من "$key" بحرف واحد مختلف.',
                    points: 30,
                  ));
                  found = true;
                  break;
                }
              }
            }
          }
        }

        if (kRiskyTlds.contains(tld)) {
          f.add(Finding(
            severity: Severity.warn,
            title: 'امتداد دومين شائع في الاحتيال (.$tld)',
            detail: 'هذه الامتدادات رخيصة أو مجانية وتُستخدم كثيرًا في الحملات الاحتيالية.',
            points: 12,
          ));
        }

        final extra = labels.length - domain.split('.').length;
        if (extra >= 3) {
          f.add(Finding(
            severity: Severity.warn,
            title: 'مستويات فرعية كثيرة ($extra)',
            detail: 'كثرة النقاط في الدومين تُستخدم لدفن الاسم الحقيقي في آخر الرابط.',
            points: 15,
          ));
        } else if (extra == 2) {
          f.add(const Finding(
            severity: Severity.info,
            title: 'دومين فرعي متعدد',
            detail: 'اقرأ الدومين من اليمين: الجزء الأخير قبل أول "/" هو الأهم.',
            points: 8,
          ));
        }

        if ('-'.allMatches(host.replaceAll('xn--', '')).length >= 3) {
          f.add(const Finding(
            severity: Severity.warn,
            title: 'شرطات كثيرة في الدومين',
            detail: 'الدومينات الاحتيالية غالبًا تحشر كلمات مثل secure-login-update.',
            points: 10,
          ));
        }
        if (host.length > 35) {
          f.add(const Finding(
            severity: Severity.info,
            title: 'اسم دومين طويل جدًا',
            detail: 'الأسماء الطويلة تُستخدم لإخفاء الجزء المهم.',
            points: 6,
          ));
        }
      } else if (!freeHost) {
        if (isRegional) {
          f.add(Finding(
            severity: Severity.info,
            title: 'نطاق إقليمي محتمل لـ ${official.name}',
            detail:
                '"$domain" يبدو نطاقًا إقليميًا لـ ${official.name}. غالبًا سليم، لكن تأكد من الكتابة الصحيحة.',
          ));
        } else {
          f.add(Finding(
            severity: Severity.good,
            title: 'الدومين رسمي: ${official.name}',
            detail: '"$domain" ضمن الدومينات الرسمية المعروفة لـ ${official.name}.',
          ));
        }
      }
    }

    // 7) المنفذ
    if (u.hasPort && u.port != 80 && u.port != 443) {
      f.add(Finding(
        severity: Severity.warn,
        title: 'منفذ غير معتاد (${u.port})',
        detail: 'المواقع العادية لا تحتاج رقم منفذ ظاهرًا في الرابط.',
        points: 10,
      ));
    }

    // 8) كلمات حساسة في المسار والاستعلام
    if (official == null || freeHost) {
      final hay = '$host ${u.path} ${u.query}'.toLowerCase();
      final hits = kUrlWords.where((w) => hay.contains(w)).toList();
      if (hits.length >= 3) {
        f.add(Finding(
          severity: Severity.warn,
          title: 'كلمات حساسة كثيرة',
          detail: 'وُجدت: ${hits.take(5).join(', ')}. صفحات الاحتيال تحشر هذه الكلمات لإقناعك.',
          points: 16,
        ));
      } else if (hits.isNotEmpty) {
        f.add(Finding(
          severity: Severity.info,
          title: 'كلمات حساسة في الرابط',
          detail: 'وُجدت: ${hits.join(', ')}.',
          points: 8,
        ));
      }
    }

    // 9) إعادة توجيه داخل الرابط
    var hasRedirectParam = false;
    try {
      for (final e in u.queryParameters.entries) {
        if (kRedirectParams.contains(e.key.toLowerCase()) &&
            _redirectValue.hasMatch(e.value)) {
          hasRedirectParam = true;
          break;
        }
      }
    } catch (_) {
      // ترميز مكسور في الاستعلام: نتجاهله
    }
    if (hasRedirectParam || _embedded.allMatches(candidate).length >= 2) {
      f.add(const Finding(
        severity: Severity.warn,
        title: 'رابط داخل رابط',
        detail: 'الرابط يحمل عنوانًا آخر بداخله وقد يحوّلك لموقع مختلف تمامًا.',
        points: 15,
      ));
    }

    // 10) أطوال وترميز
    if (raw.length > 200) {
      f.add(const Finding(
        severity: Severity.info,
        title: 'رابط طويل جدًا',
        detail: 'الطول الزائد يُستخدم لإخفاء الجزء المهم من الرابط.',
        points: 10,
      ));
    } else if (raw.length > 100) {
      f.add(const Finding(
        severity: Severity.info,
        title: 'رابط طويل',
        detail: 'الروابط الطويلة تستحق نظرة أدق.',
        points: 5,
      ));
    }
    if ('%'.allMatches(raw).length >= 6) {
      f.add(const Finding(
        severity: Severity.info,
        title: 'ترميز كثيف (%)',
        detail: 'الترميز الكثيف يُستخدم لتمويه محتوى الرابط.',
        points: 8,
      ));
    }

    // 11) ملفات خطيرة
    final path = u.path.toLowerCase();
    var dangerous = false;
    for (final ext in kDangerExt) {
      if (path.endsWith(ext)) {
        dangerous = true;
        f.add(Finding(
          severity: Severity.danger,
          title: 'تحميل ملف تنفيذي ($ext)',
          detail:
              'ملفات $ext قد تثبّت برامج ضارة. لا تثبّت شيئًا إلا من المتجر الرسمي أو موقع الناشر.',
          points: 30,
        ));
        break;
      }
    }
    if (!dangerous) {
      for (final ext in kArchiveExt) {
        if (path.endsWith(ext)) {
          f.add(Finding(
            severity: Severity.warn,
            title: 'ملف مضغوط ($ext)',
            detail: 'الملفات المضغوطة تُستخدم لإخفاء برامج ضارة عن الفلاتر.',
            points: 12,
          ));
          break;
        }
      }
    }

    if (f.isEmpty) {
      f.add(const Finding(
        severity: Severity.good,
        title: 'لا علامات تصيّد شائعة',
        detail:
            'لم يطابق الرابط أي قاعدة فحص. هذا لا يضمن أنه آمن، فقد يكون دومينًا جديدًا مخترقًا.',
      ));
    }

    final parts = UrlParts(
      scheme: scheme,
      host: host,
      domain: domain,
      tld: tld,
      path: u.path.isEmpty ? '/' : u.path,
      query: u.query,
      port: u.hasPort ? '${u.port}' : '',
      normalizedUrl: candidate,
    );
    return _finish(f, parts, domain);
  }
}
