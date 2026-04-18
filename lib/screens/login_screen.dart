import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService.instance;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _isRegister = false; // toggles between Login and Register

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _saveToken() {
    // Save FCM token now that we know the user's UID.
    // Navigation is handled by AuthGate's StreamBuilder automatically.
    NotificationService.instance.saveTokenForCurrentUser();
  }

  Future<void> _emailSubmit() async {
    setState(() => _loading = true);
    try {
      final user = _isRegister
          ? await _auth.registerWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text.trim())
          : await _auth.signInWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text.trim());
      if (user != null && mounted) _saveToken();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    try {
      final user = await _auth.signInWithGoogle();
      if (user != null && mounted) _saveToken();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _facebookLogin() async {
    setState(() => _loading = true);
    try {
      final user = await _auth.signInWithFacebook();
      if (user != null && mounted) _saveToken();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Logo / title
              const Text(
                '🌱 SoilMate',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                _isRegister ? 'Create an account' : 'Welcome back',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: cs.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(height: 36),

              // Email field
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Password field
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),

              // Email submit button
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _emailSubmit,
                  child: Text(_isRegister ? 'Create Account' : 'Login'),
                ),

              const SizedBox(height: 12),

              // Toggle register/login
              TextButton(
                onPressed: () =>
                    setState(() => _isRegister = !_isRegister),
                child: Text(
                  _isRegister
                      ? 'Already have an account? Login'
                      : "Don't have an account? Register",
                  style: TextStyle(color: SoilColors.primary),
                ),
              ),

              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Divider(color: cs.outline)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or',
                      style: TextStyle(
                          color: cs.onSurface.withOpacity(0.4),
                          fontSize: 12)),
                ),
                Expanded(child: Divider(color: cs.outline)),
              ]),
              const SizedBox(height: 16),

              // Google button
              OutlinedButton.icon(
                onPressed: _loading ? null : _googleLogin,
                icon: Image.asset(
                  'assets/google_logo.png',
                  width: 20,
                  height: 20,
                ),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 10),

              // Facebook button
              OutlinedButton.icon(
                onPressed: _loading ? null : _facebookLogin,
                icon: const Icon(
                  Icons.facebook,
                  color: Color(0xFF1877F2),
                  size: 23,
                ),
                label: const Text('Continue with Facebook'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}