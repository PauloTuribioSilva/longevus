import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://agnkeblitolgqoorvjtv.supabase.co',
    anonKey: 'sb_publishable_JUPag2sFklfF3krc4OU0tA_HmryIQoc',
  );

  runApp(const LongevusApp());
}

class LongevusApp extends StatelessWidget {
  const LongevusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Longevus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}