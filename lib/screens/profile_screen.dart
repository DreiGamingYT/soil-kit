import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/soil_data_service.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../widgets/bottom_nav.dart';
import 'faq_screen.dart' hide HelpGuideScreen;
import 'help_guide_screen.dart' hide AppBottomNav;
import 'login_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _svc = SoilDataService.instance;
  final _db  = FirebaseFirestore.instance;

  String _name     = '';
  String _email    = '';
  String _location = '';
  bool   _loading  = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Load profile from Firestore, fall back to Firebase Auth data.
  Future<void> _loadProfile() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data();
      setState(() {
        _name     = data?['name']     ?? user.displayName ?? user.email?.split('@').first ?? 'SoilMate User';
        _email    = data?['email']    ?? user.email ?? '';
        _location = data?['location'] ?? '';
        _loading  = false;
      });
    } catch (_) {
      // Fallback to auth data if Firestore fails
      setState(() {
        _name     = user.displayName ?? user.email?.split('@').first ?? 'SoilMate User';
        _email    = user.email ?? '';
        _location = '';
        _loading  = false;
      });
    }
  }

  /// Save profile to Firestore and update Firebase Auth display name.
  Future<void> _saveProfile(String name, String email, String location) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    // Update Firebase Auth display name
    if (name.isNotEmpty && name != user.displayName) {
      await user.updateDisplayName(name);
    }

    // Save to Firestore
    await _db.collection('users').doc(user.uid).set({
      'name':      name,
      'email':     email,
      'location':  location,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      _name     = name;
      _email    = email;
      _location = location;
    });
  }

  void _edit() {
    final nc = TextEditingController(text: _name);
    final ec = TextEditingController(text: _email);
    final lc = TextEditingController(text: _location);
    final cs = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setS) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cs.outline.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: nc,
                decoration: const InputDecoration(
                  hintText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ec,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lc,
                decoration: const InputDecoration(
                  hintText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        setS(() => saving = true);
                        try {
                          await _saveProfile(
                            nc.text.trim().isEmpty ? _name : nc.text.trim(),
                            ec.text.trim().isEmpty ? _email : ec.text.trim(),
                            lc.text.trim().isEmpty ? _location : lc.text.trim(),
                          );
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          messenger.showSnackBar(SnackBar(
                            content: const Row(children: [
                              Icon(Icons.check_circle_outline,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('Profile saved'),
                            ]),
                            backgroundColor: SoilColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Sr.rSm)),
                          ));
                        } catch (e) {
                          setS(() => saving = false);
                          messenger.showSnackBar(SnackBar(
                            content: Text('Failed to save: $e'),
                            backgroundColor: Colors.red,
                          ));
                        }
                      },
                      child: saving
                          ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sr.rXl),
        ),
        backgroundColor: cs.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: SoilColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 32,
                      color: SoilColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SoilMate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: cs.outline),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      'GTECH SOLUTION COMPANY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...[
                      ['CEO', 'Bolatin, Alexa'],
                      ['Product/Marketing', 'Garde, Denise Kenchien'],
                      ['Content', 'Dayna, John Mark'],
                      ['Tech Lead', 'Velasco, Jonathan'],
                      ['UI/UX', 'Suagen, Allysa Jasmin'],
                      ['Developer', 'De Guzman, Maenalyn'],
                      ['Finance', 'Ilagor, Paul John'],
                      ['Documentation', 'Malabiga, Yui Rave'],
                      ['Records', 'Siarot, Reydin'],
                      ['Research & Feature', 'Anza Jr., Jonathan'],
                      ['Quality & Testing', 'Delos Reyes, Jonel'],
                    ].map((r) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                r[0],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                r[1],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFaq() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaqScreen()),
    );
  }

  void _openGuide() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpGuideScreen()),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SoilColors.primary,
                      SoilColors.primaryMid,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(Sr.rXl),
                  boxShadow: [
                    BoxShadow(
                      color: SoilColors.primary.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 38,
                                color: Colors.white,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _edit,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 13,
                                    color: SoilColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.82),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _location,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.82),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _StatCard(
                          value: '${_svc.resultsCount}',
                          label: 'Analyses',
                          icon: Icons.science_outlined,
                          cs: cs,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          value: '${_svc.notesCount}',
                          label: 'Notes',
                          icon: Icons.edit_note_rounded,
                          cs: cs,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          value: '1',
                          label: 'Fields',
                          icon: Icons.terrain_outlined,
                          cs: cs,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _Section(
                label: 'Account',
                cs: cs,
                items: [
                  _MenuRow(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    subtitle: 'Update your name, email, and location',
                    onTap: _edit,
                  ),
                  _MenuRow(
                    icon: Icons.tune_rounded,
                    label: 'Settings',
                    subtitle: 'Theme, language, and units',
                    onTap: _openSettings,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _Section(
                label: 'Support',
                cs: cs,
                items: [
                  _MenuRow(
                    icon: Icons.help_outline_rounded,
                    label: 'FAQ',
                    subtitle: 'Common questions and answers',
                    onTap: _openFaq,
                  ),
                  _MenuRow(
                    icon: Icons.menu_book_outlined,
                    label: 'Help & Guide',
                    subtitle: 'How to use SoilMate',
                    onTap: _openGuide,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _Section(
                label: 'App',
                cs: cs,
                items: [
                  _MenuRow(
                    icon: Icons.info_outline_rounded,
                    label: 'About SoilMate',
                    subtitle: 'Version and developer info',
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sr.rMd),
                    ),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Sr.rLg),
                        ),
                        title: const Text('Sign out?',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        content: const Text(
                            'You will be returned to the login screen.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      await AuthService.instance.signOut();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: 0,
        onTap: (_) => Navigator.pop(context),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final ColorScheme cs;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.11),
          borderRadius: BorderRadius.circular(Sr.rMd),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Colors.white.withOpacity(0.95)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  final List<Widget> items;

  const _Section({
    required this.label,
    required this.cs,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: SoilColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: cs.onSurface.withOpacity(0.38),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(Sr.rLg),
            border: Border.all(color: cs.outline),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final last = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!last)
                    Divider(
                      height: 1,
                      color: cs.outline.withOpacity(0.6),
                      indent: 52,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: SoilColors.primaryLight.withOpacity(0.65),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          size: 18,
          color: SoilColors.primary.withOpacity(0.82),
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurface.withOpacity(0.42),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 13,
        color: cs.onSurface.withOpacity(0.22),
      ),
      onTap: onTap,
    );
  }
}