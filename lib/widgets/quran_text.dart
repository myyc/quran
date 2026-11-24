import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/quran_theme.dart';

/// Arabic combining marks: harakat, dagger alif, small high marks and
/// pause/recitation signs that sit on top of the base letters.
final _diacritic = RegExp(
  '[\\u0610-\\u061A\\u064B-\\u065F\\u0670\\u06D6-\\u06DC'
  '\\u06DF-\\u06E4\\u06E7\\u06E8\\u06EA-\\u06ED'
  '\\u08D3-\\u08E1\\u08E3-\\u08FF]',
);

bool isDiacritic(int rune) => _diacritic.hasMatch(String.fromCharCode(rune));

/// Waqf (pause) signs and the sajdah mark. Not part of the words; hidden
/// by default because the bundled font renders them oversized/misplaced.
final _recitationMarks = RegExp('[\\u06D6-\\u06DC\\u06E9]');

String stripRecitationMarks(String text) =>
    text.replaceAll(_recitationMarks, '');

List<TextSpan> vocalisedSpans(
  String text,
  double size, {
  required bool green,
  bool showRecitationMarks = true,
  GestureRecognizer? recognizer,
}) {
  if (!showRecitationMarks) text = stripRecitationMarks(text);
  if (!green || text.isEmpty) {
    return [
      TextSpan(text: text, style: arabicStyle(size), recognizer: recognizer),
    ];
  }
  final spans = <TextSpan>[];
  final runes = text.runes.toList();
  var start = 0;
  var currentIsMark = isDiacritic(runes.first);
  for (var i = 1; i <= runes.length; i++) {
    final mark = i < runes.length ? isDiacritic(runes[i]) : !currentIsMark;
    if (mark != currentIsMark || i == runes.length) {
      spans.add(
        TextSpan(
          text: String.fromCharCodes(runes.sublist(start, i)),
          style: currentIsMark
              ? arabicStyle(size, color: QColors.accentBright)
              : arabicStyle(size),
          recognizer: recognizer,
        ),
      );
      start = i;
      currentIsMark = mark;
    }
  }
  return spans;
}

class QuranText extends StatelessWidget {
  final String text;
  final double size;
  final TextAlign align;

  const QuranText(
    this.text, {
    super.key,
    required this.size,
    this.align = TextAlign.right,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: double.infinity,
        child: RichText(
          textAlign: align,
          text: TextSpan(
            children: vocalisedSpans(
              text,
              size,
              green: state.greenDiacritics,
              showRecitationMarks: state.showRecitationMarks,
            ),
          ),
        ),
      ),
    );
  }
}
