import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quran.dart';
import '../state/app_state.dart';
import '../theme/quran_theme.dart';
import '../widgets/quran_text.dart';
import 'reader_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('SAVED', style: capsStyle(size: 16, color: QColors.ink)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'BOOKMARKS'),
              Tab(text: 'NOTES'),
            ],
          ),
        ),
        body: const TabBarView(children: [_BookmarksTab(), _NotesTab()]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;

  const _Empty(this.message);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                message,
                style: const TextStyle(
                  color: QColors.dim,
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookmarksTab extends StatelessWidget {
  const _BookmarksTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.bookmarks.isEmpty) {
      return const _Empty(
        'No bookmarks yet.\nTap an ayah while reading to bookmark it.',
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        for (final b in state.bookmarks)
          Dismissible(
            key: ValueKey('bm-${b.key}'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: QColors.accent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(Icons.delete_outline, color: QColors.ink),
            ),
            onDismissed: (_) => state.toggleBookmark(b.surah, b.ayah),
            child: _SavedTile(
              surah: state.surah(b.surah),
              ayahNumber: b.ayah,
              onTap: () => openReader(context, surah: b.surah, ayah: b.ayah),
            ),
          ),
      ],
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.notes.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) {
      return const _Empty(
        'No notes yet.\nTap an ayah while reading to add a note.',
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        for (final e in entries)
          Builder(
            builder: (context) {
              final parts = e.key.split(':');
              final surah = int.parse(parts[0]);
              final ayah = int.parse(parts[1]);
              return Dismissible(
                key: ValueKey('note-${e.key}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: QColors.accent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(Icons.delete_outline, color: QColors.ink),
                ),
                onDismissed: (_) => state.removeNote(surah, ayah),
                child: _SavedTile(
                  surah: state.surah(surah),
                  ayahNumber: ayah,
                  note: e.value,
                  onTap: () => openReader(context, surah: surah, ayah: ayah),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _SavedTile extends StatelessWidget {
  final Surah surah;
  final int ayahNumber;
  final String? note;
  final VoidCallback onTap;

  const _SavedTile({
    required this.surah,
    required this.ayahNumber,
    required this.onTap,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final ayah = surah.ayahs[ayahNumber - 1];
    final appState = context.watch<AppState>();
    final showMarks = appState.showRecitationMarks;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: QColors.rule)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${surah.englishName.toUpperCase()} ${surah.number}:$ayahNumber',
              style: capsStyle(size: 10, color: QColors.accentBright),
            ),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  showMarks ? ayah.arabic : stripRecitationMarks(ayah.arabic),
                  style: arabicStyle(22),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              note ?? ayah.translation(appState.translation),
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: note != null ? QColors.ink : QColors.dim,
                fontStyle: note != null ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
