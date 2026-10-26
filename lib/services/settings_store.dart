import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore._();

  static final SettingsStore instance = SettingsStore._();

  static const String _kClip = 'cobra.clipwatch';
  static const String _kGsb = 'cobra.key.gsb';
  static const String _kVt = 'cobra.key.vt';
  static const String _kConsent = 'cobra.intel.consent';

  bool _clipWatch = false;
  String _gsbKey = '';
  String _vtKey = '';
  bool _intelConsent = false;

  bool get clipWatch => _clipWatch;
  String get gsbKey => _gsbKey;
  String get vtKey => _vtKey;
  bool get intelConsent => _intelConsent;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _clipWatch = p.getBool(_kClip) ?? false;
      _gsbKey = p.getString(_kGsb) ?? '';
      _vtKey = p.getString(_kVt) ?? '';
      _intelConsent = p.getBool(_kConsent) ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setClipWatch(bool v) async {
    _clipWatch = v;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kClip, v);
    } catch (_) {}
  }

  Future<void> setIntelConsent(bool v) async {
    _intelConsent = v;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kConsent, v);
    } catch (_) {}
  }

  Future<void> setKeys({required String gsb, required String vt}) async {
    _gsbKey = gsb.trim();
    _vtKey = vt.trim();
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kGsb, _gsbKey);
      await p.setString(_kVt, _vtKey);
    } catch (_) {}
  }
}
