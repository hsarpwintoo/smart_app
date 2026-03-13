import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //  Firebase initialisation 
  // Replace placeholder values in firebase_options.dart, OR run:
  //   flutterfire configure
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

//  App entry 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Check-in',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}

//  Theme 

class AppTheme {
  static const Color deepNavy      = Color(0xFF0D1B40);
  static const Color midBlue       = Color(0xFF1A3A7C);
  static const Color electricBlue  = Color(0xFF4361EE);
  static const Color accent        = Color(0xFF4CC9F0);
  static const Color lightScaffold = Color(0xFFF0F2FF);

  static ThemeData light() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: deepNavy,
      brightness: Brightness.light,
    );

    final colorScheme = baseScheme.copyWith(
      primary: deepNavy,
      secondary: electricBlue,
      tertiary: accent,
      surface: lightScaffold,
    );

    final baseTextTheme = ThemeData(useMaterial3: true).textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightScaffold,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: deepNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: electricBlue, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 56),
          shape: buttonShape,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: electricBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 56),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 56),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 56),
          shape: buttonShape,
        ),
      ),
    );
  }
}
