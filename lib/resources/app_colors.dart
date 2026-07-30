// import 'package:flutter/material.dart';
//
// class AppColors {
//   // ========================================
//   // LOGIN SCREEN COLORS (Unchanged)
//   // ========================================
//   static const Color teal = Color(0xFF00897B);
//   static const Color softCreamWhite = Color(0xFFFFFBF5);
//   static const Color black54 = Color(0x8A000000);
//   static const Color white = Colors.white;
//
//   // ========================================
//   // NEW HOME & HISTORY SCREEN THEME
//   // ========================================
//
//   // Background colors - Modern gradient-friendly palette
//   static const Color background = Color(0xFFF5F7FA); // Soft light blue-gray
//   static const Color cardBackground = Color(0xFFFFFFFF); // Pure white for cards
//
//   // Primary accent colors - Vibrant modern palette
//   static const Color primaryAccent = Color(0xFF6366F1); // Modern indigo
//   static const Color secondaryAccent = Color(0xFF8B5CF6); // Purple accent
//   static const Color tealAccent = Color(0xFF14B8A6); // Teal for actions
//
//   // Text colors - High contrast for readability
//   static const Color primaryText = Color(0xFF1F2937); // Dark gray
//   static const Color secondaryText = Color(0xFF6B7280); // Medium gray
//
//   // UI element colors
//   static const Color iconDark = Color(0xFF374151);
//   static const Color iconGray = Color(0xFF9CA3AF);
//   static const Color divider = Color(0xFFE5E7EB);
//
//   // Status colors
//   static const Color success = Color(0xFF10B981);
//   static const Color error = Color(0xFFEF4444);
//   static const Color warning = Color(0xFFF59E0B);
//
//   // Gradient colors for modern effects
//   static const Color gradientStart = Color(0xFF6366F1);
//   static const Color gradientEnd = Color(0xFF8B5CF6);
//
//   // Chat bubble colors
//   static const Color userBubble = Color(0xFF6366F1); // Indigo for user messages
//   static const Color assistantBubble = Color(0xFFF3F4F6); // Light gray for AI
//
//   // Button colors
//   static const Color buttonPrimary = Color(0xFF6366F1);
//   static const Color buttonSecondary = Color(0xFF14B8A6);
//
//   // Shimmer/skeleton colors
//   static const Color shimmerBase = Color(0xFFE5E7EB);
//   static const Color shimmerHighlight = Color(0xFFF9FAFB);
//
//   // ========================================
//   // GRADIENT PRESETS
//   // ========================================
//
//   static const LinearGradient primaryGradient = LinearGradient(
//     colors: [gradientStart, gradientEnd],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
//
//   static const LinearGradient cardGradient = LinearGradient(
//     colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
//     begin: Alignment.topCenter,
//     end: Alignment.bottomCenter,
//   );
//
//   // ========================================
//   // SHADOW PRESETS
//   // ========================================
//
//   static List<BoxShadow> cardShadow = [
//     BoxShadow(
//       color: Colors.black.withOpacity(0.05),
//       blurRadius: 10,
//       offset: const Offset(0, 2),
//     ),
//   ];
//
//   static List<BoxShadow> elevatedShadow = [
//     BoxShadow(
//       color: Colors.black.withOpacity(0.1),
//       blurRadius: 20,
//       offset: const Offset(0, 4),
//     ),
//   ];
// }