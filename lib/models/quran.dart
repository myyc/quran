import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

const translationEditions = <String, String>{
  'sahih': 'Saheeh International',
  'khattab': 'Mustafa Khattab · Clear Quran',
  'pickthall': 'Pickthall',
  'yusufali': 'Yusuf Ali',
};

class Ayah {
  final int number;
  final String arabic;
  final Map<String, String> translations;
  final int juz;
  final int page;
  final bool sajda;

  const Ayah({
    required this.number,
    required this.arabic,
    required this.translations,
    required this.juz,
    required this.page,
    required this.sajda,
  });

  String translation(String edition) =>
      translations[edition] ?? translations['sahih']!;

  String get english => translations['sahih']!;

  factory Ayah.fromJson(Map<String, dynamic> json) => Ayah(
    number: json['a'] as int,
    arabic: json['ar'] as String,
    translations: (json['tr'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as String),
    ),
    juz: json['j'] as int,
    page: json['p'] as int,
    sajda: json['s'] as bool,
  );
}

class Surah {
  final int number;
  final String arabicName;
  final String englishName;
  final String nameTranslation;
  final String revelationType;
  final List<Ayah> ayahs;

  const Surah({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.nameTranslation,
    required this.revelationType,
    required this.ayahs,
  });

  int get ayahCount => ayahs.length;
  int get juz => ayahs.first.juz;
  String get shortArabicName => arabicName.replaceFirst('سُورَةُ ', '');

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
    number: json['n'] as int,
    arabicName: json['name'] as String,
    englishName: json['ename'] as String,
    nameTranslation: json['tname'] as String,
    revelationType: json['type'] as String,
    ayahs: (json['ayahs'] as List)
        .map((a) => Ayah.fromJson(a as Map<String, dynamic>))
        .toList(),
  );
}

Future<List<Surah>> loadQuran() async {
  final raw = await rootBundle.loadString('assets/quran.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  return (data['surahs'] as List)
      .map((s) => Surah.fromJson(s as Map<String, dynamic>))
      .toList();
}

/// Tafsir (Ibn Kathir, abridged) is bundled per surah and loaded on demand
/// to keep startup fast. Results are cached for the app's lifetime.
final _tafsirCache = <int, Map<int, String>>{};

Future<Map<int, String>> loadTafsir(int surahNumber) async {
  if (_tafsirCache.containsKey(surahNumber)) {
    return _tafsirCache[surahNumber]!;
  }
  final raw = await rootBundle.loadString('assets/tafsir/$surahNumber.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final map = data.map((k, v) => MapEntry(int.parse(k), v as String));
  _tafsirCache[surahNumber] = map;
  return map;
}
