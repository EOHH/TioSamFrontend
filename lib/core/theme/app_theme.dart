import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de colores (Bright Gamified)
  static const Color background = Color(0xFFF6F8FF); // Gris azulado muy claro
  static const Color surface = Color(0xFFFFFFFF); // Blanco puro
  static const Color primary = Color(0xFF7C4DFF); // Morado vibrante
  static const Color secondary = Color(0xFF00C2FF); // Cian brillante
  static const Color accent = Color(0xFFFFD93D); // Amarillo oro
  
  static const Color textHeadline = Colors.black; // Negro puro para títulos
  static const Color textBody = Color(0xFF334155); // Gris azulado oscuro para cuerpo

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
      ),
      
      // Typography
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(color: textHeadline, fontWeight: FontWeight.w900),
        displayMedium: GoogleFonts.poppins(color: textHeadline, fontWeight: FontWeight.w800),
        displaySmall: GoogleFonts.poppins(color: textHeadline, fontWeight: FontWeight.w800),
        headlineLarge: GoogleFonts.poppins(color: textHeadline, fontWeight: FontWeight.w900),
        headlineMedium: GoogleFonts.poppins(color: textHeadline, fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.poppins(color: textHeadline, fontWeight: FontWeight.w800),
        titleMedium: GoogleFonts.poppins(color: textHeadline, fontWeight: FontWeight.w800),
        bodyLarge: GoogleFonts.poppins(color: textBody, fontWeight: FontWeight.normal),
        bodyMedium: GoogleFonts.poppins(color: textBody, fontWeight: FontWeight.normal),
        labelLarge: GoogleFonts.poppins(color: textBody, fontWeight: FontWeight.bold),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.poppins(
          color: primary,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: const Color(0xFF7C4DFF).withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // ElevatedButton Theme
      // Nota: Los gradientes no son soportados de forma nativa en ElevatedButtonTheme. 
      // Si requieres un botón con gradiente real, se recomienda crear un Custom Widget.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary, // Color base
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          elevation: 4,
          shadowColor: primary.withOpacity(0.4),
        ),
      ),

      // InputDecoration Theme (Buscadores / TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),
    );
  }
}