# Project Memory

Conventions, architectural decisions, and coding guidelines accumulated across sessions.

---

## Architecture

### State Management
The app uses **flutter_bloc ^9.0.0** with five Cubits (migrated from Provider in June 2026):

| Cubit | State | Responsibility |
|---|---|---|
| `PlaybackStateCubit` | `PlaybackState` | Currently playing song, playlist, shuffle, isPlaying |
| `AudioControlCubit` | `AudioControlState` | Playback position (`currentDuration`) and current index |
| `LibraryCubit` | `LibraryState` | Songs, albums, artists, genres, playlists, collections |
| `FavoritesCubit` | `FavoritesState` | Favorite songs list |
| `UICubit` | `UIState` | Dominant color, hero ID, color cache |

Barrel: `lib/cubits/cubits.dart`

Usage pattern: `context.watch<XCubit>().state` in `build()`, `context.read<XCubit>()` in callbacks and handlers.

---

## Coding Guidelines

### Extract handlers into named methods
`onTap`, `onPressed`, and similar callbacks must be named methods on the State/widget class. Never inline multi-line logic directly as a lambda in a widget property.

```dart
// Wrong
onTap: () async {
  final result = await someAsyncWork();
  // ... more lines
},

// Correct
onTap: _handleSomeTap,

Future<void> _handleSomeTap() async {
  final result = await someAsyncWork();
  // ...
}
```

**Why:** Keeps the build tree readable and handlers reusable.

**Rule:** Any handler longer than 1–2 lines becomes `_handleXxx()` or `_onXxxTap()`.

---

### Centralize utility/formatting logic
Never add helper or formatting functions as private methods on a widget or State class. Place them where the data lives:

| Logic type | Where it goes |
|---|---|
| Operates on a model field | Extension on that model (`SongFormat on SongModel`) |
| Formats a primitive type | Extension on that type (`int`, `String`, `Duration`) |
| No clear owner | `lib/extensions/format_extensions.dart` |

**Why:** Keeps widgets thin (build-only), makes utilities reusable, avoids duplication.

**Examples already in `format_extensions.dart`:**
- `Duration.timeString` — formats duration as `m:ss`
- `SongModel.songSubtitleText` — artist • duration subtitle
- `SongModel.audioFormatName` — maps file extension to codec name ("mp3" → "MPEG-1 Layer 3")
- `int.toTimestampString()` — formats Unix timestamp as "DD/MM/YYYY H:MM AM/PM"
- `List<SongModel>.totalDurationString()` — total playlist duration
