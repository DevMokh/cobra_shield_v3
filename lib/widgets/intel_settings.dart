import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/settings_store.dart';
import '../services/threat_feed.dart';
import 'common.dart';

/// إعدادات مصادر التهديدات: قاعدة OpenPhish المحلية + مفاتيح API الخاصة بك.
class IntelSettingsPanel extends StatefulWidget {
  const IntelSettingsPanel({super.key});

  @override
  State<IntelSettingsPanel> createState() => _IntelSettingsPanelState();
}

class _IntelSettingsPanelState extends State<IntelSettingsPanel> {
  final TextEditingController _gsb = TextEditingController();
  final TextEditingController _vt = TextEditingController();
  late final Listenable _merged =
      Listenable.merge(<Listenable>[ThreatFeed.instance, SettingsStore.instance]);
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    _gsb.text = SettingsStore.instance.gsbKey;
    _vt.text = SettingsStore.instance.vtKey;
  }

  @override
  void dispose() {
    _gsb.dispose();
    _vt.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final feed = ThreatFeed.instance;
    final ok = await feed.update();
    if (!mounted) return;
    toast(
      context,
      ok ? 'تم التحديث: ${feed.count} رابط' : (feed.lastError ?? 'فشل التحديث'),
    );
  }

  Future<void> _saveKeys() async {
    FocusScope.of(context).unfocus();
    await SettingsStore.instance.setKeys(gsb: _gsb.text, vt: _vt.text);
    if (!mounted) return;
    toast(context, 'تم حفظ المفاتيح على هذا الجهاز');
  }

  Widget _keyField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      obscureText: _hide,
      autocorrect: false,
      enableSuggestions: false,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      style: const TextStyle(fontFamily: 'monospace', color: C.text, fontSize: 13),
      decoration: fieldDecoration(hint: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _merged,
      builder: (context, _) {
        final feed = ThreatFeed.instance;
        final updated = feed.updated;
        return Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('مصادر التهديدات الحية'),
              const Text(
                'تُستخدم في "الفحص المتقدم" داخل تبويب فحص الرابط. كلها اختيارية.',
                style: TextStyle(color: C.muted, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.shield_moon_rounded, color: C.emerald, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'قاعدة OpenPhish (محلية)',
                          style: TextStyle(
                            color: C.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          feed.count == 0
                              ? 'غير محمّلة'
                              : '${feed.count} رابط${updated != null ? ' - ${fmtTime(updated)}' : ''}',
                          style: const TextStyle(color: C.muted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: feed.busy ? null : _update,
                    style: outlineButtonStyle(),
                    child: feed.busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('تحديث'),
                  ),
                ],
              ),
              const Divider(color: C.line, height: 28),
              const Text(
                'مفاتيح API (اختيارية)',
                style: TextStyle(
                  color: C.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              _keyField(_gsb, 'Google Safe Browsing API key'),
              const SizedBox(height: 8),
              _keyField(_vt, 'VirusTotal API key'),
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => setState(() => _hide = !_hide),
                  icon: Icon(
                    _hide ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 18,
                  ),
                  label: Text(_hide ? 'إظهار' : 'إخفاء'),
                  style: TextButton.styleFrom(foregroundColor: C.muted),
                ),
              ),
              FilledButton.icon(
                onPressed: _saveKeys,
                style: filledButtonStyle(),
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ المفاتيح'),
              ),
              const SizedBox(height: 12),
              const Text(
                'الحصول على المفاتيح: Google Safe Browsing من Google Cloud Console (فعّل Safe Browsing API وأنشئ API key)، و VirusTotal من حسابك المجاني في موقعهم. '
                'المفاتيح تبقى على جهازك فقط.\n\n'
                'تنبيه ترخيص: الخطط المجانية لـ Google Safe Browsing و VirusTotal و OpenPhish مخصصة للاستخدام غير التجاري. '
                'لو ستنشر التطبيق بمقابل أو بإعلانات فراجع شروط كل جهة أو استخدم خطط تجارية.',
                style: TextStyle(color: C.muted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }
}
