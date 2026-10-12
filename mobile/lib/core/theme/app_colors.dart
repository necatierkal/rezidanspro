import 'package:flutter/material.dart';

class AppColors {
  // Core Brand Colors
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  
  static const Color secondary = Color(0xFF14B8A6); // Teal
  static const Color secondaryDark = Color(0xFF0D9488);
  
  // Neutral Colors
  static const Color dark = Color(0xFF0F172A); // Slate Dark
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF334155);
  
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
  
  // Feedback & Semantic Colors
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFDC2626);   // Red
  static const Color success = Color(0xFF16A34A); // Green
  static const Color info = Color(0xFF0EA5E9);    // Sky Blue

  // Priority Colors
  static const Color priorityNormal = Color(0xFF2563EB);
  static const Color priorityImportant = Color(0xFFF59E0B);
  static const Color priorityUrgent = Color(0xFFDC2626);

  // Status Colors (Maintenance)
  static const Color statusOpen = Color(0xFFDC2626);
  static const Color statusInProgress = Color(0xFFF97316);
  static const Color statusWaiting = Color(0xFFF59E0B);
  static const Color statusResolved = Color(0xFF16A34A);
  static const Color statusClosed = Color(0xFF64748B);

  // Dues Status Colors
  static const Color duesPaid = Color(0xFF16A34A);
  static const Color duesUnpaid = Color(0xFFDC2626);
  static const Color duesPartial = Color(0xFFF59E0B);
  static const Color duesOverdue = Color(0xFF991B1B);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
}
