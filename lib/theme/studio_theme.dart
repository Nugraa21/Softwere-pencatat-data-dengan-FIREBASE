import 'package:flutter/material.dart';

class StudioTheme {
  /// 🎨 ACCENT (DINAMIS)
  static ValueNotifier<Color> accent =
      ValueNotifier(const Color(0xFF007AFF)); // iOS Blue

  /// 🌫️ GLASS COLORS (AMAN UNTUK BLUR)
  static const Color glassBase =
      Color(0xCCFFFFFF); // 80% opacity (anti white screen)
  static const Color cardGlass = Color(0xBFFFFFFF); // 75% opacity

  /// 🌙 BACKGROUND
  static const Color background =
      Color(0xFFF4F6FB); // Soft grey (mobile-friendly)

  /// 📝 TEXT
  static const Color text = Color(0xFF0F172A); // Dark slate
  static const Color secondaryText = Color(0xFF64748B); // Muted slate

  /// 📐 RADIUS
  static const double radius = 24.0;

  /// 💡 OPTIONAL SHADOW
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];
}
