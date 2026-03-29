# 🎵 Music Player — Advanced Flutter App

A **fully offline, local music player** built with Flutter, featuring Material Design 3, dynamic album art theming, background playback, a 5-band EQ, and a complete media library.

---

## ✨ Features

| Category | Details |
|----------|---------|
| **Playback** | Play/Pause, Next/Prev, Seek, Shuffle, Repeat (None/All/One) |
| **Background Audio** | Lock screen controls, OS notification player |
| **Gapless Playback** | `ConcatenatingAudioSource` via `just_audio` |
| **Equalizer** | 5-band EQ (60Hz–14kHz) with 8 presets + Bass Boost |
| **Dynamic Theming** | Palette extraction from album art → Material You ColorScheme |
| **Dark/Light Mode** | System-aware + manual override |
| **Library** | Songs, Albums, Artists, Genres; full ID3 tag extraction |
| **Playlists** | Create, rename, delete, reorder (drag), add/remove songs |
| **Favorites** | Heart any song; dedicated Favorites screen |
| **Search** | Full-text search across title, artist, album |
| **Queue Management** | View, reorder, remove from current queue |
| **Mini Player** | Persistent bottom bar with Hero animation to full screen |
| **Sleep Timer** | Auto-stop after 15/30/45/60 min |

---

## 📁 Project Structure

```
lib/
├── main.dart                  # Entry point + AudioService init
├── app.dart                   # MaterialApp + DynamicColorBuilder
├── models/
│   └── models.dart            # Song, Album, Artist, Playlist
├── services/
│   ├── audio_handler.dart     # MusicAudioHandler (just_audio + audio_service)
│   └── database_service.dart  # SQLite — playlists & favorites
├── providers/
│   ├── audio_provider.dart    # Playback state & controls
│   ├── library_provider.dart  # Device media scanning
│   ├── playlist_provider.dart # Playlist CRUD
│   └── theme_provider.dart    # Dark/light + dynamic color
├── screens/
│   ├── home_screen.dart       # Bottom nav shell
│   ├── songs_screen.dart      # All songs list
│   ├── albums_screen.dart     # Albums grid + detail
│   ├── artists_screen.dart    # Artists list + detail
│   ├── playlists_screen.dart  # Playlists + Favorites
│   ├── now_playing_screen.dart# Full-screen player + Queue tab
│   └── settings_screen.dart   # Theme, EQ, library rescan
├── widgets/
│   ├── song_tile.dart         # Reusable song row with options
│   ├── mini_player.dart       # Persistent bottom player bar
│   └── equalizer_widget.dart  # 5-band EQ sliders + presets
└── utils/
    └── extensions.dart        # Duration formatting, string helpers
```

---

## 🚀 Setup & Installation

### Prerequisites
- **Flutter** ≥ 3.10 (run `flutter --version`)
- **Android Studio** or **VS Code** with Flutter plugin
- Android device/emulator with **API 21+** (Android 5.0+)

### Steps

```bash
# 1. Get dependencies
flutter pub get

# 2. Run on connected Android device
flutter run

# 3. Build release APK
flutter build apk --release
```

> **iOS**: Add `NSAppleMusicUsageDescription` in `ios/Runner/Info.plist` and configure audio session in Xcode. The `on_audio_query` package supports iOS 9+.

---

## 🔑 Permissions

| Permission | Purpose |
|-----------|---------|
| `READ_MEDIA_AUDIO` | Android 13+ media access |
| `READ_EXTERNAL_STORAGE` | Android 12 and below |
| `WAKE_LOCK` | Keep CPU on during background playback |
| `FOREGROUND_SERVICE` | Background audio service |

---

## 🎛️ Architecture Decisions

### Audio Stack
- **`just_audio`** handles decoding and gapless `ConcatenatingAudioSource` playback.
- **`audio_service`** wraps it in a `BaseAudioHandler` that bridges to Android's `MediaSession` — giving you notification controls, lock screen, Bluetooth headset buttons, and Android Auto compatibility.
- **`audio_session`** configures the `AudioFocus` policy (pauses on phone calls, ducks for navigation prompts).

### State Management
- **Provider** pattern: `AudioProvider`, `LibraryProvider`, `PlaylistProvider`, `ThemeProvider`.
- All providers are injected at `main()` via `MultiProvider` so any widget in the tree can `context.watch/read` them.

### Persistence
- **SQLite via `sqflite`**: Stores playlists (with ordered song ID lists) and favorites.
- **SharedPreferences**: EQ band values, enabled state, theme mode selection.

### Dynamic Theming
- `palette_generator` extracts the dominant color from the current album art's `MemoryImage`.
- A `ColorScheme.fromSeed(seedColor: dominant)` is generated and applied live via `ThemeProvider`.
- Falls back to the system Material You colors (via `dynamic_color`) or a default purple seed.

---

## 🔧 Extending the App

### Real hardware Equalizer
The `equalizer_widget.dart` provides the UI and persists band values. To connect to the actual Android `AudioEffect` API:
1. Add `equalizer_flutter: ^1.0.0` to `pubspec.yaml`.
2. In `audio_handler.dart`, after `_player.setAudioSource(...)` get the `_player.androidAudioSessionId` and pass it to `Equalizer.open(priority: 0, audioSession: id)`.

### Crossfade
Implement a second `AudioPlayer` in `audio_handler.dart`. Listen to `_player.positionStream` and when `remaining < crossfadeDuration`, start the secondary player and fade volumes with `setVolume()` using a `Timer`.

### Lyrics
Integrate the `lrc` package or parse `.lrc` files alongside audio files. Display in a new `LyricsTab` in `NowPlayingScreen`.

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `just_audio` | ^0.9.36 | Audio playback engine |
| `audio_service` | ^0.18.12 | OS media integration |
| `audio_session` | ^0.1.18 | Audio focus management |
| `on_audio_query` | ^2.9.0 | Device library scanning + artwork |
| `provider` | ^6.1.1 | State management |
| `palette_generator` | ^0.3.3 | Album art color extraction |
| `dynamic_color` | ^1.6.8 | Material You system colors |
| `sqflite` | ^2.3.0 | SQLite database |
| `shared_preferences` | ^2.2.2 | Key-value settings |
| `permission_handler` | ^11.1.0 | Runtime permissions |
| `rxdart` | ^0.27.7 | Reactive position streams |

---

## 📄 License
MIT — free to use, modify, and distribute.
