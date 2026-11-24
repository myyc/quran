import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quran.dart';
import '../state/app_state.dart';
import '../theme/quran_theme.dart';
import '../widgets/quran_text.dart';

void openReader(BuildContext context, {required int surah, int ayah = 1}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ReaderScreen(surahNumber: surah, initialAyah: ayah),
    ),
  );
}

const _arabicIndicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

String arabicIndic(int n) =>
    n.toString().split('').map((d) => _arabicIndicDigits[int.parse(d)]).join();

class ReaderScreen extends StatefulWidget {
  final int surahNumber;
  final int initialAyah;

  const ReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah = 1,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _scrollController = ItemScrollController();
  final _positionsListener = ItemPositionsListener.create();

  Surah get _surah => context.read<AppState>().surah(widget.surahNumber);

  final _flowKey = GlobalKey<_FlowViewState>();

  @override
  void initState() {
    super.initState();
    _positionsListener.itemPositions.addListener(_onPositionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().savePosition(
        widget.surahNumber,
        widget.initialAyah,
      );
    });
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onPositionChanged);
    super.dispose();
  }

  void _onPositionChanged() {
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final first = positions
        .where((p) => p.itemTrailingEdge > 0)
        .reduce((a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b);
    context.read<AppState>().savePosition(
      widget.surahNumber,
      first.index.clamp(1, _surah.ayahCount),
    );
  }

  void _jumpTo(int ayah) {
    if (context.read<AppState>().mode == ReadingMode.flow) {
      _flowKey.currentState?.jumpToAyah(ayah);
      return;
    }
    _scrollController.scrollTo(
      index: ayah.clamp(1, _surah.ayahCount),
      duration: const Duration(milliseconds: 300),
      alignment: 0.1,
    );
  }

  void _goToSurah(int number) {
    if (number < 1 || number > 114) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ReaderScreen(surahNumber: number)),
    );
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return;
    // RTL book order: swipe right -> next surah, swipe left -> previous.
    _goToSurah(widget.surahNumber + (velocity > 0 ? 1 : -1));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final surah = _surah;
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => _showJumpDialog(surah),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                surah.englishName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${surah.number} · ${surah.nameTranslation} · Juz ${surah.juz}',
                style: capsStyle(size: 9),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Text size',
            icon: const Icon(Icons.text_fields),
            onPressed: () => _showTextSizeSheet(context),
          ),
          PopupMenuButton<ReadingMode>(
            tooltip: 'Reading mode',
            icon: const Icon(Icons.auto_stories_outlined),
            color: QColors.panel,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            onSelected: state.setMode,
            itemBuilder: (_) => [
              for (final m in ReadingMode.values)
                PopupMenuItem(
                  value: m,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_modeLabel(m), style: const TextStyle(fontSize: 14)),
                      if (state.mode == m)
                        const Icon(
                          Icons.check,
                          size: 18,
                          color: QColors.accentBright,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _onSwipe,
        child: state.mode == ReadingMode.flow
            ? _FlowView(
                key: _flowKey,
                surah: surah,
                initialAyah: widget.initialAyah,
              )
            : ScrollablePositionedList.builder(
                itemScrollController: _scrollController,
                itemPositionsListener: _positionsListener,
                initialScrollIndex: widget.initialAyah.clamp(
                  1,
                  surah.ayahCount,
                ),
                itemCount: surah.ayahCount + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _SurahHeader(surah: surah);
                  final ayah = surah.ayahs[index - 1];
                  return switch (state.mode) {
                    ReadingMode.flow => throw StateError('handled above'),
                    ReadingMode.verses => _VerseAyah(surah: surah, ayah: ayah),
                    ReadingMode.study => _StudyAyah(surah: surah, ayah: ayah),
                  };
                },
              ),
      ),
    );
  }

  static String _modeLabel(ReadingMode mode) => switch (mode) {
    ReadingMode.flow => 'Flow · Arabic with separators',
    ReadingMode.verses => 'Verses · Arabic by ayah',
    ReadingMode.study => 'Study · Arabic + translation',
  };

  void _goTo(String input) {
    final text = input.trim().toLowerCase();
    if (text.startsWith('p')) {
      final page = int.tryParse(text.substring(1));
      if (page == null) return;
      final start = context.read<AppState>().pageStart(page);
      if (start != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                ReaderScreen(surahNumber: start.surah, initialAyah: start.ayah),
          ),
        );
      }
      return;
    }
    final n = int.tryParse(text);
    if (n != null) _jumpTo(n);
  }

  void _showJumpDialog(Surah surah) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('GO TO AYAH OR PAGE', style: capsStyle(size: 13)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: '1 – ${surah.ayahCount}, or p1 – p604',
            hintStyle: const TextStyle(color: QColors.dim),
          ),
          onSubmitted: (_) {
            Navigator.pop(context);
            _goTo(controller.text);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: capsStyle()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goTo(controller.text);
            },
            child: Text('GO', style: capsStyle(color: QColors.accentBright)),
          ),
        ],
      ),
    );
  }

  void _showTextSizeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<AppState>(
        builder: (context, state, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                InkWell(
                  onTap: () => state.setGreenDiacritics(!state.greenDiacritics),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('GREEN VOCALISATION', style: capsStyle()),
                      ),
                      Switch(
                        value: state.greenDiacritics,
                        activeThumbColor: QColors.accent,
                        onChanged: state.setGreenDiacritics,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Colours the harakat green so the base letters stand out.',
                  style: TextStyle(color: QColors.dim, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  final Surah surah;

  const _SurahHeader({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: QColors.accent)),
      ),
      child: Column(
        children: [
          Text(
            surah.shortArabicName,
            style: kufiStyle(34),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${surah.nameTranslation.toUpperCase()} · ${surah.ayahCount} AYAHS · '
            '${surah.revelationType.toUpperCase()}',
            style: capsStyle(size: 10),
            textAlign: TextAlign.center,
          ),
          if (surah.number != 9) ...[
            const SizedBox(height: 16),
            QuranText(
              context.read<AppState>().surah(1).ayahs.first.arabic,
              size: 24,
              align: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

void _showAyahActions(BuildContext context, Surah surah, Ayah ayah) {
  showModalBottomSheet(
    context: context,
    builder: (sheetContext) {
      final state = sheetContext.watch<AppState>();
      final bookmarked = state.isBookmarked(surah.number, ayah.number);
      final note = state.noteFor(surah.number, ayah.number);
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(
                  '${surah.englishName.toUpperCase()} ${surah.number}:${ayah.number}'
                  '${ayah.sajda ? ' · SAJDA' : ''}',
                  style: capsStyle(color: QColors.accentBright),
                ),
              ),
              if (state.mode != ReadingMode.study)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Text(
                    ayah.translation(state.translation),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                ),
              _ActionTile(
                icon: Icons.menu_book_outlined,
                label: 'Tafsir · Ibn Kathir',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showTafsir(context, surah, ayah);
                },
              ),
              _ActionTile(
                icon: bookmarked ? Icons.bookmark : Icons.bookmark_border,
                label: bookmarked ? 'Remove bookmark' : 'Bookmark',
                onTap: () {
                  state.toggleBookmark(surah.number, ayah.number);
                  Navigator.pop(sheetContext);
                },
              ),
              _ActionTile(
                icon: Icons.edit_note_outlined,
                label: note == null ? 'Add note' : 'Edit note',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showNoteDialog(context, surah, ayah);
                },
              ),
              _ActionTile(
                icon: Icons.copy_outlined,
                label: 'Copy Arabic',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: ayah.arabic));
                  Navigator.pop(sheetContext);
                },
              ),
              _ActionTile(
                icon: Icons.share_outlined,
                label: 'Share with translation',
                onTap: () {
                  Navigator.pop(sheetContext);
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          '${ayah.arabic}\n\n${ayah.translation(state.translation)}\n\n'
                          '— ${surah.englishName} ${surah.number}:${ayah.number} '
                          '(${translationEditions[state.translation]})',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showTafsir(BuildContext context, Surah surah, Ayah ayah) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                'TAFSIR · IBN KATHIR (ABRIDGED)\n'
                '${surah.englishName.toUpperCase()} ${surah.number}:${ayah.number}',
                style: capsStyle(color: QColors.accentBright),
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<int, String>>(
                future: loadTafsir(surah.number),
                builder: (context, snapshot) {
                  final text = snapshot.data?[ayah.number];
                  if (text == null) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: QColors.accent,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SelectableText(
                      text,
                      style: const TextStyle(fontSize: 15, height: 1.7),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showNoteDialog(BuildContext context, Surah surah, Ayah ayah) {
  final state = context.read<AppState>();
  final controller = TextEditingController(
    text: state.noteFor(surah.number, ayah.number),
  );
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'NOTE · ${surah.number}:${ayah.number}',
        style: capsStyle(size: 13),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 5,
        style: const TextStyle(fontSize: 15),
        decoration: const InputDecoration(
          hintText: 'Write a note…',
          hintStyle: TextStyle(color: QColors.dim),
        ),
      ),
      actions: [
        if (state.noteFor(surah.number, ayah.number) != null)
          TextButton(
            onPressed: () {
              state.removeNote(surah.number, ayah.number);
              Navigator.pop(dialogContext);
            },
            child: Text('DELETE', style: capsStyle()),
          ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text('CANCEL', style: capsStyle()),
        ),
        TextButton(
          onPressed: () {
            state.setNote(surah.number, ayah.number, controller.text);
            Navigator.pop(dialogContext);
          },
          child: Text('SAVE', style: capsStyle(color: QColors.accentBright)),
        ),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: QColors.dim),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _AyahMarker extends StatelessWidget {
  final Surah surah;
  final Ayah ayah;

  const _AyahMarker({required this.surah, required this.ayah});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bookmarked = state.isBookmarked(surah.number, ayah.number);
    final hasNote = state.noteFor(surah.number, ayah.number) != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${surah.number}:${ayah.number}',
          style: capsStyle(
            size: 10,
            color: bookmarked ? QColors.accentBright : QColors.dim,
          ),
        ),
        if (bookmarked) ...[
          const SizedBox(width: 6),
          const Icon(Icons.bookmark, size: 12, color: QColors.accentBright),
        ],
        if (hasNote) ...[
          const SizedBox(width: 6),
          const Icon(Icons.edit_note, size: 14, color: QColors.accentBright),
        ],
        if (ayah.sajda) ...[
          const SizedBox(width: 6),
          Text('۩', style: arabicStyle(14, color: QColors.accentBright)),
        ],
      ],
    );
  }
}

/// Renders the whole surah as one continuous paragraph. Ayah positions are
/// resolved from the laid-out paragraph (caret offsets), so jumping to an
/// ayah and saving the reading position stay exact despite there being no
/// per-ayah widgets.
class _FlowView extends StatefulWidget {
  final Surah surah;
  final int initialAyah;

  const _FlowView({super.key, required this.surah, required this.initialAyah});

  @override
  State<_FlowView> createState() => _FlowViewState();
}

class _FlowViewState extends State<_FlowView> {
  final _controller = ScrollController();
  final _textKey = GlobalKey();
  final _headerKey = GlobalKey();

  late final List<TapGestureRecognizer> _recognizers;
  final _starts = <int>[];
  List<double>? _dys;
  bool _initialJumpDone = false;

  @override
  void initState() {
    super.initState();
    _recognizers = [
      for (final ayah in widget.surah.ayahs)
        TapGestureRecognizer()
          ..onTap = () => _showAyahActions(context, widget.surah, ayah),
    ];
  }

  void _computeStarts(bool showMarks) {
    _starts.clear();
    var offset = 0;
    for (final ayah in widget.surah.ayahs) {
      _starts.add(offset);
      final text = showMarks ? ayah.arabic : stripRecitationMarks(ayah.arabic);
      offset += text.length + _separator(ayah.number).length;
    }
  }

  static String _separator(int n) => ' ﴿${arabicIndic(n)}﴾ ';

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _measure() {
    final render = _textKey.currentContext?.findRenderObject();
    if (render is! RenderParagraph) return;
    _dys = [
      for (final start in _starts)
        render.getOffsetForCaret(TextPosition(offset: start), Rect.zero).dy,
    ];
    if (!_initialJumpDone) {
      _initialJumpDone = true;
      if (widget.initialAyah > 1) {
        _controller.jumpTo(_offsetForAyah(widget.initialAyah));
      }
    }
    _saveVisiblePosition();
  }

  double get _headerHeight =>
      (_headerKey.currentContext?.findRenderObject() as RenderBox?)
          ?.size
          .height ??
      0;

  double _offsetForAyah(int ayah) {
    final dys = _dys;
    if (dys == null || dys.isEmpty) return 0;
    final i = (ayah - 1).clamp(0, dys.length - 1);
    return (_headerHeight + dys[i] - 12).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
  }

  void jumpToAyah(int ayah) {
    if (_dys == null) return;
    _controller.animateTo(
      _offsetForAyah(ayah),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _saveVisiblePosition() {
    final dys = _dys;
    if (dys == null || !_controller.hasClients) return;
    final target = _controller.offset - _headerHeight;
    final lineHeight = context.read<AppState>().arabicSize * 1.9;
    var ayah = 1;
    for (var i = 0; i < dys.length; i++) {
      if (dys[i] + lineHeight > target) {
        ayah = i + 1;
        break;
      }
      ayah = i + 1;
    }
    context.read<AppState>().savePosition(widget.surah.number, ayah);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final size = state.arabicSize;
    _computeStarts(state.showRecitationMarks);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    return NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        _saveVisiblePosition();
        return false;
      },
      child: SingleChildScrollView(
        controller: _controller,
        child: Column(
          children: [
            _SurahHeader(key: _headerKey, surah: widget.surah),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: RichText(
                  key: _textKey,
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    children: [
                      for (var i = 0; i < widget.surah.ayahs.length; i++) ...[
                        ...vocalisedSpans(
                          widget.surah.ayahs[i].arabic,
                          size,
                          green: state.greenDiacritics,
                          showRecitationMarks: state.showRecitationMarks,
                          recognizer: _recognizers[i],
                        ),
                        TextSpan(
                          text: _separator(widget.surah.ayahs[i].number),
                          style: arabicStyle(
                            size * 0.75,
                            color: QColors.accentBright,
                          ),
                          recognizer: _recognizers[i],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseAyah extends StatelessWidget {
  final Surah surah;
  final Ayah ayah;

  const _VerseAyah({required this.surah, required this.ayah});

  @override
  Widget build(BuildContext context) {
    final size = context.watch<AppState>().arabicSize;
    return InkWell(
      onTap: () => _showAyahActions(context, surah, ayah),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: QColors.rule)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AyahMarker(surah: surah, ayah: ayah),
            const SizedBox(height: 8),
            QuranText(ayah.arabic, size: size),
          ],
        ),
      ),
    );
  }
}

class _StudyAyah extends StatelessWidget {
  final Surah surah;
  final Ayah ayah;

  const _StudyAyah({required this.surah, required this.ayah});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return InkWell(
      onTap: () => _showAyahActions(context, surah, ayah),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: QColors.rule)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AyahMarker(surah: surah, ayah: ayah),
            const SizedBox(height: 10),
            QuranText(ayah.arabic, size: state.arabicSize),
            const SizedBox(height: 12),
            Text(
              ayah.translation(state.translation),
              style: TextStyle(
                fontSize: state.translationSize,
                height: 1.55,
                color: const Color(0xCCFFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
