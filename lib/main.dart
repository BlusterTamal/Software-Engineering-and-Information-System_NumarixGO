/*
 * File: lib/main.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/main.dart
 * Description: Main entry point for Smart Numerix app with theme management and Hive initialization
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'app_themes.dart';
import 'theme_provider.dart';
import 'welcome_page.dart';
import 'home_page.dart';
import 'features/cost_calculator_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  Hive.registerAdapter(ExpenseAdapter());
  await Hive.openBox<Expense>('expenses');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const SmartNumerixApp(),
    ),
  );
}

class SmartNumerixApp extends StatelessWidget {
  const SmartNumerixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Smart Numerix',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('bn', 'BD'),
          ],
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeNotifier.themeMode,
          home: const WelcomePage(),
          routes: {
            '/home': (context) => const HomePage(),
            '/welcome': (context) => const WelcomePage(),
          },
          builder: (context, child) {
            ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
              return Material(
                child: Container(
                  color: const Color(0xFF16213E),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
                          const SizedBox(height: 16),
                          const Text(
                            'Something went wrong!',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${errorDetails.exception}',
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            };
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}