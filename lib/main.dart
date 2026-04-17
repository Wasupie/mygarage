import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/home_screen.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

/// MyGarage - Vehicle Maintenance Tracker
/// Track vehicles, maintenance, fuel, and modifications
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize local notifications (skip on web).
  if (!kIsWeb) {
    try {
      await NotificationService.initialize();
    } catch (_) {
      // Notifications are optional; don't block app start.
    }
  }
  
  runApp(const MyGarageApp());
}

class MyGarageApp extends StatelessWidget {
  const MyGarageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyGarage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
