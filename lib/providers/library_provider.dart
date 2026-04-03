// // lib/providers/library_provider.dart
// import 'package:flutter/foundation.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:permission_handler/permission_handler.dart';
// import '../models/models.dart';
// import '../services/database_service.dart';

// enum LibraryState { initial, loading, ready, error, noPermission }

// class LibraryProvider extends ChangeNotifier {
//   final _audioQuery = OnAudioQuery();
//   final _db = DatabaseService.instance;

//   LibraryState _state = LibraryState.initial;
//   LibraryState get state => _state;

//   String _error = '';
//   String get error => _error;

//   // ─── Raw collections ─────────────────────────────────────────
//   List<Song> _songs = [];
//   List<Album> _albums = [];
//   List<Artist> _artists = [];
//   List<String> _genres = [];

//   List<Song> get songs => _filteredSongs ?? _songs;
//   List<Album> get albums => _albums;
//   List<Artist> get artists => _artists;
//   List<String> get genres => _genres;

//   // ─── Favorites ───────────────────────────────────────────────
//   Set<int> _favoriteIds = {};
//   Set<int> get favoriteIds => _favoriteIds;
//   List<Song> get favorites =>
//       _songs.where((s) => _favoriteIds.contains(s.id)).toList();

//   // ─── Search / Filter ─────────────────────────────────────────
//   String _searchQuery = '';
//   String get searchQuery => _searchQuery;
//   List<Song>? _filteredSongs;

//   void setSearch(String query) {
//     _searchQuery = query;
//     if (query.trim().isEmpty) {
//       _filteredSongs = null;
//     } else {
//       final q = query.toLowerCase();
//       _filteredSongs = _songs
//           .where((s) =>
//               s.title.toLowerCase().contains(q) ||
//               s.artist.toLowerCase().contains(q) ||
//               s.album.toLowerCase().contains(q))
//           .toList();
//     }
//     notifyListeners();
//   }

//   List<Song> songsForAlbum(int albumId) =>
//       _songs.where((s) => s.albumId == albumId).toList();

//   List<Song> songsForArtist(int artistId) =>
//       _songs.where((s) => s.artistId == artistId).toList();

//   List<Song> songsForGenre(String genre) =>
//       _songs.where((s) => s.genre == genre).toList();

//   List<Song> songsById(List<int> ids) {
//     final map = {for (var s in _songs) s.id: s};
//     return ids.map((id) => map[id]).whereType<Song>().toList();
//   }

//   // ─── Permission & Init ───────────────────────────────────────
//   Future<bool> requestPermission() async {
//     final status = defaultTargetPlatform == TargetPlatform.android
//         ? await Permission.audio.request()
//         : PermissionStatus.granted;

//     if (status.isGranted) return true;

//     // Fallback for older Android
//     final storage = await Permission.storage.request();
//     return storage.isGranted;
//   }

//   Future<void> init() async {
//     _state = LibraryState.loading;
//     notifyListeners();

//     final hasPermission = await requestPermission();
//     if (!hasPermission) {
//       _state = LibraryState.noPermission;
//       notifyListeners();
//       return;
//     }

//     await scanLibrary();
//   }

//   Future<void> scanLibrary() async {
//     try {
//       _state = LibraryState.loading;
//       notifyListeners();

//       // Load favorites from DB
//       _favoriteIds = await _db.getFavoriteIds();

//       // Query songs
//       final songModels = await _audioQuery.querySongs(
//         sortType: SongSortType.TITLE,
//         orderType: OrderType.ASC_OR_SMALLER,
//         uriType: UriType.EXTERNAL,
//         ignoreCase: true,
//       );

//       _songs = songModels
//           .where((m) => (m.duration ?? 0) > 10000) // skip <10s
//           .map((m) {
//             final s = Song.fromModel(m);
//             return s.copyWith(isFavorite: _favoriteIds.contains(s.id));
//           })
//           .toList();

//       // Query albums
//       final albumModels = await _audioQuery.queryAlbums(
//         sortType: AlbumSortType.ALBUM,
//         orderType: OrderType.ASC_OR_SMALLER,
//       );
//       _albums = albumModels.map(Album.fromModel).toList();

//       // Query artists
//       final artistModels = await _audioQuery.queryArtists(
//         sortType: ArtistSortType.ARTIST,
//         orderType: OrderType.ASC_OR_SMALLER,
//       );
//       _artists = artistModels.map(Artist.fromModel).toList();

//       // Extract genres
//       _genres = _songs
//           .map((s) => s.genre)
//           .whereType<String>()
//           .toSet()
//           .toList()
//         ..sort();

//       _state = LibraryState.ready;
//     } catch (e) {
//       _error = e.toString();
//       _state = LibraryState.error;
//     } finally {
//       notifyListeners();
//     }
//   }

//   // ─── Favorites ───────────────────────────────────────────────
//   Future<void> toggleFavorite(Song song) async {
//     if (_favoriteIds.contains(song.id)) {
//       _favoriteIds.remove(song.id);
//       await _db.removeFavorite(song.id);
//     } else {
//       _favoriteIds.add(song.id);
//       await _db.addFavorite(song.id);
//     }
//     // Reflect in songs list
//     final idx = _songs.indexWhere((s) => s.id == song.id);
//     if (idx >= 0) {
//       _songs[idx] = _songs[idx].copyWith(
//         isFavorite: _favoriteIds.contains(song.id),
//       );
//     }
//     notifyListeners();
//   }

//   bool isFavorite(int songId) => _favoriteIds.contains(songId);
// }

// lib/providers/library_provider.dart
import 'dart:io'; // NEW: For reading file paths
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEW: For saving folder preferences

import '../models/models.dart';
import '../services/database_service.dart';

enum LibraryState { initial, loading, ready, error, noPermission }

class LibraryProvider extends ChangeNotifier {
  final _audioQuery = OnAudioQuery();
  final _db = DatabaseService.instance;

  LibraryState _state = LibraryState.initial;
  LibraryState get state => _state;

  String _error = '';
  String get error => _error;

  // ─── Raw collections ─────────────────────────────────────────
  List<Song> _songs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<String> _genres = [];

  List<Song> get songs => _filteredSongs ?? _songs;
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;
  List<String> get genres => _genres;

  // ─── NEW: Folder Filtering Variables ─────────────────────────
  List<String> _allowedFolders = [];
  List<String> get allowedFolders => _allowedFolders;

  List<String> _allAvailableFolders = [];
  List<String> get allAvailableFolders => _allAvailableFolders;

  // ─── Favorites ───────────────────────────────────────────────
  Set<int> _favoriteIds = {};
  Set<int> get favoriteIds => _favoriteIds;
  List<Song> get favorites =>
      _songs.where((s) => _favoriteIds.contains(s.id)).toList();

  // ─── Search / Filter ─────────────────────────────────────────
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  List<Song>? _filteredSongs;

  void setSearch(String query) {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _filteredSongs = null;
    } else {
      final q = query.toLowerCase();
      _filteredSongs = _songs
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q) ||
              s.album.toLowerCase().contains(q))
          .toList();
    }
    notifyListeners();
  }

  List<Song> songsForAlbum(int albumId) =>
      _songs.where((s) => s.albumId == albumId).toList();

  List<Song> songsForArtist(int artistId) =>
      _songs.where((s) => s.artistId == artistId).toList();

  List<Song> songsForGenre(String genre) =>
      _songs.where((s) => s.genre == genre).toList();

  List<Song> songsById(List<int> ids) {
    final map = {for (var s in _songs) s.id: s};
    return ids.map((id) => map[id]).whereType<Song>().toList();
  }

  // ─── Permission & Init ───────────────────────────────────────
  Future<bool> requestPermission() async {
    final status = defaultTargetPlatform == TargetPlatform.android
        ? await Permission.audio.request()
        : PermissionStatus.granted;

    if (status.isGranted) return true;

    // Fallback for older Android
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<void> init() async {
    _state = LibraryState.loading;
    notifyListeners();

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      _state = LibraryState.noPermission;
      notifyListeners();
      return;
    }

    await scanLibrary();
  }

  Future<void> scanLibrary() async {
    try {
      _state = LibraryState.loading;
      notifyListeners();

      // Load favorites from DB
      _favoriteIds = await _db.getFavoriteIds();
      
      // NEW: Load folder preferences
      final prefs = await SharedPreferences.getInstance();
      _allowedFolders = prefs.getStringList('allowed_folders') ?? [];

      // Query songs
      var songModels = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      // NEW: Extract all unique folders from the raw device scan
      Set<String> folders = {};
      for (var m in songModels) {
        folders.add(File(m.data).parent.path);
      }
      _allAvailableFolders = folders.toList()..sort();

      // NEW: Filter songModels if user has selected specific folders
      if (_allowedFolders.isNotEmpty) {
        songModels = songModels.where((m) {
          final parentPath = File(m.data).parent.path;
          return _allowedFolders.contains(parentPath);
        }).toList();
      }

      // Convert filtered raw models into your custom Song models
      _songs = songModels
          .where((m) => (m.duration ?? 0) > 10000) // skip <10s
          .map((m) {
            final s = Song.fromModel(m);
            return s.copyWith(isFavorite: _favoriteIds.contains(s.id));
          })
          .toList();

      // Query albums
      final albumModels = await _audioQuery.queryAlbums(
        sortType: AlbumSortType.ALBUM,
        orderType: OrderType.ASC_OR_SMALLER,
      );
      // NEW: Only map albums that actually contain our filtered songs
      _albums = albumModels
          .map(Album.fromModel)
          .where((a) => _songs.any((s) => s.albumId == a.id))
          .toList();

      // Query artists
      final artistModels = await _audioQuery.queryArtists(
        sortType: ArtistSortType.ARTIST,
        orderType: OrderType.ASC_OR_SMALLER,
      );
      // NEW: Only map artists that actually have filtered songs
      _artists = artistModels
          .map(Artist.fromModel)
          .where((ar) => _songs.any((s) => s.artistId == ar.id))
          .toList();

      // Extract genres
      _genres = _songs
          .map((s) => s.genre)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();

      _state = LibraryState.ready;
    } catch (e) {
      _error = e.toString();
      _state = LibraryState.error;
    } finally {
      notifyListeners();
    }
  }

  // ─── Favorites ───────────────────────────────────────────────
  Future<void> toggleFavorite(Song song) async {
    if (_favoriteIds.contains(song.id)) {
      _favoriteIds.remove(song.id);
      await _db.removeFavorite(song.id);
    } else {
      _favoriteIds.add(song.id);
      await _db.addFavorite(song.id);
    }
    // Reflect in songs list
    final idx = _songs.indexWhere((s) => s.id == song.id);
    if (idx >= 0) {
      _songs[idx] = _songs[idx].copyWith(
        isFavorite: _favoriteIds.contains(song.id),
      );
    }
    notifyListeners();
  }

  bool isFavorite(int songId) => _favoriteIds.contains(songId);

  // ─── NEW: Folder Management ──────────────────────────────────
  Future<void> toggleFolder(String folderPath, bool allow) async {
    if (allow) {
      if (!_allowedFolders.contains(folderPath)) {
        _allowedFolders.add(folderPath);
      }
    } else {
      _allowedFolders.remove(folderPath);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('allowed_folders', _allowedFolders);

    await scanLibrary(); // Re-scan to apply UI changes
  }
}