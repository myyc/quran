import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran.dart';

enum ReadingMode { flow, verses, study }

class Bookmark {
  final int surah;
  final int ayah;
  final int createdAt;

  const Bookmark({
    required this.surah,
    required this.ayah,
    required this.createdAt,
  });

  String get key => '$surah:$ayah';

  Map<String, dynamic> toJson() => {'s': surah, 'a': ayah, 't': createdAt};

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    surah: json['s'] as int,
    ayah: json['a'] as int,
    createdAt: json['t'] as int,
  );
}

class AppState extends ChangeNotifier {
  static const _kMode = 'reading_mode';
  static const _kArabicSize = 'arabic_size';
  static const _kTranslationSize = 'translation_size';
  static const _kGreenDiacritics = 'green_diacritics';
  static const _kShowRecitationMarks = 'show_recitation_marks';
  static const _kTranslation = 'translation';
  static const _kLastSurah = 'last_surah';
  static const _kLastAyah = 'last_ayah';
  static const _kBookmarks = 'bookmarks';
  static const _kNotes = 'notes';
  static const _kProgress = 'progress';

  late SharedPreferences _prefs;

  List<Surah> surahs = [];
  bool ready = false;

  ReadingMode mode = ReadingMode.study;
  double arabicSize = 30;
  double translationSize = 15;
  bool greenDiacritics = false;
  bool showRecitationMarks = false;
  String translation = 'sahih';

  /// Updated on every scroll while reading. Kept out of [notifyListeners]
  /// so position tracking never rebuilds whole screens.
  final position = ValueNotifier<({int surah, int ayah})?>(null);

  /// Furthest ayah read per surah. Also a [ValueNotifier] for the same
  /// reason; only changes on forward progress.
  final progress = ValueNotifier<Map<int, int>>({});

  List<Bookmark> bookmarks = [];
  Map<String, String> notes = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    mode = ReadingMode.values[_prefs.getInt(_kMode) ?? ReadingMode.study.index];
    arabicSize = _prefs.getDouble(_kArabicSize) ?? 30;
    translationSize = _prefs.getDouble(_kTranslationSize) ?? 15;
    greenDiacritics = _prefs.getBool(_kGreenDiacritics) ?? false;
    showRecitationMarks = _prefs.getBool(_kShowRecitationMarks) ?? false;
    translation = _prefs.getString(_kTranslation) ?? 'sahih';
    if (_prefs.containsKey(_kLastSurah)) {
      position.value = (
        surah: _prefs.getInt(_kLastSurah)!,
        ayah: _prefs.getInt(_kLastAyah) ?? 1,
      );
    }
    bookmarks =
        (_prefs.getStringList(_kBookmarks) ?? [])
            .map(
              (s) => Bookmark.fromJson(jsonDecode(s) as Map<String, dynamic>),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notes = (jsonDecode(
      _prefs.getString(_kNotes) ?? '{}',
    ) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String));
    progress.value = (jsonDecode(
      _prefs.getString(_kProgress) ?? '{}',
    ) as Map<String, dynamic>).map((k, v) => MapEntry(int.parse(k), v as int));
    surahs = await loadQuran();
    ready = true;
    notifyListeners();
  }

  Surah surah(int number) => surahs[number - 1];

  double get khatamFraction {
    if (surahs.isEmpty) return 0;
    var read = 0;
    for (final s in surahs) {
      read += (progress.value[s.number] ?? 0).clamp(0, s.ayahCount);
    }
    return read / 6236;
  }

  /// First surah:ayah of each juz, for the juz index.
  List<({int juz, int surah, int ayah})> get juzStarts {
    final starts = <({int juz, int surah, int ayah})>[];
    for (var j = 1; j <= 30; j++) {
      outer:
      for (final s in surahs) {
        for (final a in s.ayahs) {
          if (a.juz == j) {
            starts.add((juz: j, surah: s.number, ayah: a.number));
            break outer;
          }
        }
      }
    }
    return starts;
  }

  /// First surah:ayah on a mushaf page, or null if the page is out of range.
  ({int surah, int ayah})? pageStart(int page) {
    for (final s in surahs) {
      for (final a in s.ayahs) {
        if (a.page == page) return (surah: s.number, ayah: a.number);
      }
    }
    return null;
  }

  Future<void> setMode(ReadingMode value) async {
    mode = value;
    await _prefs.setInt(_kMode, value.index);
    notifyListeners();
  }

  Future<void> setArabicSize(double value) async {
    arabicSize = value;
    await _prefs.setDouble(_kArabicSize, value);
    notifyListeners();
  }

  Future<void> setTranslationSize(double value) async {
    translationSize = value;
    await _prefs.setDouble(_kTranslationSize, value);
    notifyListeners();
  }

  Future<void> setGreenDiacritics(bool value) async {
    greenDiacritics = value;
    await _prefs.setBool(_kGreenDiacritics, value);
    notifyListeners();
  }

  Future<void> setShowRecitationMarks(bool value) async {
    showRecitationMarks = value;
    await _prefs.setBool(_kShowRecitationMarks, value);
    notifyListeners();
  }

  Future<void> setTranslation(String value) async {
    translation = value;
    await _prefs.setString(_kTranslation, value);
    notifyListeners();
  }

  void savePosition(int surahNumber, int ayahNumber) {
    final current = position.value;
    if (current == null ||
        current.surah != surahNumber ||
        current.ayah != ayahNumber) {
      position.value = (surah: surahNumber, ayah: ayahNumber);
      _prefs.setInt(_kLastSurah, surahNumber);
      _prefs.setInt(_kLastAyah, ayahNumber);
    }
    if ((progress.value[surahNumber] ?? 0) < ayahNumber) {
      progress.value = {...progress.value, surahNumber: ayahNumber};
      _prefs.setString(
        _kProgress,
        jsonEncode(progress.value.map((k, v) => MapEntry('$k', v))),
      );
    }
  }

  bool isBookmarked(int surah, int ayah) =>
      bookmarks.any((b) => b.surah == surah && b.ayah == ayah);

  Future<void> _saveBookmarks() => _prefs.setStringList(
    _kBookmarks,
    bookmarks.map((b) => jsonEncode(b.toJson())).toList(),
  );

  Future<void> toggleBookmark(int surah, int ayah) async {
    final existing = bookmarks.indexWhere(
      (b) => b.surah == surah && b.ayah == ayah,
    );
    if (existing >= 0) {
      bookmarks.removeAt(existing);
    } else {
      bookmarks.insert(
        0,
        Bookmark(
          surah: surah,
          ayah: ayah,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    await _saveBookmarks();
    notifyListeners();
  }

  String? noteFor(int surah, int ayah) => notes['$surah:$ayah'];

  Future<void> setNote(int surah, int ayah, String text) async {
    final key = '$surah:$ayah';
    if (text.trim().isEmpty) {
      notes.remove(key);
    } else {
      notes[key] = text.trim();
    }
    await _prefs.setString(_kNotes, jsonEncode(notes));
    notifyListeners();
  }

  Future<void> removeNote(int surah, int ayah) => setNote(surah, ayah, '');

  Map<String, dynamic> exportData() => {
    'app': 'dev.myyc.quran',
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
    'notes': notes,
    'progress': progress.value.map((k, v) => MapEntry('$k', v)),
    'position': position.value == null
        ? null
        : {'surah': position.value!.surah, 'ayah': position.value!.ayah},
    'settings': {
      'mode': mode.index,
      'arabicSize': arabicSize,
      'translationSize': translationSize,
      'greenDiacritics': greenDiacritics,
      'showRecitationMarks': showRecitationMarks,
      'translation': translation,
    },
  };

  Future<void> importData(Map<String, dynamic> data) async {
    if (data['bookmarks'] is List) {
      bookmarks =
          (data['bookmarks'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Bookmark.fromJson)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveBookmarks();
    }
    if (data['notes'] is Map) {
      notes = (data['notes'] as Map).map((k, v) => MapEntry('$k', '$v'));
      await _prefs.setString(_kNotes, jsonEncode(notes));
    }
    if (data['progress'] is Map) {
      progress.value = (data['progress'] as Map).map(
        (k, v) => MapEntry(int.parse('$k'), (v as num).toInt()),
      );
      await _prefs.setString(
        _kProgress,
        jsonEncode(progress.value.map((k, v) => MapEntry('$k', v))),
      );
    }
    if (data['position'] is Map) {
      final p = data['position'] as Map;
      savePosition((p['surah'] as num).toInt(), (p['ayah'] as num).toInt());
    }
    final settings = data['settings'];
    if (settings is Map) {
      if (settings['mode'] is num) {
        mode = ReadingMode.values[(settings['mode'] as num).toInt()];
        await _prefs.setInt(_kMode, mode.index);
      }
      if (settings['arabicSize'] is num) {
        arabicSize = (settings['arabicSize'] as num).toDouble();
        await _prefs.setDouble(_kArabicSize, arabicSize);
      }
      if (settings['translationSize'] is num) {
        translationSize = (settings['translationSize'] as num).toDouble();
        await _prefs.setDouble(_kTranslationSize, translationSize);
      }
      if (settings['greenDiacritics'] is bool) {
        greenDiacritics = settings['greenDiacritics'] as bool;
        await _prefs.setBool(_kGreenDiacritics, greenDiacritics);
      }
      if (settings['showRecitationMarks'] is bool) {
        showRecitationMarks = settings['showRecitationMarks'] as bool;
        await _prefs.setBool(_kShowRecitationMarks, showRecitationMarks);
      }
      if (translationEditions.containsKey(settings['translation'])) {
        translation = settings['translation'] as String;
        await _prefs.setString(_kTranslation, translation);
      }
    }
    notifyListeners();
  }
}
