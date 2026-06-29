# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased] — 2026-06-28

### Added
- **Slide transition for the Now Playing screen.** `Helpers.slideUpRoute` opens
  `SongPlayedScreen` with a slide-up and closes it with a slide-down
  (`lib/helpers/helpers.dart`). Wired into both entry points
  (`lib/helpers/music_actions.dart`, `lib/widgets/current_song_tile.dart`).
- **Native dominant-color extraction.** New `queryArtworkColor(id, type)` in the
  `music_query_selector` plugin computes the artwork's dominant color natively
  (`androidx.palette` on Android, Core Image `CIAreaAverage` on iOS) and returns
  an ARGB int, avoiding a second image decode on the Dart side.
- **Native song deletion with the system dialog.** New `deleteSongs(ids)` in the
  plugin uses `MediaStore.createDeleteRequest` (Android 11+ confirmation dialog),
  `RecoverableSecurityException` (Android 10), and direct delete (≤9). On a
  confirmed delete the song is removed from the live queue and playback advances
  to the next track via `PlaybackService.removeFromQueue`.
- **Alphabet A–Z fast-scroll rail.** New `AlphabetScrollbar` widget
  (`lib/widgets/alphabet_scrollbar.dart`) on the Songs tab. Compact, vertically
  centered, auto-reveals while the list scrolls and fades out when idle. O(1)
  letter→position mapping and jump; only the active letter/bubble repaint.
- **Swipeable artwork carousel.** The Now Playing artwork is now a `PageView`
  over the current queue; swiping left/right changes the song, and external
  changes (next/prev, auto-advance) keep the carousel in sync.

### Changed
- **Songs are queried sorted by title** (`SongSortType.TITLE`) so the alphabet
  rail is meaningful (`lib/data/repositories/on_audio_query_repository.dart`).
- **Now Playing background** uses `ImageFiltered` (blurs the artwork image
  itself) instead of `BackdropFilter` (which sampled the live backdrop).
- **Dominant-color flow** (`UICubit.searchDominantColorByAlbumId`) now calls the
  native `queryArtworkColor` instead of reading the cached `.jpg` and running
  `PaletteGenerator`; the persisted hex cache and fast path are unchanged.
- **Removed the `palette_generator` dependency** (no longer used).
- **Delete flow** in `MoreSongOptionsModal` rewritten to the native dialog on
  Android (legacy file delete kept as a non-Android fallback); the app-owned
  album-art cache file is now deleted directly instead of via
  `manageExternalStorage`.

- **Custom search screen** (`lib/search/music_search_screen.dart`). Replaced the
  stock `SearchDelegate` subclass with a custom `StatefulWidget` (`MusicSearchScreen`)
  that matches the Muzio Player reference: a rounded pill field with an inline
  search icon and mic, an external "Cancel" button, and a transparent scaffold
  so the global `AppBackground` shows through. Entry points in `HomeScreen`,
  `AlbumSelectedScreen`, `ArtistSelectedScreen`, and `GenreSelectedScreen` all
  updated from `showSearch(delegate: ...)` to `Navigator.push(MaterialPageRoute(...))`.
  Old `search_delegate.dart` removed; file renamed to `music_search_screen.dart`.

### Fixed
- **Skip buttons caused a seek jump.** Tapping skip-next/previous fired an
  immediate ±10s scrub before the tap was recognized. The press-and-hold scrub
  now waits before its first seek (so a tap is a clean skip) and reads the live
  player position so holding scrubs progressively
  (`_MusicControls._whilePressed`).
- **Now Playing close showed a blue blurred background.** With the global
  `AppBackground` behind the Navigator and transparent scaffolds, the opaque
  route left the home screen offstage during the slide. Fixed with `opaque:
  false` plus a `FadeTransition` so the home screen is revealed through the
  closing screen.
- **Carousel selected the wrong song on tap (race condition).** A transient
  index emit from the player triggered a programmatic `animateToPage`, whose
  `onPageChanged` then seeked to the wrong song. `onPageChanged` now seeks only
  on a genuine user swipe (detected via `ScrollStartNotification.dragDetails`);
  programmatic/transient moves never seek.

---

### Plugin: `music_query_selector`

- **`queryArtworkColor(int id, ArtworkType type) → Future<int?>`** added across
  the federated plugin:
  - Android: `ArtworkColorQuery.kt` (`androidx.palette:palette-ktx`), routed via
    `Method.QUERY_ARTWORK_COLOR` / `MethodController`.
  - iOS: `ArtworkColorQuery.swift` (Core Image `CIAreaAverage`).
  - Dart: platform interface, method channel, and facade.
- **`deleteSongs(List<int> ids) → Future<bool>`** added:
  - Android: `DeleteController.kt` using `MediaStore.createDeleteRequest` with an
    `ActivityResultListener` registered in `MusicQuerySelectorPlugin`.
  - iOS: not supported (returns not-implemented; the app guards with
    `Platform.isAndroid`).
  - Dart: platform interface, method channel, and facade.
