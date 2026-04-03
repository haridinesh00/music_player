// lib/widgets/mini_player.dart
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../providers/audio_provider.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: context.read<AudioProvider>().mediaItemStream,
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();
        return _MiniPlayerContent(item: item);
      },
    );
  }
}

class _MiniPlayerContent extends StatelessWidget {
  final MediaItem item;
  const _MiniPlayerContent({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final audio = context.read<AudioProvider>();

    return GestureDetector(
      onTap: () => _openNowPlaying(context),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < -200) _openNowPlaying(context);
      },
      child: Container(
        height: 72,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Album Art
            Hero(
              tag: 'album_art_${item.id}',
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(20)),
                child: _MiniArtwork(albumId: item.extras?['albumId'] as int?),
              ),
            ),
            const SizedBox(width: 12),
            // Title & Artist
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.artist ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Controls
            StreamBuilder<bool>(
              stream: audio.playingStream,
              builder: (ctx, snap) {
                final playing = snap.data ?? false;
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      onPressed: audio.skipToPrevious,
                      color: cs.onSurface,
                    ),
                    IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        size: 36,
                        color: cs.primary,
                      ),
                      onPressed: audio.togglePlayPause,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      onPressed: audio.skipToNext,
                      color: cs.onSurface,
                    ),
                    const SizedBox(width: 4),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openNowPlaying(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const NowPlayingScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class _MiniArtwork extends StatelessWidget {
  final int? albumId;
  const _MiniArtwork({this.albumId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (albumId == null) return _fallback(cs);
    return QueryArtworkWidget(
      id: albumId!,
      type: ArtworkType.ALBUM,
      artworkWidth: 72,
      artworkHeight: 72,
      artworkFit: BoxFit.cover,
      artworkBorder: BorderRadius.zero,
      nullArtworkWidget: _fallback(cs),
      keepOldArtwork: true,
    );
  }

  Widget _fallback(ColorScheme cs) => Container(
        width: 72,
        height: 72,
        color: cs.primaryContainer,
        child: Icon(Icons.music_note_rounded, color: cs.primary, size: 30),
      );
}
