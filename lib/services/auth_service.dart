import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;

  // Stream for AuthGate
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // EMAIL — sign in
  Future<User?> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return result.user;
  }

  // EMAIL — register
  Future<User?> registerWithEmail(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = result.user;

    // Save the new account to Firestore so the app can read profile data
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid':       user.uid,
        'email':     user.email ?? '',
        'name':      user.email?.split('@').first ?? 'SoilMate User',
        'location':  '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  // GOOGLE
  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user != null) await _ensureFirestoreProfile(user);
    return user;
  }

  // FACEBOOK
  Future<User?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: ['public_profile', 'email'],
      loginTracking: LoginTracking.limited, // use limited if email still fails
    );
    if (result.status != LoginStatus.success) return null;
    final credential =
    FacebookAuthProvider.credential(result.accessToken!.tokenString);
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) await _ensureFirestoreProfile(user);
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
    // Stop listening for order status changes
    NotificationService.instance.stopOrderStatusListener();
  }

  User? get currentUser => _auth.currentUser;

  // Creates a Firestore profile only if one doesn't exist yet.
  // Safe to call on every login — uses merge: false via set with merge.
  Future<void> _ensureFirestoreProfile(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid':       user.uid,
        'email':     user.email ?? '',
        'name':      user.displayName ?? user.email?.split('@').first ?? 'SoilMate User',
        'location':  '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}