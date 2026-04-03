// lib/screens/artists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../utils/extensions.dart';
import '../widgets/song_tile.dart';

class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    if (lib.state != LibraryState.ready) {
      return const Center(child: CircularProgressIndicator());
    }
    if (lib.artists.isEmpty) {
      return const Center(child: Text('No artists found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: lib.artists.length,
      itemBuilder: (ctx, i) {
        final artist = lib.artists[i];
        return _ArtistTile(artist: artist);
      },
    );
  }
}

class _ArtistTile extends StatelessWidget {
  final Artist artist;
  const _ArtistTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child: Text(
          artist.name.initials,
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(artist.name,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        '${artist.numberOfTracks} songs • ${artist.numberOfAlbums} albums',
        style:
            TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
      ),
      trailing: Icon(Icons.chevron_right, color: cs.outline),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtistDetailScreen(artist: artist),
        ),
      ),
    );
  }
}

// ─── Artist Detail ────────────────────────────────────────────
class ArtistDetailScreen extends StatelessWidget {
  final Artist artist;
  const ArtistDetailScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lib = context.read<LibraryProvider>();
    final audio = context.read<AudioProvider>();
    final songs = lib.songsForArtist(artist.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(artist.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primaryContainer,
                      cs.secondaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    artist.name.initials,
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w800,
                      color: cs.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
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
                      Text(
                        '${songs.length} songs',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        '${artist.numberOfAlbums} albums',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 13),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.shuffle_rounded),
                    onPressed: () => audio.playAll(songs, shuffle: true),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'artist_play_${artist.id}',
                    onPressed: () => audio.playAll(songs),
                    child: const Icon(Icons.play_arrow_rounded),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) =>
                  SongTile(song: songs[i], queue: songs),
              childCount: songs.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
