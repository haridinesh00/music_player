// lib/app.dart
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  static const _seed = Color(0xFF6750A4);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        // Use Material You system colors if available, else seed
        final lightScheme = lightDynamic?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: _seed,
              brightness: Brightness.light,
            );
        final darkScheme = darkDynamic?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: _seed,
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
