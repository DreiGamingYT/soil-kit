import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  void _goHome() {
    // Replace with your actual home screen
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _emailLogin() async {
    setState(() => _loading = true);
    try {
      final user = await _auth.signInWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text.trim());
      if (user != null) _goHome();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _loading = false);
  }

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    final user = await _auth.signInWithGoogle();
    if (user != null) _goHome();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('SoilMate', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator()
            else ...[
              ElevatedButton(onPressed: _emailLogin, child: const Text('Login with Email')),
              OutlinedButton(onPressed: _googleLogin, child: const Text('Login with Google')),
            ]
          ],
        ),
      ),
    );
  }
}