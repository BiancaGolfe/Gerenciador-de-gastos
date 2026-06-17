import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF3C3489);
  static const primaryLight = Color(0xFFEEEDFE);
  static const primaryMid = Color(0xFF534AB7);

  static const catAlimentacao = Color(0xFF1D9E75);
  static const catAlimentacaoBg = Color(0xFFE1F5EE);
  static const catTransporte = Color(0xFF185FA5);
  static const catTransporteBg = Color(0xFFE6F1FB);
  static const catLazer = Color(0xFFBA7517);
  static const catLazerBg = Color(0xFFFAEEDA);
  static const catEstudos = Color(0xFF534AB7);
  static const catEstudosBg = Color(0xFFEEEDFE);
  static const catSaude = Color(0xFFA32D2D);
  static const catSaudeBg = Color(0xFFFCEBEB);
  static const catOutros = Color(0xFF5F5E5A);
  static const catOutrosBg = Color(0xFFF1EFE8);
}

class AppCategorias {
  static const List<String> lista = [
    'Alimentação',
    'Transporte',
    'Lazer',
    'Estudos',
    'Saúde',
    'Outros',
  ];

  static Color cor(String categoria) {
    switch (categoria) {
      case 'Alimentação': return AppColors.catAlimentacao;
      case 'Transporte': return AppColors.catTransporte;
      case 'Lazer': return AppColors.catLazer;
      case 'Estudos': return AppColors.catEstudos;
      case 'Saúde': return AppColors.catSaude;
      default: return AppColors.catOutros;
    }
  }

  static Color corFundo(String categoria) {
    switch (categoria) {
      case 'Alimentação': return AppColors.catAlimentacaoBg;
      case 'Transporte': return AppColors.catTransporteBg;
      case 'Lazer': return AppColors.catLazerBg;
      case 'Estudos': return AppColors.catEstudosBg;
      case 'Saúde': return AppColors.catSaudeBg;
      default: return AppColors.catOutrosBg;
    }
  }

  static IconData icone(String categoria) {
    switch (categoria) {
      case 'Alimentação': return Icons.restaurant_outlined;
      case 'Transporte': return Icons.directions_bus_outlined;
      case 'Lazer': return Icons.sports_esports_outlined;
      case 'Estudos': return Icons.menu_book_outlined;
      case 'Saúde': return Icons.favorite_border;
      default: return Icons.receipt_long_outlined;
    }
  }
}

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F4F8),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1A2E),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEAE8F0), width: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F4F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDDAEA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDDAEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
