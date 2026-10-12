import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'RezidansPro';
  static const String tagline = 'Binanızın iletişim merkezi.';
  static const String secondaryTagline = 'Binanız artık cebinizde.';
  static const String storeTitle = 'RezidansPro - Apartman & Site';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String supportEmail = 'destek@rezidanspro.app';
  static const String websiteUrl = 'https://rezidanspro.app';
  static const String privacyPolicyUrl = 'https://rezidanspro.app/privacy';
  static const String termsUrl = 'https://rezidanspro.app/terms';

  // API Base URL - Configurable for Emulator, Real Device, or Localhost
  static const String defaultApiBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator default
  static const String localApiBaseUrl = 'http://localhost:8000/api/v1';   // Web/Desktop default

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF14B8A6);
}
