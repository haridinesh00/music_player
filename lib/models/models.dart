// lib/models/models.dart
// Barrel file + all data models

import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';

// ─────────────────────────────────────────
//  Song
// ─────────────────────────────────────────
class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String? genre;
  final String data; // full file path
  final int duration; // ms
  final int? albumId;
  final int? artistId;
  bool isFavorite;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.genre,
    required this.data,
    required this.duration,
    this.albumId,
    this.artistId,
    this.isFavorite = false,
  });

  factory Song.fromModel(SongModel m) => Song(
        id: m.id,
        title: m.title,
        artist: m.artist ?? 'Unknown Artist',
        album: m.album ?? 'Unknown Album',
        genre: m.genre,
        data: m.data,
        duration: m.duration ?? 0,
        albumId: m.albumId,
        artistId: m.artistId,
      );

  MediaItem toMediaItem() => MediaItem(
        id: data,
        title: title,
        artist: artist,
        album: album,
        duration: Duration(milliseconds: duration),
        artUri: Uri.parse('content://media/external/audio/media/$id/albumart'),
        extras: {'songId': id, 'albumId': albumId},
      );

  Song copyWith({bool? isFavorite}) => Song(
        id: id,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        data: data,
        duration: duration,
        albumId: albumId,
        artistId: artistId,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  @override
  bool operator ==(Object other) => other is Song && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────
//  Album
// ─────────────────────────────────────────
class Album {
  final int id;
  final String title;
  final String artist;
  final int songCount;
  final int? firstYear;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.songCount,
    this.firstYear,
  });

  factory Album.fromModel(AlbumModel m) => Album(
        id: m.id,
        title: m.album,
        artist: m.artist ?? 'Unknown Artist',
        songCount: m.numOfSongs,
        // firstYear: m.firstYear,
      );
}

// ─────────────────────────────────────────
//  Artist
// ─────────────────────────────────────────
class Artist {
  final int id;
  final String name;
  final int numberOfTracks;
  final int numberOfAlbums;

  Artist({
    required this.id,
    required this.name,
    required this.numberOfTracks,
    required this.numberOfAlbums,
  });

  factory Artist.fromModel(ArtistModel m) => Artist(
        id: m.id,
        name: m.artist,
        numberOfTracks: m.numberOfTracks ?? 0,
        numberOfAlbums: m.numberOfAlbums ?? 0,
      );
}

// ─────────────────────────────────────────
//  Playlist
// ─────────────────────────────────────────
class Playlist {
  final int? id;
  String name;
  List<int> songIds;
  final DateTime createdAt;
  DateTime updatedAt;

  Playlist({
    this.id,
    required this.name,
    List<int>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : songIds = songIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Playlist.fromMap(Map<String, dynamic> m) => Playlist(
        id: m['id'] as int,
        name: m['name'] as String,
        songIds: (m['song_ids'] as String?)
                ?.split(',')
                .where((s) => s.isNotEmpty)
                .map(int.parse)
                .toList() ??
            [],
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'song_ids': songIds.join(','),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Playlist copyWith({String? name, List<int>? songIds}) => Playlist(
        id: id,
        name: name ?? this.name,
        songIds: songIds ?? this.songIds,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
