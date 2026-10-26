// أدوات معالجة النص العربي/الإنجليزي لمطابقة الكلمات المفتاحية

bool _isAscii(String s) => s.runes.every((r) => r < 128);

/// يوحّد النص: يشيل التشكيل والتطويل والحروف الخفية، يوحّد الألف والياء والتاء
/// المربوطة، يحوّل الأرقام الهندية لإنجليزية، ويحوّل الإنجليزي لحروف صغيرة.
String normalizeText(String input) {
  final b = StringBuffer();
  for (final r in input.runes) {
    // تشكيل + تطويل + حروف خفية
    if ((r >= 0x064B && r <= 0x065F) ||
        r == 0x0640 ||
        r == 0x0670 ||
        r == 0x200B ||
        r == 0x200C ||
        r == 0x200D ||
        r == 0x200E ||
        r == 0x200F ||
        r == 0x2060 ||
        r == 0xFEFF) {
      continue;
    }
    if (r == 0x0623 || r == 0x0625 || r == 0x0622) {
      b.writeCharCode(0x0627); // أ إ آ -> ا
    } else if (r == 0x0649 || r == 0x0626) {
      b.writeCharCode(0x064A); // ى ئ -> ي
    } else if (r == 0x0629) {
      b.writeCharCode(0x0647); // ة -> ه
    } else if (r == 0x0624) {
      b.writeCharCode(0x0648); // ؤ -> و
    } else if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(0x30 + (r - 0x0660)); // أرقام هندية
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(0x30 + (r - 0x06F0)); // أرقام فارسية
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString().toLowerCase();
}

/// يبني تعبيرًا نمطيًا يطابق الكلمة كاملة (مع السماح بسوابق ولواحق عربية بسيطة)
/// عشان "الان" ما تطابقش "الانتظار" و"pin" ما تطابقش "pinterest".
RegExp buildKeywordRegex(String keyword) {
  final k = normalizeText(keyword.trim());
  final esc = RegExp.escape(k);
  if (_isAscii(k)) {
    if (k.length >= 6) {
      return RegExp('(?<![a-z0-9])$esc');
    }
    return RegExp('(?<![a-z0-9])$esc(?![a-z0-9])');
  }
  return RegExp(
    '(?<![\\u0621-\\u064A])[وفبلك]?(?:ال)?$esc(?:ها|هم|كم|نا|ه|ك|ي)?(?![\\u0621-\\u064A])',
  );
}
