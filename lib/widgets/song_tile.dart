// lib/widgets/song_tile.dart
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../providers/playlist_provider.dart';
import '../utils/extensions.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song> queue;
  final bool isPlaying;
  final bool showTrackNumber;
  final int? trackNumber;
  final VoidCallback? onTap;

  const SongTile({
    super.key,
    required this.song,
    required this.queue,
    this.isPlaying = false,
    this.showTrackNumber = false,
    this.trackNumber,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final audio = context.read<AudioProvider>();
    final lib = context.read<LibraryProvider>();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _ArtworkThumbnail(
        albumId: song.albumId,
        isPlaying: isPlaying,
        trackNumber: showTrackNumber ? trackNumber : null,
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying ? cs.primary : null,
          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${song.artist} • ${song.duration.msToMmss}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Favorite button
          IconButton(
            icon: Icon(
              lib.isFavorite(song.id) ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color:
                  lib.isFavorite(song.id) ? cs.error : cs.onSurface.withOpacity(0.4),
            ),
            onPressed: () => lib.toggleFavorite(song),
          ),
          // More options
          IconButton(
            icon: Icon(Icons.more_vert,
                size: 20, color: cs.onSurface.withOpacity(0.4)),
            onPressed: () => _showOptions(context, audio, lib),
          ),
        ],
      ),
      onTap: onTap ?? () => audio.playSong(song, queue),
    );
  }

  void _showOptions(
      BuildContext context, AudioProvider audio, LibraryProvider lib) {
    final playlists = context.read<PlaylistProvider>();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => _SongOptionsSheet(
        song: song,
        audio: audio,
        lib: lib,
        playlists: playlists,
      ),
    );
  }
}

class _ArtworkThumbnail extends StatelessWidget {
  final int? albumId;
  final bool isPlaying;
  final int? trackNumber;

  const _ArtworkThumbnail({
    this.albumId,
    required this.isPlaying,
    this.trackNumber,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: albumId != null
            ? QueryArtworkWidget(
                id: albumId!,
                type: ArtworkType.ALBUM,
                artworkBorder: BorderRadius.circular(8),
                nullArtworkWidget: _fallbackArt(cs, trackNumber),
                keepOldArtwork: true,
                artworkWidth: 48,
                artworkHeight: 48,
                artworkFit: BoxFit.cover,
              )
            : _fallbackArt(cs, trackNumber),
      ),
    );
  }

  Widget _fallbackArt(ColorScheme cs, int? number) => Container(
        color: cs.primaryContainer,
        child: Center(
          child: isPlaying
              ? Icon(Icons.equalizer, color: cs.primary, size: 22)
              : number != null
                  ? Text('$number',
                      style: TextStyle(
                          color: cs.primary, fontWeight: FontWeight.bold))
                  : Icon(Icons.music_note, color: cs.primary, size: 22),
        ),
      );
}

// ─── Song Options Bottom Sheet ────────────────────────────────
class _SongOptionsSheet extends StatelessWidget {
  final Song song;
  final AudioProvider audio;
  final LibraryProvider lib;
  final PlaylistProvider playlists;

  const _SongOptionsSheet({
    required this.song,
    required this.audio,
    required this.lib,
    required this.playlists,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Song header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.albumId != null
                    ? QueryArtworkWidget(
                        id: song.albumId!,
                        type: ArtworkType.ALBUM,
                        artworkWidth: 56,
                        artworkHeight: 56,
                        artworkFit: BoxFit.cover,
                        nullArtworkWidget: Container(
                          width: 56,
                          height: 56,
                          color: cs.primaryContainer,
                          child:
                              Icon(Icons.music_note, color: cs.primary),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: cs.primaryContainer,
                        child:
                            Icon(Icons.music_note, color: cs.primary),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(song.artist,
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.6)),
                        maxLines: 1),
                  ],
                ),
              ),
            ]),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Play'),
            onTap: () {
              Navigator.pop(context);
              audio.playSong(song, [song]);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text('Add to queue'),
            onTap: () {
              Navigator.pop(context);
              audio.addToQueue(song);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to queue')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.skip_next_outlined),
            title: const Text('Play next'),
            onTap: () {
              Navigator.pop(context);
              audio.addNextInQueue(song);
            },
          ),
          ListTile(
            leading: Icon(
              lib.isFavorite(song.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: lib.isFavorite(song.id) ? cs.error : null,
            ),
            title: Text(lib.isFavorite(song.id)
                ? 'Remove from favorites'
                : 'Add to favorites'),
            onTap: () {
              Navigator.pop(context);
              lib.toggleFavorite(song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to playlist'),
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylist(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Add to playlist',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              ...playlists.playlists.map((p) => ListTile(
                    leading: const Icon(Icons.playlist_play),
                    title: Text(p.name),
                    trailing: playlists.containsSong(p.id!, song.id)
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      playlists.addSong(p.id!, song.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added to ${p.name}')),
                      );
                    },
                  )),
              if (playlists.playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No playlists yet. Create one in the Playlists tab.'),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
