// lib/utils/extensions.dart

extension DurationFormat on Duration {
  String get mmss {
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get hhmmss {
    if (inHours > 0) {
      final h = inHours.toString();
      final m = inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    return mmss;
  }
}

extension IntDuration on int {
  Duration get ms => Duration(milliseconds: this);
  String get msToMmss => Duration(milliseconds: this).mmss;
}

extension StringExt on String {
  String get initials {
    final words = trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}
