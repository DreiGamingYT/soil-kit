import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:soilmate/services/soil_data_service.dart';
import 'screens/auth_gate.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';

// If you used FlutterFire CLI, uncomment this:
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await Firebase.initializeApp(
    // If you used FlutterFire CLI, use this instead:
    options: DefaultFirebaseOptions.currentPlatform,
  );

  NotificationService.instance.init();

  await SoilDataService.instance.loadFromLocal();

  runApp(const SoilApp());
}

// ── Earthy Organic Design Tokens ─────────────────────────────────────────────
class SoilColors {
  SoilColors._();

  static const primary      = Color(0xFF3A5C38);
  static const primaryMid   = Color(0xFF5A8A55);
  static const primaryLight = Color(0xFFDCEBD9);
  static const primaryDark  = Color(0xFF7DB878);

  static const bgLight      = Color(0xFFF4EFE6);
  static const bgDark       = Color(0xFF131A11);

  static const surfaceLight      = Color(0xFFFEFCF7);
  static const surfaceDark       = Color(0xFF1C2A1A);
  static const surfaceElevLight  = Color(0xFFEDE6D9);
  static const surfaceElevDark   = Color(0xFF243222);

  static const borderLight = Color(0xFFD9D0C3);
  static const borderDark  = Color(0xFF293D27);

  static const clay    = Color(0xFFA07558);
  static const harvest = Color(0xFFBF903E);

  static const low    = Color(0xFFB84B38);
  static const medium = Color(0xFFBF903E);
  static const high   = Color(0xFF4A8A46);
}

class Sr {
  Sr._();
  static const xs = 4.0;  static const sm = 8.0;   static const md = 16.0;
  static const lg = 24.0; static const xl = 32.0;  static const xxl = 48.0;
  static const rXs = 8.0; static const rSm = 12.0; static const rMd = 18.0;
  static const rLg = 24.0; static const rXl = 32.0; static const rPill = 100.0;
}

class SoilApp extends StatelessWidget {
  const SoilApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SettingsService.instance;
    return ValueListenableBuilder<String>(
      valueListenable: s.language,
      builder: (_, __, ___) => ValueListenableBuilder<ThemeMode>(
        valueListenable: s.themeMode,
        builder: (_, mode, __) => MaterialApp(
          title: 'SoilMate',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: _light(),
          darkTheme: _dark(),
          home: const AuthGate(),
        ),
      ),
    );
  }

  static const _headStyle = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.6,
  );

  ThemeData _light() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: SoilColors.primary,
      primary: SoilColors.primary,
      surface: SoilColors.surfaceLight,
    ).copyWith(
      surface: SoilColors.surfaceLight,
      surfaceContainerHighest: SoilColors.surfaceElevLight,
      outline: SoilColors.borderLight,
      onSurface: const Color(0xFF1E2518),
    ),
    scaffoldBackgroundColor: SoilColors.bgLight,
    appBarTheme: AppBarTheme(
      backgroundColor: SoilColors.bgLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: _headStyle.copyWith(color: const Color(0xFF1E2518)),
      iconTheme: const IconThemeData(color: Color(0xFF1E2518)),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: SoilColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sr.rLg),
        side: const BorderSide(color: SoilColors.borderLight),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SoilColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sr.rMd)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SoilColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        side: const BorderSide(color: SoilColors.borderLight, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sr.rMd)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SoilColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sr.rSm),
        borderSide: const BorderSide(color: SoilColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sr.rSm),
        borderSide: const BorderSide(color: SoilColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sr.rSm),
        borderSide: const BorderSide(color: SoilColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFFB0A898), fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: SoilColors.borderLight, thickness: 1, space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? SoilColors.primary : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
            ? SoilColors.primaryLight
            : const Color(0xFFDDD5C8),
      ),
    ),
  );

  ThemeData _dark() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: SoilColors.primary,
      primary: SoilColors.primaryDark,
      brightness: Brightness.dark,
    ).copyWith(
      surface: SoilColors.surfaceDark,
      surfaceContainerHighest: SoilColors.surfaceElevDark,
      outline: SoilColors.borderDark,
      onSurface: const Color(0xFFE2DDD6),
    ),
    scaffoldBackgroundColor: SoilColors.bgDark,
    appBarTheme: AppBarTheme(
      backgroundColor: SoilColors.bgDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: _headStyle.copyWith(color: const Color(0xFFE2DDD6)),
      iconTheme: const IconThemeData(color: Color(0xFFE2DDD6)),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: SoilColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sr.rLg),
        side: const BorderSide(color: SoilColors.borderDark),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SoilColors.primaryMid,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sr.rMd)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SoilColors.primaryDark,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        side: const BorderSide(color: SoilColors.borderDark, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sr.rMd)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SoilColors.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sr.rSm),
        borderSide: const BorderSide(color: SoilColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sr.rSm),
        borderSide: const BorderSide(color: SoilColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sr.rSm),
        borderSide: const BorderSide(color: SoilColors.primaryDark, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF5A6A52), fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: SoilColors.borderDark, thickness: 1, space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? SoilColors.primaryDark : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
            ? const Color(0xFF2D4A2A)
            : const Color(0xFF2A2A2A),
      ),
    ),
  );
}
