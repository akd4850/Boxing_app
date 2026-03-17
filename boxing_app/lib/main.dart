import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const BoxingApp());
}

class BoxingApp extends StatelessWidget {
  const BoxingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boxing App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A9EA1)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('ja'),
        Locale('zh'),
      ],
      locale: const Locale('ko'),
      home: const MainScreen(),
    );
  }
}
