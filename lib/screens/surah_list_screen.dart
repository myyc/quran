import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quran.dart';
import '../state/app_state.dart';
import '../theme/quran_theme.dart';
import 'reader_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  bool _showJuz = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<Map<int, int>>(
          valueListenable: state.progress,
          builder: (context, progress, _) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      _IndexTab(
                        label: 'SURAHS',
                        selected: !_showJuz,
                        onTap: () => setState(() => _showJuz = false),
                      ),
                      const SizedBox(width: 8),
                      _IndexTab(
                        label: 'JUZ',
                        selected: _showJuz,
                        onTap: () => setState(() => _showJuz = true),
                      ),
                      const Spacer(),
                      Text(
                        '${(state.khatamFraction * 100).toStringAsFixed(1)}% READ',
                        style: capsStyle(size: 10),
                      ),
                    ],
                  ),
                ),
                if (_showJuz)
                  ...state.juzStarts.map((j) => _JuzTile(start: j))
                else ...[
                  const _ContinueCard(),
                  ...state.surahs.map(
                    (s) =>
                        SurahTile(surah: s, readAyah: progress[s.number] ?? 0),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IndexTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _IndexTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? QColors.accent : QColors.panel,
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

class _JuzTile extends StatelessWidget {
  final ({int juz, int surah, int ayah}) start;

  const _JuzTile({required this.start});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final surah = state.surah(start.surah);
    return InkWell(
      onTap: () => openReader(context, surah: start.surah, ayah: start.ayah),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '${start.juz}',
                style: const TextStyle(
                  color: QColors.accentBright,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Juz ${start.juz}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${surah.englishName} ${start.surah}:${start.ayah}',
              style: const TextStyle(color: QColors.dim, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return ValueListenableBuilder<({int surah, int ayah})?>(
      valueListenable: state.position,
      builder: (context, pos, _) {
        if (pos == null) return const SizedBox.shrink();
        final surah = state.surah(pos.surah);
        return InkWell(
          onTap: () => openReader(context, surah: surah.number, ayah: pos.ayah),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QColors.panel,
              border: Border.all(color: QColors.accent),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTINUE READING',
                        style: capsStyle(size: 10, color: QColors.accentBright),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        surah.englishName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ayah ${pos.ayah} of ${surah.ayahCount}',
                        style: const TextStyle(
                          color: QColors.dim,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: QColors.accentBright),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SurahTile extends StatelessWidget {
  final Surah surah;
  final int readAyah;

  const SurahTile({super.key, required this.surah, this.readAyah = 0});

  @override
  Widget build(BuildContext context) {
    final fraction = (readAyah / surah.ayahCount).clamp(0.0, 1.0);
    return InkWell(
      onTap: () => openReader(context, surah: surah.number),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    '${surah.number}',
                    style: const TextStyle(
                      color: QColors.accentBright,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.englishName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${surah.nameTranslation} · ${surah.ayahCount} ayahs · '
                        '${surah.revelationType}',
                        style: const TextStyle(
                          color: QColors.dim,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(surah.shortArabicName, style: kufiStyle(20)),
              ],
            ),
          ),
          if (fraction > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                child: Container(height: 2, color: QColors.accent),
              ),
            ),
        ],
      ),
    );
  }
}
