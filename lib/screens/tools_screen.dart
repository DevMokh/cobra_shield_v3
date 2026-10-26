import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/intel_settings.dart';
import '../widgets/scale_header.dart';
import '../widgets/tools.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  int _tab = 0;

  Widget _tool() {
    switch (_tab) {
      case 0:
        return const StrengthTool();
      case 1:
        return const GeneratorTool();
      case 2:
        return const CleanerTool();
      default:
        return const HashTool();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ScaleHeader(
          title: 'أدوات الأمان',
          subtitle: 'كلمات السر والروابط والبصمات',
          icon: Icons.build_circle_rounded,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 0, label: Text('القوة')),
                  ButtonSegment<int>(value: 1, label: Text('مولّد')),
                  ButtonSegment<int>(value: 2, label: Text('منظّف')),
                  ButtonSegment<int>(value: 3, label: Text('هاش')),
                ],
                selected: <int>{_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
                style: SegmentedButton.styleFrom(
                  backgroundColor: C.surface,
                  foregroundColor: C.muted,
                  selectedBackgroundColor: alpha(C.emerald, 0.2),
                  selectedForegroundColor: C.emerald,
                  side: const BorderSide(color: C.line),
                ),
              ),
              const SizedBox(height: 14),
              _tool(),
              const SizedBox(height: 18),
              const IntelSettingsPanel(),
              const SizedBox(height: 14),
              const SettingsPanel(),
            ],
          ),
        ),
      ],
    );
  }
}
