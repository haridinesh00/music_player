// lib/widgets/equalizer_widget.dart
//
// Visual EQ with 5 bands. Values are persisted via SharedPreferences.
// Actual audio DSP requires the `equalizer_flutter` or a custom
// AudioEffect platform channel — hook into those in AudioHandler.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EqualizerWidget extends StatefulWidget {
  const EqualizerWidget({super.key});

  @override
  State<EqualizerWidget> createState() => _EqualizerWidgetState();
}

class _EqualizerWidgetState extends State<EqualizerWidget> {
  static const _bands = ['60Hz', '230Hz', '910Hz', '4kHz', '14kHz'];
  static const _min = -12.0;
  static const _max = 12.0;

  late List<double> _gains;
  bool _enabled = true;

  static const _presets = {
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Bass Boost': [6.0, 4.0, 0.0, 0.0, 0.0],
    'Treble Boost': [0.0, 0.0, 0.0, 4.0, 6.0],
    'Vocal': [-2.0, 0.0, 4.0, 4.0, 2.0],
    'Rock': [4.0, 2.0, -2.0, 2.0, 4.0],
    'Pop': [-1.0, 2.0, 4.0, 2.0, -1.0],
    'Jazz': [2.0, 1.0, 0.0, 2.0, 3.0],
    'Classical': [3.0, 2.0, 0.0, 2.0, 3.0],
  };

  @override
  void initState() {
    super.initState();
    _gains = List.filled(_bands.length, 0.0);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _enabled = p.getBool('eq_enabled') ?? true;
      for (int i = 0; i < _bands.length; i++) {
        _gains[i] = p.getDouble('eq_band_$i') ?? 0.0;
      }
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('eq_enabled', _enabled);
    for (int i = 0; i < _bands.length; i++) {
      await p.setDouble('eq_band_$i', _gains[i]);
    }
  }

  void _applyPreset(String name) {
    setState(() {
      _gains = List<double>.from(_presets[name]!);
    });
    _savePrefs();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────
        Row(
          children: [
            Text('Equalizer',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const Spacer(),
            Switch(value: _enabled, onChanged: (v) {
              setState(() => _enabled = v);
              _savePrefs();
            }),
          ],
        ),
        const SizedBox(height: 16),

        // ── Presets ─────────────────────────────────────────────
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _presets.keys
                .map((name) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(name),
                        selected: _isPreset(name),
                        onSelected: (_) => _applyPreset(name),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),

        // ── Bands ───────────────────────────────────────────────
        AnimatedOpacity(
          opacity: _enabled ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_enabled,
            child: SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  _bands.length,
                  (i) => Expanded(
                    child: _BandSlider(
                      label: _bands[i],
                      value: _gains[i],
                      min: _min,
                      max: _max,
                      onChanged: (v) {
                        setState(() => _gains[i] = v);
                        _savePrefs();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
        // dB scale hint
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('+12 dB',
                style: TextStyle(fontSize: 11, color: cs.outline)),
            Text('0 dB',
                style: TextStyle(fontSize: 11, color: cs.outline)),
            Text('-12 dB',
                style: TextStyle(fontSize: 11, color: cs.outline)),
          ],
        ),
      ],
    );
  }

  bool _isPreset(String name) {
    final preset = _presets[name]!;
    for (int i = 0; i < preset.length; i++) {
      if ((_gains[i] - preset[i]).abs() > 0.01) return false;
    }
    return true;
  }
}

class _BandSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _BandSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayGain =
        value >= 0 ? '+${value.toStringAsFixed(1)}' : value.toStringAsFixed(1);

    return Column(
      children: [
        Text(
          displayGain,
          style: TextStyle(
            fontSize: 10,
            color: value.abs() > 0.1 ? cs.primary : cs.outline,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 24,
              onChanged: onChanged,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: cs.outline),
        ),
      ],
    );
  }
}
