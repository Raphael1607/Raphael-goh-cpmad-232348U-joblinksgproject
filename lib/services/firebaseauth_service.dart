import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _fbAuth = FirebaseAuth.instance;

  // Sign In
  Future<User?> signIn({String? email, String? password}) async {
    try {
      final ucred = await _fbAuth.signInWithEmailAndPassword(
        email: email!,
        password: password!,
      );
      final user = ucred.user;
      debugPrint("Signed in. uid: ${user?.uid}");
      return user;
    } on FirebaseAuthException catch (e) {
 
      debugPrint('signIn failed: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('signIn error: $e');
      return null;
    }
  }

  // Sign Up
  Future<User?> signUp({String? email, String? password}) async {
    try {
      final ucred = await _fbAuth.createUserWithEmailAndPassword(
        email: email!,
        password: password!,
      );
      final user = ucred.user;
      debugPrint('Signed up. uid: ${user?.uid}');
      return user;
    } on FirebaseAuthException catch (e) {
 
      debugPrint('signUp failed: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('signUp error: $e');
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _fbAuth.signOut();
  }
}
