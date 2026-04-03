// lib/services/audio_handler.dart
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

enum RepeatMode { none, all, one }

class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  // 1. Declare the Equalizer first
  final AndroidEqualizer equalizer = AndroidEqualizer();

  // 2. Declare the player using 'late final' so we can initialize it with the pipeline later
  late final AudioPlayer _player;
  
  final _playlist = ConcatenatingAudioSource(children: []);

  // Public streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<double> get volumeStream => _player.volumeStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeStream => _player.shuffleModeEnabledStream;

  bool get playing => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  int? get currentIndex => _player.currentIndex;
  double get volume => _player.volume;

  // Combined position + duration stream
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (pos, buf, dur) => PositionData(pos, buf, dur ?? Duration.zero),
      );

  MusicAudioHandler() {
    // 3. Initialize the player WITH the equalizer plugged in
    _player = AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [
          equalizer, 
        ],
      ),
    );

    // 4. Turn the equalizer on!
    equalizer.setEnabled(true);
    
    // 5. Run your normal initialization
    _init();
  }

  Future<void> _init() async {
    // Configure audio session
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Handle audio interruptions
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        _player.pause();
      } else {
        if (event.type == AudioInterruptionType.pause ||
            event.type == AudioInterruptionType.duck) {
          _player.play();
        }
      }
    });

    // Pipe playback events → audio_service state
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Auto-advance: update mediaItem when index changes
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    // Auto-play next on completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });

    try {
      await _player.setAudioSource(_playlist);
    } catch (_) {}
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
      shuffleMode: _player.shuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      repeatMode: {
        LoopMode.off: AudioServiceRepeatMode.none,
        LoopMode.all: AudioServiceRepeatMode.all,
        LoopMode.one: AudioServiceRepeatMode.one,
      }[_player.loopMode]!,
    );
  }

  // ─── Playback Controls ───────────────────────────────────────
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_player.loopMode == LoopMode.all) {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(shuffleMode == AudioServiceShuffleMode.all);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _player.setLoopMode({
      AudioServiceRepeatMode.none: LoopMode.off,
      AudioServiceRepeatMode.one: LoopMode.one,
      AudioServiceRepeatMode.all: LoopMode.all,
      AudioServiceRepeatMode.group: LoopMode.all,
    }[repeatMode]!);
  }

  // ─── Queue Management ────────────────────────────────────────
  Future<void> playFromSongs({
    required List<MediaItem> songs,
    required int startIndex,
  }) async {
    // Update service queue
    queue.add(songs);
    mediaItem.add(songs[startIndex]);

    // Build audio sources
    final sources = songs
        .map((item) => AudioSource.uri(Uri.parse(item.id), tag: item))
        .toList();

    await _playlist.clear();
    await _playlist.addAll(sources);
    await _player.seek(Duration.zero, index: startIndex);
    await _player.play();
  }

  Future<void> addToQueue(MediaItem item) async {
    final current = List<MediaItem>.from(queue.value)..add(item);
    queue.add(current);
    await _playlist.add(AudioSource.uri(Uri.parse(item.id), tag: item));
  }

  Future<void> addNextInQueue(MediaItem item) async {
    final idx = (_player.currentIndex ?? 0) + 1;
    final current = List<MediaItem>.from(queue.value)..insert(idx, item);
    queue.add(current);
    await _playlist.insert(
        idx, AudioSource.uri(Uri.parse(item.id), tag: item));
  }

  Future<void> removeFromQueue(int index) async {
    final current = List<MediaItem>.from(queue.value)..removeAt(index);
    queue.add(current);
    await _playlist.removeAt(index);
  }

  Future<void> moveQueueItem(int from, int to) async {
    final current = List<MediaItem>.from(queue.value);
    final item = current.removeAt(from);
    current.insert(to, item);
    queue.add(current);
    await _playlist.move(from, to);
  }

  // ─── Volume & Speed ──────────────────────────────────────────
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  // ─── Crossfade ───────────────────────────────────────────────
  // Note: just_audio handles gapless playback automatically via
  // ConcatenatingAudioSource. True crossfade requires a custom
  // dual-player implementation (use a crossfade service).

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'setVolume':
        await setVolume(extras!['volume'] as double);
        break;
    }
  }

  // @override
  // Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
  //   // 1. Clean up the messy URI path into a readable song title
  //   final pathString = Uri.decodeFull(uri.path);
  //   final fileName = pathString.split('/').last; 

  //   // 2. Create the MediaItem for the Mini-Player UI
  //   final externalItem = MediaItem(
  //     id: uri.toString(),
  //     title: fileName,
  //     artist: 'External File',
  //   );

  //   // 3. Update the AudioService Queue (Updates your UI)
  //   final currentQueue = queue.value;
  //   currentQueue.add(externalItem);
  //   queue.add(currentQueue); 

  //   // 4. Create the actual Just Audio source
  //   // CRITICAL: We use AudioSource.uri() so it can read the 'content://' scheme!
  //   final audioSource = AudioSource.uri(
  //     uri,
  //     tag: externalItem, 
  //   );

  //   try {
  //     // 5. Inject the song directly into Just Audio's engine
  //     // 👇 NOTE: Change '_playlist' to whatever you named your ConcatenatingAudioSource! 👇
  //     await _playlist.add(audioSource); 
      
  //     // 6. Skip to the end of the queue (where we just put the song) and hit play
  //     // 👇 NOTE: Change '_player' to whatever you named your AudioPlayer instance! 👇
  //     await _player.seek(Duration.zero, index: currentQueue.length - 1);
  //     await _player.play();
  //   } catch (e) {
  //     log('Error playing external file: $e');
  //   }
  // }

  @override
  Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
    final pathString = Uri.decodeFull(uri.path);
    final fileName = pathString.split('/').last; 

    final externalItem = MediaItem(
      id: uri.toString(),
      title: fileName,
      artist: 'External File',
    );

    // FIX 1: Create a brand NEW list so the UI stream actually recognizes the change
    final currentQueue = List<MediaItem>.from(queue.value);
    currentQueue.add(externalItem);
    queue.add(currentQueue); // This now triggers a proper UI queue update

    final audioSource = AudioSource.uri(
      uri,
      tag: externalItem, 
    );

    try {
      await _playlist.add(audioSource); 
      
      // FIX 2: Explicitly shout to the rest of the app "THIS is the new song!"
      mediaItem.add(externalItem);

      await _player.seek(Duration.zero, index: currentQueue.length - 1);
      await _player.play();
    } catch (e) {
      log('Error playing external file: $e');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

// ─── Position Data ────────────────────────────────────────────
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);

  double get progress =>
      duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;
}
