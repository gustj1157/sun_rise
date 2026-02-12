import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'providers/spots_provider.dart';
import 'providers/sun_status_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SunTimeApp());
}

class SunTimeApp extends StatelessWidget {
  const SunTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SpotsProvider()),
        ChangeNotifierProvider(create: (_) => SunStatusProvider()),
      ],
      child: MaterialApp(
        title: 'SunTime Korea',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
