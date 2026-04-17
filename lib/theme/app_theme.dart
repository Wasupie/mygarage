import 'package:flutter/material.dart';

import 'app_ui.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color maintenance;
  final Color fuel;
  final Color modifications;
  final Color success;
  final Color warning;

  const AppSemanticColors({
    required this.maintenance,
    required this.fuel,
    required this.modifications,
    required this.success,
    required this.warning,
  });

  @override
  AppSemanticColors copyWith({
    Color? maintenance,
    Color? fuel,
    Color? modifications,
    Color? success,
    Color? warning,
  }) {
    return AppSemanticColors(
      maintenance: maintenance ?? this.maintenance,
      fuel: fuel ?? this.fuel,
      modifications: modifications ?? this.modifications,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      maintenance: Color.lerp(maintenance, other.maintenance, t)!,
      fuel: Color.lerp(fuel, other.fuel, t)!,
      modifications: Color.lerp(modifications, other.modifications, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

sealed class AppTheme {
  static ThemeData light() => _build(brightness: Brightness.light);
  static ThemeData dark() => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final scheme = brightness == Brightness.light ? _lightScheme : _darkScheme;

    // Typography: slightly tighter and more editorial than Material defaults.
    final baseTextTheme = Typography.material2021().black;
    final textTheme = baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 1.25),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 1.25),
      bodySmall: baseTextTheme.bodySmall?.copyWith(height: 1.2),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      visualDensity: VisualDensity.comfortable,
      splashFactory: InkRipple.splashFactory,

      extensions: <ThemeExtension<dynamic>>[
        AppSemanticColors(
          // Monochrome semantics: different values (not hues).
          maintenance: isLight ? const Color(0xFF1F2328) : const Color(0xFFE6E8EB),
          fuel: isLight ? const Color(0xFF2B3037) : const Color(0xFFD6D9DD),
          modifications: isLight ? const Color(0xFF15181D) : const Color(0xFFF2F3F5),
          success: isLight ? const Color(0xFF2A2F36) : const Color(0xFFC9CDD2),
          warning: isLight ? const Color(0xFF3A4048) : const Color(0xFFB8BDC4),
        ),
      ],

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.all(0),
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: isLight ? 0.7 : 0.5),
        thickness: 1,
        space: AppSpacing.m,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.55 : 0.35),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: scheme.error),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.s,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.s,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: AppSpacing.xs,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        shape: const StadiumBorder(),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),

      tabBarTheme: TabBarThemeData(
        dividerColor: scheme.outlineVariant.withValues(alpha: 0.7),
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: scheme.primary, width: 2),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.chip),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
        titleTextStyle: textTheme.titleMedium?.copyWith(color: scheme.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.chip),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        backgroundColor:
            scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.55 : 0.35),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }

  // Monochrome palette: grayscale only, flat surfaces, subtle outlines.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1F2328),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE7E9EC),
    onPrimaryContainer: Color(0xFF0E1116),
    secondary: Color(0xFF2B3037),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEDEFF2),
    onSecondaryContainer: Color(0xFF111419),
    tertiary: Color(0xFF15181D),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF2F3F5),
    onTertiaryContainer: Color(0xFF0B0D10),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFCFCFD),
    onSurface: Color(0xFF101216),
    surfaceDim: Color(0xFFF3F4F6),
    surfaceBright: Color(0xFFFCFCFD),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFAFAFB),
    surfaceContainer: Color(0xFFF5F6F7),
    surfaceContainerHigh: Color(0xFFEEF0F2),
    surfaceContainerHighest: Color(0xFFE7E9EC),
    onSurfaceVariant: Color(0xFF4A4F57),
    outline: Color(0xFF808791),
    outlineVariant: Color(0xFFD7DADE),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1A1D22),
    onInverseSurface: Color(0xFFF1F2F4),
    inversePrimary: Color(0xFFE6E8EB),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE6E8EB),
    onPrimary: Color(0xFF111317),
    primaryContainer: Color(0xFF2B2F36),
    onPrimaryContainer: Color(0xFFF2F3F5),
    secondary: Color(0xFFD6D9DD),
    onSecondary: Color(0xFF12151A),
    secondaryContainer: Color(0xFF2A2E35),
    onSecondaryContainer: Color(0xFFEEF0F2),
    tertiary: Color(0xFFF2F3F5),
    onTertiary: Color(0xFF0F1115),
    tertiaryContainer: Color(0xFF262A31),
    onTertiaryContainer: Color(0xFFE7E9EC),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF0F1115),
    onSurface: Color(0xFFEDEEF1),
    surfaceDim: Color(0xFF0F1115),
    surfaceBright: Color(0xFF2B2F36),
    surfaceContainerLowest: Color(0xFF0B0D10),
    surfaceContainerLow: Color(0xFF12151A),
    surfaceContainer: Color(0xFF171A1F),
    surfaceContainerHigh: Color(0xFF1E2228),
    surfaceContainerHighest: Color(0xFF262A31),
    onSurfaceVariant: Color(0xFFC9CDD2),
    outline: Color(0xFF8A919B),
    outlineVariant: Color(0xFF3A4048),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE6E8EB),
    onInverseSurface: Color(0xFF1A1D22),
    inversePrimary: Color(0xFF1F2328),
  );
}

extension ThemeExt on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ??
      const AppSemanticColors(
        maintenance: Color(0xFF0F4C5C),
        fuel: Color(0xFFB3532D),
        modifications: Color(0xFF6B4EFF),
        success: Color(0xFF1C7C54),
        warning: Color(0xFFB98300),
      );
}
