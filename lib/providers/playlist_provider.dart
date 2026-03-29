// lib/providers/playlist_provider.dart
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class PlaylistProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;

  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _playlists = await _db.getPlaylists();
    _loaded = true;
    notifyListeners();
  }

  Future<void> reload() async {
    _playlists = await _db.getPlaylists();
    notifyListeners();
  }

  // ─── CRUD ────────────────────────────────────────────────────
  Future<Playlist> create(String name) async {
    final now = DateTime.now().toIso8601String();
    final p = Playlist(name: name);
    final saved = await _db.savePlaylist(p);
    _playlists.add(saved);
    notifyListeners();
    return saved;
  }

  Future<void> rename(int id, String name) async {
    await _db.renamePlaylist(id, name);
    final idx = _playlists.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      _playlists[idx].name = name;
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    await _db.deletePlaylist(id);
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ─── Song management ─────────────────────────────────────────
  Future<void> addSong(int playlistId, int songId) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return;
    if (_playlists[idx].songIds.contains(songId)) return;
    _playlists[idx].songIds.add(songId);
    await _db.updatePlaylistSongs(playlistId, _playlists[idx].songIds);
    notifyListeners();
  }

  Future<void> removeSong(int playlistId, int songId) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return;
    _playlists[idx].songIds.remove(songId);
    await _db.updatePlaylistSongs(playlistId, _playlists[idx].songIds);
    notifyListeners();
  }

  Future<void> reorderSongs(int playlistId, int oldIndex, int newIndex) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return;
    final ids = List<int>.from(_playlists[idx].songIds);
    final item = ids.removeAt(oldIndex);
    ids.insert(newIndex, item);
    _playlists[idx].songIds = ids;
    await _db.updatePlaylistSongs(playlistId, ids);
    notifyListeners();
  }

  Future<void> addSongs(int playlistId, List<int> songIds) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return;
    for (final id in songIds) {
      if (!_playlists[idx].songIds.contains(id)) {
        _playlists[idx].songIds.add(id);
      }
    }
    await _db.updatePlaylistSongs(playlistId, _playlists[idx].songIds);
    notifyListeners();
  }

  bool containsSong(int playlistId, int songId) {
    final p = _playlists.firstWhere((p) => p.id == playlistId,
        orElse: () => Playlist(name: ''));
    return p.songIds.contains(songId);
  }

  Playlist? getById(int id) {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
