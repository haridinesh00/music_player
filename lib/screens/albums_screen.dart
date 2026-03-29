// lib/screens/albums_screen.dart
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/song_tile.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    if (lib.state != LibraryState.ready) {
      return const Center(child: CircularProgressIndicator());
    }
    if (lib.albums.isEmpty) {
      return const Center(child: Text('No albums found'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: lib.albums.length,
      itemBuilder: (ctx, i) => _AlbumCard(album: lib.albums[i]),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AlbumDetailScreen(album: album)),
      ),
      child: Card(
        // Add clipBehavior so the image respects the Card's rounded corners
        clipBehavior: Clip.antiAlias, 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch image to edges
          children: [
            // Artwork (Takes up exactly half the card)
            AspectRatio(
              aspectRatio: 1, // Keeps the image a perfect square
              child: QueryArtworkWidget(
                id: album.id,
                type: ArtworkType.ALBUM,
                artworkBorder: BorderRadius.zero,
                artworkFit: BoxFit.cover,
                keepOldArtwork: true,
                nullArtworkWidget: Container(
                  color: cs.primaryContainer,
                  child: Icon(
                    Icons.album_rounded,
                    size: 56,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
            
            // Text Block (Wrapped in Expanded to prevent overflow)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, // Center text vertically
                  children: [
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      album.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${album.songCount} songs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Added to prevent wrapping
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Album Detail ────────────────────────────────────────────
class AlbumDetailScreen extends StatelessWidget {
  final Album album;
  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lib = context.read<LibraryProvider>();
    final audio = context.read<AudioProvider>();
    final songs = lib.songsForAlbum(album.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(album.title,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  QueryArtworkWidget(
                    id: album.id,
                    type: ArtworkType.ALBUM,
                    artworkBorder: BorderRadius.zero,
                    artworkFit: BoxFit.cover,
                    artworkWidth: double.infinity,
                    artworkHeight: double.infinity,
                    keepOldArtwork: true,
                    nullArtworkWidget: Container(
                      color: cs.primaryContainer,
                      child: Icon(Icons.album_rounded,
                          size: 80, color: cs.primary),
                    ),
                  ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(album.artist,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(
                        '${songs.length} songs${album.firstYear != null ? ' • ${album.firstYear}' : ''}',
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.6),
                            fontSize: 13),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.shuffle_rounded),
                    onPressed: () => audio.playAll(songs, shuffle: true),
                    tooltip: 'Shuffle',
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'album_play_${album.id}',
                    onPressed: () => audio.playAll(songs),
                    child: const Icon(Icons.play_arrow_rounded),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => SongTile(
                song: songs[i],
                queue: songs,
                trackNumber: i + 1,
                showTrackNumber: true,
              ),
              childCount: songs.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
