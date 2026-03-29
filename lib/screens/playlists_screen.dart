// lib/screens/playlists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/song_tile.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    final playlists = context.watch<PlaylistProvider>();
    // final cs = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // ── Favorites tile ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _FavoritesTile(lib: lib),
          ),
        ),

        // ── Section header ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  'Playlists',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                  onPressed: () => _showCreateDialog(context, playlists),
                ),
              ],
            ),
          ),
        ),

        if (playlists.playlists.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.queue_music_outlined, size: 64),
                  SizedBox(height: 12),
                  Text('No playlists yet',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Tap "New" to create your first playlist'),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) =>
                  _PlaylistTile(playlist: playlists.playlists[i]),
              childCount: playlists.playlists.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  void _showCreateDialog(
      BuildContext context, PlaylistProvider playlists) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              playlists.create(v.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                playlists.create(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ─── Favorites Tile ──────────────────────────────────────────
class _FavoritesTile extends StatelessWidget {
  final LibraryProvider lib;
  const _FavoritesTile({required this.lib});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FavoritesScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.errorContainer, cs.tertiaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.favorite_rounded,
                color: cs.onErrorContainer, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Favorites',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: cs.onErrorContainer)),
                Text(
                  '${lib.favorites.length} songs',
                  style: TextStyle(
                      color: cs.onErrorContainer.withOpacity(0.7),
                      fontSize: 13),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: cs.onErrorContainer),
          ],
        ),
      ),
    );
  }
}

// ─── Playlist Tile ───────────────────────────────────────────
class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final playlists = context.read<PlaylistProvider>();

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.playlist_play_rounded,
            color: cs.secondary, size: 28),
      ),
      title: Text(playlist.name,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        '${playlist.songIds.length} songs',
        style:
            TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6)),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) =>
            _handleAction(context, action, playlists),
        itemBuilder: (_) => [
          const PopupMenuItem(
              value: 'rename', child: Text('Rename')),
          const PopupMenuItem(
              value: 'delete',
              child: Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
        child: Icon(Icons.more_vert, color: cs.onSurface.withOpacity(0.5)),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(playlist: playlist)),
      ),
    );
  }

  void _handleAction(
      BuildContext context, String action, PlaylistProvider playlists) {
    if (action == 'delete') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete playlist?'),
          content: Text('Delete "${playlist.name}"?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red),
              onPressed: () {
                playlists.delete(playlist.id!);
                Navigator.pop(ctx);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else if (action == 'rename') {
      final c = TextEditingController(text: playlist.name);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rename'),
          content: TextField(
            controller: c,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (c.text.trim().isNotEmpty) {
                  playlists.rename(playlist.id!, c.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Rename'),
            ),
          ],
        ),
      );
    }
  }
}

// ─── Playlist Detail ─────────────────────────────────────────
class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final lib = context.read<LibraryProvider>();
    final audio = context.read<AudioProvider>();
    final playlists = context.watch<PlaylistProvider>();
    final current =
        playlists.getById(playlist.id!) ?? playlist;
    final songs = lib.songsById(current.songIds);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        actions: [
          if (songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              onPressed: () => audio.playAll(songs, shuffle: true),
            ),
        ],
      ),
      body: songs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.queue_music_outlined,
                      size: 64, color: cs.primary),
                  const SizedBox(height: 12),
                  const Text('No songs yet'),
                  const SizedBox(height: 8),
                  const Text('Add songs from the Songs tab'),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Text('${songs.length} songs',
                          style: TextStyle(
                              color: cs.onSurface.withOpacity(0.6),
                              fontSize: 13)),
                      const Spacer(),
                      FilledButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play all'),
                        onPressed: () => audio.playAll(songs),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: songs.length,
                    onReorder: (from, to) {
                      playlists.reorderSongs(
                          current.id!, from, to > from ? to - 1 : to);
                    },
                    itemBuilder: (ctx, i) {
                      final song = songs[i];
                      return Dismissible(
                        key: ValueKey('${current.id}_${song.id}_$i'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: cs.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete,
                              color: cs.onError),
                        ),
                        onDismissed: (_) =>
                            playlists.removeSong(current.id!, song.id),
                        child: SongTile(
                          key: ValueKey('tile_${song.id}_$i'),
                          song: song,
                          queue: songs,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Favorites Screen ────────────────────────────────────────
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    final audio = context.read<AudioProvider>();
    final songs = lib.favorites;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          if (songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              onPressed: () => audio.playAll(songs, shuffle: true),
            ),
        ],
      ),
      body: songs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border,
                      size: 64, color: cs.error),
                  const SizedBox(height: 12),
                  const Text('No favorites yet'),
                  const SizedBox(height: 8),
                  const Text('Tap the ♡ on any song to add it'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (ctx, i) =>
                  SongTile(song: songs[i], queue: songs),
            ),
    );
  }
}
