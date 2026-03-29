// lib/services/database_service.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'music_player.db'),
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> init() async {
    await db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE playlists (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        name     TEXT    NOT NULL,
        song_ids TEXT    NOT NULL DEFAULT '',
        created_at TEXT  NOT NULL,
        updated_at TEXT  NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        song_id  INTEGER PRIMARY KEY,
        added_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ─── Playlists ───────────────────────────────────────────────
  Future<List<Playlist>> getPlaylists() async {
    final d = await db;
    final rows = await d.query('playlists', orderBy: 'name ASC');
    return rows.map(Playlist.fromMap).toList();
  }

  Future<Playlist> createPlaylist(String name) async {
    final d = await db;
    final now = DateTime.now().toIso8601String();
    final p = Playlist(name: name, createdAt: DateTime.now());
    final id = await d.insert('playlists', {
      'name': name,
      'song_ids': '',
      'created_at': now,
      'updated_at': now,
    });
    return p.copyWith()..songIds.clear();
    // Return with proper id
    final row = await d.query('playlists', where: 'id = ?', whereArgs: [id]);
    return Playlist.fromMap(row.first);
  }

  Future<Playlist> savePlaylist(Playlist playlist) async {
    final d = await db;
    final updated = playlist.copyWith();
    if (playlist.id == null) {
      final id = await d.insert('playlists', updated.toMap());
      final row =
          await d.query('playlists', where: 'id = ?', whereArgs: [id]);
      return Playlist.fromMap(row.first);
    } else {
      await d.update('playlists', updated.toMap(),
          where: 'id = ?', whereArgs: [playlist.id]);
      return updated;
    }
  }

  Future<void> deletePlaylist(int id) async {
    final d = await db;
    await d.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> renamePlaylist(int id, String name) async {
    final d = await db;
    await d.update(
      'playlists',
      {'name': name, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updatePlaylistSongs(int id, List<int> songIds) async {
    final d = await db;
    await d.update(
      'playlists',
      {
        'song_ids': songIds.join(','),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Favorites ───────────────────────────────────────────────
  Future<Set<int>> getFavoriteIds() async {
    final d = await db;
    final rows = await d.query('favorites');
    return rows.map((r) => r['song_id'] as int).toSet();
  }

  Future<void> addFavorite(int songId) async {
    final d = await db;
    await d.insert(
      'favorites',
      {
        'song_id': songId,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeFavorite(int songId) async {
    final d = await db;
    await d.delete('favorites', where: 'song_id = ?', whereArgs: [songId]);
  }

  // ─── Settings ────────────────────────────────────────────────
  Future<String?> getSetting(String key) async {
    final d = await db;
    final rows =
        await d.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final d = await db;
    await d.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
