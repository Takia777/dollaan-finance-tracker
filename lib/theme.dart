import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna dari sketsa: sakura, tosca tua, kuning, ungu, putih, ungu tua.
class AppColors {
  static const sakura = Color(0xFFFDEEF2);
  static const tosca = Color(0xFF0E6E6A);
  static const kuning = Color(0xFFF7C948);
  static const ungu = Color(0xFF9B7BF2);
  static const putih = Color(0xFFFFFFFF);
  static const unguTua = Color(0xFF35245E);
  static const muted = Color(0xFF8C819F);
  static const danger = Color(0xFFD9485F);
  static const pink = Color(0xFFE58FAA);

  /// Warna kartu wallet yang bisa dipilih pengguna.
  static const cardColors = <String, Color>{
    'unguTua': unguTua,
    'ungu': ungu,
    'tosca': tosca,
    'kuning': kuning,
    'sakura': Color(0xFFF6C9D6),
  };

  static Color card(String key) => cardColors[key] ?? unguTua;

  /// Warna teks di atas kartu (gelap untuk kartu terang).
  static Color onCard(String key) =>
      (key == 'kuning' || key == 'sakura') ? unguTua : putih;
}

extension Fade on Color {
  /// Versi transparan dari warna ini, misalnya `AppColors.tosca.o(0.12)`.
  Color o(double opacity) => withValues(alpha: opacity);
}

/// Gaya teks singkat: `ts(14, FontWeight.w700)`.
TextStyle ts(double size,
        [FontWeight weight = FontWeight.w500, Color color = AppColors.unguTua]) =>
    TextStyle(fontSize: size, fontWeight: weight, color: color);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.unguTua,
      primary: AppColors.unguTua,
      secondary: AppColors.tosca,
      surface: AppColors.putih,
    ),
    scaffoldBackgroundColor: AppColors.sakura,
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.unguTua,
      displayColor: AppColors.unguTua,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerColor: Colors.transparent,
  );
}
