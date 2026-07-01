# Isolates Analysis — Music Player App

## Why Isolates?

Dart is single-threaded by default. Flutter's UI engine needs the main isolate free to render frames at 60/120 fps. When CPU-bound work lands on the main isolate, frames are skipped and the app jank. `Isolate.run()` (Dart 3 / Flutter 3.7+) spawns a short-lived background isolate, runs a closure there, returns the result to the main isolate, and disposes itself — no boilerplate required.

**Rule of thumb used here:** isolate only CPU work (parsing, filtering, sorting, encoding). Never platform channels — `SharedPreferences.setString`, `on_audio_query`, artwork generation — these must stay on the main isolate.

---

## Where Isolates Were Applied

### 1 · `LibraryState.searchAsync()` — per-keystroke search

**File:** `lib/cubits/library/library_state.dart`

**Problem:** `searchByQuery()` runs three synchronous `.where()` + `.toLowerCase().contains()` scans over the full `songList`, `albumList`, and `artistList` on every keystroke. At 5,000 songs + 200 albums + 300 artists this is measurably slow.

**Fix:** New `static Future<MultipleSearchModel> searchAsync(...)` method offloads all three filter passes to `Isolate.run()`. The call site (`music_search_screen.dart`) debounces keystrokes at 150 ms, cancels stale results via `query != _query` guard, and stores results in `_searchResult` state.

**Algorithm complexity:** unchanged O(n) per collection, but now off the main thread.

---

### 2 · `FavoritesCubit.initFavorites()` — startup hydration

**File:** `lib/cubits/favorites/favorites_cubit.dart`

**Problem:** O(n × m) — for each of the n saved favorite IDs it did a full linear `indexWhere` scan over all m songs. 100 favorites × 5,000 songs = 500,000 comparisons on startup, synchronously, before the first frame.

**Fix:** Converted to `Future<void>`, moved work to `Isolate.run()`, and changed the algorithm to O(n + m) by building a HashMap (`{for (final s in allSongs) s.id: s}`) inside the isolate. `LibraryCubit.onSongsLoaded` callback type updated to `Future<void> Function(...)` and the call site now `await`s it.

**Algorithm improvement:** O(n × m) → O(n + m).

---

### 3 · `LibraryCubit.searchByArtistId()` — artist content building

**File:** `lib/cubits/library/library_cubit.dart`

**Problem:** Two issues compounding each other:
- Linear scan over `songList` to find the artist's songs (O(n))
- Album lookup used `albumList.firstWhere()` inside a loop — O(k × m) where k = artist's songs, m = total albums

**Fix:** Converted to `Future<void>`, moved all filtering / sorting / album-lookup into `Isolate.run()`. Album lookup switched to a HashMap (`{for (final a in allAlbums) a.id: a}`) — one build pass, then O(1) per lookup. `artist_selected_screen.dart` updated to `await` the call and guard `setState` with `mounted`.

**Algorithm improvement:** O(k × m) → O(k + m) for album resolution.

---

## Bonus: In-memory Cache for `dominantColorCollection`

**Files:** `lib/data/repositories/shared_preferences_repository.dart`, `lib/share_prefs/user_preferences.dart`

**Problem (not a CPU problem — a repeated I/O problem):** The `dominantColorCollection` getter calls `json.decode()` on the full album-color JSON blob every time `UICubit` reacts to a song change. On frequent track skips this decoded the same string repeatedly, allocating new maps each time.

**Fix:** Added `Map<String, String>? _colorCache` in `SharedPreferencesRepository`. Getter uses `??=` — decode once, serve from memory. Setter updates the cache immediately then offloads `json.encode()` to `Isolate.run()`, calling back to `UserPreferences.setRawDominantColor()` (bypasses re-encoding) on the main isolate once serialization is done. The setter call (new color discovered) is rare; the getter call (every song change) is frequent — caching the getter is the high-value fix.

---

## What Was NOT Isolated (and Why)

| Location | Reason skipped |
|---|---|
| `getAllSongs()` | Pure platform-channel I/O — channels must be called from the main isolate; already async and I/O-bound |
| `searchByAlbumId()` | O(n) scan over typically ≤ 200 albums; isolate spawn overhead > computation |
| `buildArtworkCache()` | `queryArtwork()` is a platform channel — cannot be moved to an isolate |
| `totalDurationString()` | O(n) fold on a sub-list; trivially fast at any real library size |

---

## Verification Checklist

1. `flutter analyze --no-pub` — zero issues.
2. Open search screen, type rapidly — results appear ~150 ms after the last keystroke with no UI jank.
3. Cold-launch with 100+ saved favorites — first frame renders before favorites finish hydrating (they arrive asynchronously via `emit`).
4. Navigate to a prolific artist for the first time — screen transition is smooth; songs/albums populate shortly after via `context.watch`.
5. Skip songs rapidly — dominant color updates instantly (cache hit on getter); JSON write is fire-and-forget in background.
