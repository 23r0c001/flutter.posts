import 'package:flutter/material.dart';

/// App-level design tokens.
///
/// These are raw color primitives that should remain stable and reusable.
class AppColorTokens {
  AppColorTokens._();

  // Brand mint scale.
  static const Color mint050 = Color(0xFFECFDF5);
  static const Color mint100 = Color(0xFFD1FAE5);
  static const Color mint300 = Color(0xFF6EE7B7);
  static const Color mint500 = Color(0xFF10B981);
  static const Color mint700 = Color(0xFF047857);

  // Neutral scale.
  static const Color slate050 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate900 = Color(0xFF0F172A);

  // Supporting colors.
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color danger500 = Color(0xFFDC2626);
}
