import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../services/inbox.dart';
import '../services/message_analyzer.dart';
import '../services/settings_store.dart';
import 'history_screen.dart';
import 'message_scan_screen.dart';
import 'tools_screen.dart';
import 'train_screen.dart';
import 'url_scan_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  String _lastClip = '';

  final List<Widget> _pages = const <Widget>[
    UrlScanScreen(),
    MessageScanScreen(),
    TrainScreen(),
    ToolsScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Inbox.shared.addListener(_onShared);
    Inbox.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkClipboard());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Inbox.shared.removeListener(_onShared);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
  }

  /// نص جاي من "مشاركة" أو تحديد نص: رابط واحد -> فحص رابط، غير كده -> فحص رسالة
  void _onShared() {
    final inc = Inbox.shared.value;
    if (inc == null) return;
    final text = inc.text;
    final links = MessageAnalyzer.extractLinks(text);
    final singleLink = links.length == 1 && (text.length - links.first.length) < 12;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (singleLink) {
        setState(() => _index = 0);
        Inbox.toUrl.value = Incoming(links.first);
      } else {
        setState(() => _index = 1);
        Inbox.toMessage.value = Incoming(text);
      }
    });
  }

  Future<void> _checkClipboard() async {
    if (!SettingsStore.instance.clipWatch) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    try {
      final d = await Clipboard.getData(Clipboard.kTextPlain);
      final t = d?.text?.trim();
      if (t == null || t.isEmpty || t == _lastClip) return;
      _lastClip = t;
      final links = MessageAnalyzer.extractLinks(t);
      if (links.isEmpty || !mounted) return;
      final first = links.first;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: const Text('في رابط منسوخ. تحب تفحصه؟'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'افحص',
          textColor: C.emerald,
          onPressed: () {
            setState(() => _index = 0);
            Inbox.toUrl.value = Incoming(first);
          },
        ),
      ));
    } catch (_) {
      // أندرويد منع قراءة الحافظة الآن: نتجاهل
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.link_rounded),
            selectedIcon: Icon(Icons.link_rounded),
            label: 'رابط',
          ),
          NavigationDestination(
            icon: Icon(Icons.mark_email_unread_outlined),
            selectedIcon: Icon(Icons.mark_email_unread_rounded),
            label: 'رسالة',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports_rounded),
            label: 'تدرّب',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_circle_outlined),
            selectedIcon: Icon(Icons.build_circle_rounded),
            label: 'أدوات',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'السجل',
          ),
        ],
      ),
    );
  }
}
