import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';

// Providers
import 'core/providers/auth_provider.dart';
import 'core/providers/community_provider.dart';
import 'core/providers/announcement_provider.dart';
import 'core/providers/maintenance_provider.dart';
import 'core/providers/dues_provider.dart';
import 'core/providers/meeting_provider.dart';
import 'core/providers/poll_provider.dart';
import 'core/providers/message_provider.dart';
import 'core/providers/dashboard_provider.dart';
import 'core/providers/notification_provider.dart';

// Entry screen
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent storage and API service
  final storageService = await StorageService.init();
  final apiService = ApiService(storageService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService, storageService)),
        ChangeNotifierProvider(create: (_) => CommunityProvider(apiService, storageService)),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider(apiService)),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider(apiService)),
        ChangeNotifierProvider(create: (_) => DuesProvider(apiService)),
        ChangeNotifierProvider(create: (_) => MeetingProvider(apiService)),
        ChangeNotifierProvider(create: (_) => PollProvider(apiService)),
        ChangeNotifierProvider(create: (_) => MessageProvider(apiService)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(apiService)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(apiService)),
      ],
      child: const RezidansProApp(),
    ),
  );
}

class RezidansProApp extends StatelessWidget {
  const RezidansProApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: AppConfig.storeTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: auth.isAuthenticated ? const MainNavigationScreen() : const OnboardingScreen(),
    );
  }
}
