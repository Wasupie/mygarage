import 'package:flutter/material.dart';

/// Design tokens (spacing, radii, durations) used across the app.
///
/// Keep these values stable so UI changes feel intentional.
sealed class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double s = 12;
  static const double m = 16;
  static const double l = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

sealed class AppRadii {
  static const double s = 10;
  static const double m = 14;
  static const double l = 18;
  static const double xl = 24;

  static const BorderRadius card = BorderRadius.all(Radius.circular(l));
  static const BorderRadius input = BorderRadius.all(Radius.circular(m));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(12));
}

sealed class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
}
