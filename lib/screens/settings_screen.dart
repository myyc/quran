import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quran.dart';
import '../state/app_state.dart';
import '../theme/quran_theme.dart';
import '../widgets/quran_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('SETTINGS', style: capsStyle(size: 16, color: QColors.ink)),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text('READING MODE', style: capsStyle()),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final m in ReadingMode.values)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: m != ReadingMode.study ? 8 : 0,
                    ),
                    child: _ModeButton(
                      label: switch (m) {
                        ReadingMode.flow => 'FLOW',
                        ReadingMode.verses => 'VERSES',
                        ReadingMode.study => 'STUDY',
                      },
                      selected: state.mode == m,
                      onTap: () => state.setMode(m),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Flow: Arabic with separators · Verses: Arabic by ayah · '
            'Study: Arabic with translation',
            style: TextStyle(color: QColors.dim, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 32),
          Text('TRANSLATION', style: capsStyle()),
          const SizedBox(height: 8),
          for (final entry in translationEditions.entries)
            InkWell(
              onTap: () => state.setTranslation(entry.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 15,
                          color: state.translation == entry.key
                              ? QColors.ink
                              : QColors.dim,
                        ),
                      ),
                    ),
                    if (state.translation == entry.key)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: QColors.accentBright,
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('ARABIC TEXT SIZE', style: capsStyle()),
          Slider(
            value: state.arabicSize,
            min: 20,
            max: 48,
            onChanged: state.setArabicSize,
          ),
          Text('TRANSLATION SIZE', style: capsStyle()),
          Slider(
            value: state.translationSize,
            min: 11,
            max: 24,
            onChanged: state.setTranslationSize,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GREEN VOCALISATION', style: capsStyle()),
                    const SizedBox(height: 4),
                    const Text(
                      'Harakat in green, base letters in white.',
                      style: TextStyle(color: QColors.dim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.greenDiacritics,
                activeThumbColor: QColors.accent,
                onChanged: state.setGreenDiacritics,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RECITATION MARKS', style: capsStyle()),
                    const SizedBox(height: 4),
                    const Text(
                      'Waqf pause signs and sajdah marks in the Arabic text.',
                      style: TextStyle(color: QColors.dim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.showRecitationMarks,
                activeThumbColor: QColors.accent,
                onChanged: state.setShowRecitationMarks,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QColors.panel,
              border: Border.all(color: QColors.rule),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuranText(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  size: state.arabicSize,
                ),
                const SizedBox(height: 10),
                Text(
                  'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
                  style: TextStyle(
                    fontSize: state.translationSize,
                    height: 1.55,
                    color: QColors.dim,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text('BACKUP', style: capsStyle()),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _exportBackup(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.upload_outlined, size: 20, color: QColors.dim),
                  SizedBox(width: 12),
                  Text(
                    'Export bookmarks, notes & settings',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => _importBackup(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.download_outlined, size: 20, color: QColors.dim),
                  SizedBox(width: 12),
                  Text('Import backup', style: TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('ABOUT', style: capsStyle()),
          const SizedBox(height: 12),
          const Text(
            'Arabic text: Uthmani script via AlQuran Cloud (Tanzil project).\n'
            'Translations: Saheeh International, Mustafa Khattab, Pickthall, '
            'Yusuf Ali.\n'
            'Tafsir: Ibn Kathir (abridged).\n\n'
            'The Quran is stored on your device. Reading position, bookmarks '
            'and notes are kept locally and work fully offline.',
            style: TextStyle(color: QColors.dim, fontSize: 13, height: 1.7),
          ),
          const SizedBox(height: 16),
          Text('QURAN 1.0.0 · DEV.MYYC.QURAN', style: capsStyle(size: 9)),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? QColors.accent : QColors.panel,
          border: Border.all(color: selected ? QColors.accent : QColors.rule),
        ),
        child: Text(
          label,
          style: capsStyle(
            size: 11,
            color: selected ? QColors.ink : QColors.dim,
          ),
        ),
      ),
    );
  }
}

Future<void> _exportBackup(BuildContext context) async {
  final state = context.read<AppState>();
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/quran-backup.json');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(state.exportData()),
  );
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: 'Quran backup'),
  );
}

Future<void> _importBackup(BuildContext context) async {
  final state = context.read<AppState>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null) return;
    var bytes = result.files.single.bytes;
    if (bytes == null) {
      final path = result.files.single.path;
      if (path == null) return;
      bytes = await File(path).readAsBytes();
    }
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! Map<String, dynamic> || data['app'] != 'dev.myyc.quran') {
      throw const FormatException('not a quran backup');
    }
    await state.importData(data);
    messenger.showSnackBar(const SnackBar(content: Text('Backup imported.')));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not import: invalid backup file.')),
    );
  }
}
