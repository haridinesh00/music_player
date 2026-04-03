// lib/app.dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart'; // To access your global 'audioHandler'
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

class MusicPlayerApp extends StatefulWidget {
  const MusicPlayerApp({super.key});

  static const _seed = Color(0xFF6750A4);

  @override
  State<MusicPlayerApp> createState() => _MusicPlayerAppState();
}

class _MusicPlayerAppState extends State<MusicPlayerApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();

    // SCENARIO 1: App is completely closed (Cold Start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        audioHandler.playFromUri(initialUri);
      }
    } catch (e) {
      debugPrint('Error handling initial link: $e');
    }

    // SCENARIO 2: App is already running in the background
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      audioHandler.playFromUri(uri);
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        // Use Material You system colors if available, else seed
        final lightScheme = lightDynamic?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: MusicPlayerApp._seed,
              brightness: Brightness.light,
            );
        final darkScheme = darkDynamic?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: MusicPlayerApp._seed,
              brightness: Brightness.dark,
            );

        return MaterialApp(
          title: 'Music Player',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeProvider.buildTheme(
            brightness: Brightness.light,
            override: lightScheme,
          ),
          darkTheme: ThemeProvider.buildTheme(
            brightness: Brightness.dark,
            override: darkScheme,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}