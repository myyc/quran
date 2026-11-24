import 'package:flutter_test/flutter_test.dart';
import 'package:quran/models/quran.dart';
import 'package:quran/state/app_state.dart';
import 'package:quran/theme/quran_theme.dart';
import 'package:quran/utils/arabic.dart';
import 'package:quran/widgets/quran_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled Quran has 114 surahs and 6236 ayahs', () async {
    final surahs = await loadQuran();
    expect(surahs.length, 114);
    expect(surahs.fold<int>(0, (n, s) => n + s.ayahCount), 6236);

    final fatiha = surahs.first;
    expect(fatiha.englishName, 'Al-Faatiha');
    expect(fatiha.ayahCount, 7);
    expect(fatiha.ayahs.first.arabic, contains('بِسْمِ'));
    expect(fatiha.ayahs.first.english, contains('In the name of Allah'));

    final baqarah = surahs[1];
    expect(baqarah.ayahCount, 286);
    expect(baqarah.ayahs.last.number, 286);
  });

  test('basmala stripped from first ayah except surahs 1 and 9', () async {
    final surahs = await loadQuran();
    expect(surahs[0].ayahs.first.arabic, contains('بِسْمِ'));
    expect(surahs[1].ayahs.first.arabic, 'الٓمٓ');
    expect(surahs[8].ayahs.first.arabic, isNot(contains('بِسْمِ')));
    for (final s in surahs.skip(1)) {
      expect(s.ayahs.first.arabic.startsWith('بِسْمِ'), isFalse,
          reason: 'surah ${s.number}');
    }
  });

  test('four translations, pages and tafsir bundled', () async {
    final surahs = await loadQuran();
    final ayah = surahs[1].ayahs[254];
    expect(ayah.translations.keys.toSet(),
        {'sahih', 'khattab', 'pickthall', 'yusufali'});
    expect(ayah.translation('khattab'), isNotEmpty);
    expect(ayah.page, greaterThan(1));
    expect(surahs[1].ayahs.first.page, 2);
    final tafsir = await loadTafsir(2);
    expect(tafsir[255], isNotNull);
    expect(tafsir[255]!.length, greaterThan(100));
  });

  test('arabic search normalisation', () {
    expect(normalizeArabic('بِسْمِ ٱللَّهِ'), 'بسم الله');
    expect(normalizeArabic('الٓمٓ'), 'الم');
  });

  test('vocalisedSpans separates harakat from base letters', () {
    const text = 'بِسْمِ';
    final spans = vocalisedSpans(text, 30, green: true);
    final joined = spans.map((s) => s.text).join();
    expect(joined, text);
    expect(spans.length, greaterThan(1));
    final greenSpans = spans.where(
      (s) => s.style?.color == QColors.accentBright,
    );
    expect(greenSpans.isNotEmpty, isTrue);
    expect(greenSpans.every((s) => s.text!.runes.every(isDiacritic)), isTrue);
    final whiteSpans = spans.where((s) => s.style?.color == QColors.ink);
    expect(
      whiteSpans.every((s) => s.text!.runes.every((r) => !isDiacritic(r))),
      isTrue,
    );

    final plain = vocalisedSpans(text, 30, green: false);
    expect(plain.length, 1);
    expect(plain.single.text, text);
  });

  test('recitation marks are stripped, letters and harakat kept', () {
    expect(stripRecitationMarks('قُلْ هُوَ ۚ اللَّهُ'), 'قُلْ هُوَ  اللَّهُ');
    expect(stripRecitationMarks('يَسْجُدُونَ ۩'), 'يَسْجُدُونَ ');
    final spans = vocalisedSpans(
      'قُلْ هُوَ ۚ اللَّهُ',
      30,
      green: false,
      showRecitationMarks: false,
    );
    expect(spans.single.text, 'قُلْ هُوَ  اللَّهُ');
  });

  test('bookmarks serialize round-trip', () {
    const b = Bookmark(surah: 2, ayah: 255, createdAt: 1234);
    final restored = Bookmark.fromJson(b.toJson());
    expect(restored.surah, 2);
    expect(restored.ayah, 255);
    expect(restored.createdAt, 1234);
    expect(restored.key, '2:255');
  });
}
