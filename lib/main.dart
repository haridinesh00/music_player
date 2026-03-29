// lib/main.dart
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/audio_provider.dart';
import 'providers/library_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/theme_provider.dart';
import 'services/audio_handler.dart';
import 'services/database_service.dart';

late MusicAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Portrait + landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  try {

    await DatabaseService.instance.init();

    // Register background audio handler
    audioHandler = await AudioService.init(
      builder: () => MusicAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.musicplayer.audio',
        androidNotificationChannelName: 'Music Player',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: false,
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        notificationColor: Color(0xFF6750A4),
      ),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider(audioHandler)),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
      ],
      child: const MusicPlayerApp(),
    ),
  );
}
