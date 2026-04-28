import 'package:flutter/material.dart';
import 'home_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) => HomeScreen(
    selectedIndex: _selectedIndex,
    onNavTap: (i) => setState(() => _selectedIndex = i),
  );
}