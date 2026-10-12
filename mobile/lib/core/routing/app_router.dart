import 'package:flutter/material.dart';

// Screens
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/join_building_screen.dart';
import '../../features/home/main_navigation_screen.dart';
import '../../features/announcements/announcements_screen.dart';
import '../../features/maintenance/report_fault_screen.dart';
import '../../features/building/building_info_screen.dart';
import '../../features/notifications/notifications_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/join-community':
        return MaterialPageRoute(builder: (_) => const JoinBuildingScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case '/announcements':
        return MaterialPageRoute(builder: (_) => const AnnouncementsScreen());
      case '/report-fault':
        return MaterialPageRoute(builder: (_) => const ReportFaultScreen());
      case '/building-info':
        return MaterialPageRoute(builder: (_) => const BuildingInfoScreen());
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
