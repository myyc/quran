import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quran.dart';
import '../state/app_state.dart';
import '../theme/quran_theme.dart';
import '../utils/arabic.dart';
import 'reader_screen.dart';
import 'surah_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final q = _query.toLowerCase();
    final arabicQuery = normalizeArabic(_query);

    final surahResults = state.surahs.where((s) {
      if (q.isEmpty) return false;
      return s.englishName.toLowerCase().contains(q) ||
          s.nameTranslation.toLowerCase().contains(q) ||
          s.arabicName.contains(_query) ||
          s.number.toString() == q;
    }).toList();

    final ayahResults = <({Surah surah, Ayah ayah})>[];
    if (q.length >= 2) {
      outer:
      for (final s in state.surahs) {
        for (final a in s.ayahs) {
          if (normalizeArabic(a.arabic).contains(arabicQuery) ||
              a.translation(state.translation).toLowerCase().contains(q)) {
            ayahResults.add((surah: s, ayah: a));
            if (ayahResults.length >= 50) break outer;
          }
        }
      }
    }

    final empty = surahResults.isEmpty && ayahResults.isEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          autofocus: true,
          onChanged: (value) => setState(() => _query = value.trim()),
          style: const TextStyle(fontSize: 16),
          cursorColor: QColors.accent,
          decoration: const InputDecoration(
            hintText: 'Surahs, ayat, translations…',
            hintStyle: TextStyle(color: QColors.dim, fontSize: 16),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: empty
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) < -200) {
                  Navigator.of(context).pop();
                }
              },
              child: Center(
                child: Text(
                  _query.isEmpty
                      ? 'Type a name, number, Arabic or English text.'
                      : 'No matches.',
                  style: const TextStyle(color: QColors.dim, fontSize: 14),
                ),
              ),
            )
          : ListView(
              children: [
                if (surahResults.isNotEmpty) ...[
                  _SectionHeader('SURAHS'),
                  ...surahResults.map((s) => SurahTile(surah: s)),
                ],
                if (ayahResults.isNotEmpty) ...[
                  _SectionHeader(
                    'AYAT${ayahResults.length == 50 ? ' · FIRST 50' : ''}',
                  ),
                  for (final r in ayahResults)
                    _AyahResult(
                      surah: r.surah,
                      ayah: r.ayah,
                      translation: state.translation,
                    ),
                ],
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(label, style: capsStyle(size: 10)),
    );
  }
}

class _AyahResult extends StatelessWidget {
  final Surah surah;
  final Ayah ayah;
  final String translation;

  const _AyahResult({
    required this.surah,
    required this.ayah,
    required this.translation,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openReader(context, surah: surah.number, ayah: ayah.number),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${surah.englishName.toUpperCase()} ${surah.number}:${ayah.number}',
              style: capsStyle(size: 10, color: QColors.accentBright),
            ),
            const SizedBox(height: 6),
            Text(
              ayah.translation(translation),
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xCCFFFFFF),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
