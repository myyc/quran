# AGENTS.md

Guidance for AI agents working on this repo. **Pledge: any change that alters
documented behavior, structure, data, or workflow must update this file in the
same change.**

## Project

Quran reading app (`dev.myyc.quran`), Flutter, **Android only**, offline-first.
Flat UI: pure black `#000000`, accent `#009E49` (`QColors.accent`), accent text
`#2CC36B`. Fonts bundled in `assets/fonts`: Inter (UI), AmiriQuran (ayah text),
ReemKufi (surah names).

## Commands

- Deps: `flutter pub get`
- Analyze: `flutter analyze` (must stay clean)
- Test: `flutter test`
- Format: `dart format lib test`
- Release: `flutter build apk --release` (signed with production key)
- Debug install over release without data loss: `flutter build apk --debug` —
  the debug build type is also signed with the release key on purpose.
- Regenerate data: `uv run --no-project tool/build_assets.py`
  (use `uv` for everything Python; raw downloads live in `tool/raw`, not committed)
- Send build to the user's phone: `lfx <apk> "caption"` (their custom tool)

## Data

`tool/build_assets.py` merges sources into `assets/quran.json`
(114 surahs, 6236 ayat: Arabic Uthmani, 4 translations, juz, mushaf page,
sajda) plus per-surah `assets/tafsir/<n>.json` (Ibn Kathir abridged, loaded
lazily via `loadTafsir` to keep startup fast).

Sources: alquran.cloud (`quran-uthmani`, `en.sahih`, `en.pickthall`,
`en.yusufali`), fawazahmed0/quran-api (`eng-mustafakhattaba`),
spa5k/tafsir_api (`en-tafisr-ibn-kathir`).

The basmala is stripped from ayah 1 of every surah except 1 and 9 (surahs 95
and 97 use a shadda variant) and rendered in the surah header instead.
Waqf/recitation marks (U+06D6–06DC, U+06E9) are hidden by default
(`showRecitationMarks`); copy/share always uses the full original text.

## Structure

- `lib/models/quran.dart` — Surah/Ayah, `translationEditions`, asset loading
- `lib/state/app_state.dart` — all persisted state (shared_preferences)
- `lib/screens/` — home shell (bottom nav), surah list (+juz index), reader,
  search, saved, settings
- `lib/widgets/quran_text.dart` — vocalisation/diacritic spans, mark stripping
- `lib/utils/arabic.dart` — Arabic search normalisation

## Conventions

- **High-frequency state** (reading position, per-surah progress) lives in
  `ValueNotifier`s, NOT `notifyListeners()` — full-screen rebuilds on scroll
  caused jank once already. Settings-grade state uses `notifyListeners()`.
- Flow mode is one continuous `RichText` per surah; ayah taps use
  `TapGestureRecognizer`s (disposed properly) and jump/position uses caret
  offsets from `RenderParagraph`. Offsets must be computed from the same
  (possibly mark-stripped) text that is rendered.
- Do not bump the version in `pubspec.yaml` unless the user asks.
- Release/debug keystore: `android/app/quran-release.keystore`, credentials in
  `android/key.properties` — both gitignored, never commit them.
- Match the existing flat aesthetic: no rounded corners, no elevation, hairline
  rules only where they earn their place.
