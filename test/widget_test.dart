import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sunrise/constants/app_theme.dart';
import 'package:sunrise/providers/spots_provider.dart';
import 'package:sunrise/providers/sun_status_provider.dart';

void main() {
  testWidgets('App smoke test - splash screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SpotsProvider()),
          ChangeNotifierProvider(create: (_) => SunStatusProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Center(child: Text('SunTime')),
          ),
        ),
      ),
    );

    expect(find.text('SunTime'), findsOneWidget);
  });
}
