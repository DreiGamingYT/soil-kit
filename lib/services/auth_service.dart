import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    return result.user;
  }

  // FACEBOOK
  Future<User?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success) return null;
    final credential =
    FacebookAuthProvider.credential(result.accessToken!.tokenString);
    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
  }

  User? get currentUser => _auth.currentUser;
}