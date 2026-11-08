import 'package:flutter/material.dart';

/// Palet pastel Pastel.Shop.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFAF6F3);
  static const surface = Colors.white;
  static const line = Color(0xFFECE3DE);

  static const pink = Color(0xFFEBD3D3);
  static const pinkSoft = Color(0xFFF7ECEA);
  static const pinkDeep = Color(0xFFC48B93);
  static const lavender = Color(0xFFDAD4E6);
  static const lavenderSoft = Color(0xFFF1EEF6);
  static const mint = Color(0xFFD3E2D8);
  static const peach = Color(0xFFF1DFD0);
  static const sky = Color(0xFFD5E2EA);
  static const butter = Color(0xFFF0E6CB);

  static const ink = Color(0xFF3F3540);
  static const inkSoft = Color(0xFF8A7F88);
  static const accent = Color(0xFF9A5B6E);
  static const danger = Color(0xFFB5566A);
  static const star = Color(0xFFD9A441);

  static const List<Color> tints = [pink, lavender, mint, peach, sky, butter];

  /// Warna pastel latar gambar, berbeda-beda per produk.
  static Color tintFor(int id) => tints[id.abs() % tints.length];
}

class AppDecor {
  AppDecor._();

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x149A5B6E),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static BoxDecoration card({
    double radius = 22,
    Color color = Colors.white,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.line),
      boxShadow: softShadow,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.pinkDeep,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      primaryContainer: AppColors.pink,
      onPrimaryContainer: AppColors.ink,
      secondaryContainer: AppColors.lavender,
      onSecondaryContainer: AppColors.ink,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    final text = base.textTheme
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
        .copyWith(
          headlineMedium: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.ink,
          ),
          headlineSmall: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.25,
            color: AppColors.ink,
          ),
          titleLarge: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.ink,
          ),
          titleMedium: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
            color: AppColors.ink,
          ),
        );

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: AppColors.background,
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.pinkDeep,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFBF3F1),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(AppColors.line),
        enabledBorder: border(AppColors.line),
        focusedBorder: border(AppColors.accent, 1.6),
        errorBorder: border(AppColors.danger),
        focusedErrorBorder: border(AppColors.danger, 1.6),
        labelStyle: const TextStyle(color: AppColors.inkSoft),
        floatingLabelStyle: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: Color(0xFFB8ADB4)),
        prefixIconColor: AppColors.pinkDeep,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: AppColors.pinkDeep, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 3,
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

/// Dekorasi field seragam untuk form.
InputDecoration pastelField({
  required String label,
  String? hint,
  IconData? icon,
  String? prefixText,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    prefixIcon: icon == null ? null : Icon(icon),
  );
}

/// Tombol ikon bulat putih bergaris tipis.
class PastelIconButton extends StatelessWidget {
  const PastelIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: iconColor ?? AppColors.ink,
        fixedSize: const Size(44, 44),
        side: const BorderSide(color: AppColors.line),
      ),
    );
  }
}

/// Kartu bagian form dengan judul dan ikon pastel.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.tint = AppColors.pink,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecor.card(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.ink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}