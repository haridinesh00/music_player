// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Dynamic palette extracted from current album art
  ColorScheme? _dynamicScheme;
  ColorScheme? get dynamicScheme => _dynamicScheme;

  Color get dominantColor =>
      _dynamicScheme?.primary ?? const Color(0xFF6750A4);
  Color get dominantSurface =>
      _dynamicScheme?.surface ?? const Color(0xFF1C1B1F);

  bool _useDynamicColor = true;
  bool get useDynamicColor => _useDynamicColor;

  ThemeProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIdx = prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[modeIdx];
    _useDynamicColor = prefs.getBool('dynamic_color') ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  Future<void> toggleDynamicColor(bool value) async {
    _useDynamicColor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dynamic_color', value);
    notifyListeners();
  }

  // Called whenever the current song changes
  Future<void> extractColorsFromArtwork(
    int? albumId, {
    bool isDark = true,
  }) async {
    if (!_useDynamicColor || albumId == null) {
      _dynamicScheme = null;
      notifyListeners();
      return;
    }

    try {
      final query = OnAudioQuery();
      final artBytes = await query.queryArtwork(
        albumId,
        ArtworkType.ALBUM,
        size: 200,
        quality: 80,
      );

      if (artBytes == null || artBytes.isEmpty) {
        _dynamicScheme = null;
        notifyListeners();
        return;
      }

      final image = MemoryImage(artBytes);
      final palette = await PaletteGenerator.fromImageProvider(
        image,
        maximumColorCount: 8,
      );

      final dominant = palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          const Color(0xFF6750A4);

      _dynamicScheme = ColorScheme.fromSeed(
        seedColor: dominant,
        brightness: isDark ? Brightness.dark : Brightness.light,
      );
    } catch (_) {
      _dynamicScheme = null;
    }
    notifyListeners();
  }

  // ─── Material 3 themes ───────────────────────────────────────
  static ThemeData buildTheme({
    required Brightness brightness,
    Color seedColor = const Color(0xFF6750A4),
    ColorScheme? override,
  }) {
    final scheme = override ??
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        thumbColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.24),
        overlayColor: scheme.primary.withValues(alpha: 0.12),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: scheme.surfaceContainerHigh,
      ),
    );
  }
}
