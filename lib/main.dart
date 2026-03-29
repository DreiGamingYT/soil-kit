import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/home_screen.dart';
import 'models/settings_service.dart';

void main() {
  WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  runApp(const SoilApp());
}

// ── Design Tokens ─────────────────────────────────────────────────────────────
class SoilColors {
  SoilColors._();
  static const primary      = Color(0xFF2C5F2E);
  static const primaryMid   = Color(0xFF4A8C4D);
  static const primaryLight = Color(0xFFEAF3EA);
  static const bgLight      = Color(0xFFF7F4EF);
  static const bgDark       = Color(0xFF0E160E);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark  = Color(0xFF172017);
  static const surfaceElevDark = Color(0xFF1F2D1F);
  static const border       = Color(0x14000000);
  static const low          = Color(0xFFEF4444);
  static const medium       = Color(0xFFF59E0B);
  static const high         = Color(0xFF22C55E);
}

class Sr { // Spacing & Radius shorthand
  Sr._();
  static const xs = 4.0; static const sm = 8.0; static const md = 16.0;
  static const lg = 24.0; static const xl = 32.0; static const xxl = 48.0;
  static const rSm = 10.0; static const rMd = 16.0; static const rLg = 24.0;
  static const rPill = 100.0;
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
          title: 'SoilMate', debugShowCheckedModeBanner: false,
          themeMode: mode, theme: _light(), darkTheme: _dark(),
          home: const MainScaffold(),
        ),
      ),
    );
  }

  static const _titleStyle = TextStyle(
      fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5);

  ThemeData _light() => ThemeData(
    useMaterial3: true, brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: SoilColors.primary,
        primary: SoilColors.primary, surface: SoilColors.surfaceLight)
        .copyWith(surface: SoilColors.surfaceLight,
        surfaceContainerHighest: const Color(0xFFF0EDE8),
        outline: const Color(0xFFE0DBD4)),
    scaffoldBackgroundColor: SoilColors.bgLight,
    appBarTheme: AppBarTheme(backgroundColor: SoilColors.bgLight,
        elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        titleTextStyle: _titleStyle.copyWith(color: const Color(0xFF1A1A1A)),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        systemOverlayStyle: SystemUiOverlayStyle.dark),
    cardTheme: CardThemeData(elevation: 0, color: SoilColors.surfaceLight,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sr.rLg),
            side: const BorderSide(color: SoilColors.border)),
        margin: EdgeInsets.zero),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: SoilColors.primary, foregroundColor: Colors.white,
        elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sr.rPill)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: SoilColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        side: const BorderSide(color: SoilColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sr.rPill)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
    inputDecorationTheme: InputDecorationTheme(filled: true,
        fillColor: SoilColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Sr.rMd),
            borderSide: const BorderSide(color: SoilColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Sr.rMd),
            borderSide: const BorderSide(color: SoilColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Sr.rMd),
            borderSide: const BorderSide(color: SoilColors.primary, width: 1.5)),
        hintStyle: const TextStyle(color: Color(0xFFAEAEAE), fontSize: 14)),
    dividerTheme: const DividerThemeData(color: SoilColors.border, thickness: 1, space: 1),
    switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? SoilColors.primary : Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                ? SoilColors.primaryLight : const Color(0xFFE0E0E0))),
  );

  ThemeData _dark() => ThemeData(
    useMaterial3: true, brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: SoilColors.primary,
        primary: const Color(0xFF7DB560), brightness: Brightness.dark)
        .copyWith(surface: SoilColors.surfaceDark,
        surfaceContainerHighest: SoilColors.surfaceElevDark,
        outline: const Color(0xFF2A3A2A),
        onSurface: const Color(0xFFE8EAE8)),
    scaffoldBackgroundColor: SoilColors.bgDark,
    appBarTheme: AppBarTheme(backgroundColor: SoilColors.bgDark,
        elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
        titleTextStyle: _titleStyle.copyWith(color: const Color(0xFFE8EAE8)),
        iconTheme: const IconThemeData(color: Color(0xFFE8EAE8)),
        systemOverlayStyle: SystemUiOverlayStyle.light),
    cardTheme: CardThemeData(elevation: 0, color: SoilColors.surfaceDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sr.rLg),
            side: const BorderSide(color: Color(0xFF2A3A2A))),
        margin: EdgeInsets.zero),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A8C4D), foregroundColor: Colors.white,
        elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sr.rPill)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
    inputDecorationTheme: InputDecorationTheme(filled: true,
        fillColor: SoilColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Sr.rMd),
            borderSide: const BorderSide(color: Color(0xFF2A3A2A))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Sr.rMd),
            borderSide: const BorderSide(color: Color(0xFF2A3A2A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Sr.rMd),
            borderSide: const BorderSide(color: Color(0xFF7DB560), width: 1.5)),
        hintStyle: const TextStyle(color: Color(0xFF5A6A5A), fontSize: 14)),
    dividerTheme: const DividerThemeData(color: Color(0xFF2A3A2A), thickness: 1, space: 1),
    switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? const Color(0xFF7DB560) : Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                ? const Color(0xFF2D4A2F) : const Color(0xFF2A2A2A))),
  );
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => FlutterNativeSplash.remove());
  }
  @override
  Widget build(BuildContext context) => HomeScreen(
      selectedIndex: _selectedIndex,
      onNavTap: (i) => setState(() => _selectedIndex = i));
}