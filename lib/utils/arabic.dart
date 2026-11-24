import '../widgets/quran_text.dart';

/// Folds Arabic text for search: strips harakat, waqf marks and tatweel,
/// and unifies alef/yeh forms so queries typed without diacritics match.
String normalizeArabic(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (isDiacritic(rune)) continue;
    final char = String.fromCharCode(rune);
    if (_recitationOrTatweel.hasMatch(char)) continue;
    buffer.write(_fold[char] ?? char);
  }
  return buffer.toString();
}

final _recitationOrTatweel = RegExp('[\\u06D6-\\u06DC\\u06E9\\u0640]');

const _fold = {
  'أ': 'ا',
  'إ': 'ا',
  'آ': 'ا',
  'ٱ': 'ا',
  'ى': 'ي',
  'ئ': 'ي',
  'ؤ': 'و',
  'ة': 'ه',
};
