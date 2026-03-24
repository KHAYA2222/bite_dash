// providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ---------------------------------------------------------------------------
  // Init — listens to Firebase auth state changes.
  // Called once in main.dart. Automatically restores session on app relaunch.
  // ---------------------------------------------------------------------------
  void init() {
    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      } else {
        await _loadUserProfile(firebaseUser.uid);
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Load user profile from Firestore
  // ---------------------------------------------------------------------------
  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromJson({...doc.data()!, 'id': doc.id});
      } else {
        // Firestore doc missing — build minimal profile from FirebaseAuth
        final fbUser = _auth.currentUser!;
        _currentUser = UserModel(
          id: fbUser.uid,
          name: fbUser.displayName ?? _nameFromEmail(fbUser.email ?? ''),
          email: fbUser.email ?? '',
          createdAt: DateTime.now(),
        );
        // Try to write the missing document
        await _writeUserDocument(_currentUser!);
      }
    } catch (e) {
      debugPrint('[AuthProvider] _loadUserProfile error: $e');
      // Build a minimal profile so the app doesn't crash
      final fbUser = _auth.currentUser;
      if (fbUser != null) {
        _currentUser = UserModel(
          id: fbUser.uid,
          name: fbUser.displayName ?? _nameFromEmail(fbUser.email ?? ''),
          email: fbUser.email ?? '',
          createdAt: DateTime.now(),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Sign In
  // ---------------------------------------------------------------------------
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // authStateChanges() listener handles the rest
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[AuthProvider] signIn FirebaseAuthException: ${e.code} — ${e.message}');
      _setError(_friendlyAuthError(e.code));
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] signIn unexpected error: $e');
      _setError('Sign in failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Up
  // ---------------------------------------------------------------------------
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    UserCredential? cred;

    try {
      // Step 1 — Create the Firebase Auth account
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('[AuthProvider] Auth account created: ${cred.user?.uid}');

      // Step 2 — Set display name in FirebaseAuth
      await cred.user?.updateDisplayName(name.trim());
      debugPrint('[AuthProvider] Display name set.');

      // Step 3 — Build the user model
      final user = UserModel(
        id: cred.user!.uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
        createdAt: DateTime.now(),
      );

      // Step 4 — Write Firestore document
      await _writeUserDocument(user);
      debugPrint('[AuthProvider] Firestore document written for ${user.id}');

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[AuthProvider] signUp FirebaseAuthException: ${e.code} — ${e.message}');
      _setError(_friendlyAuthError(e.code));
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] signUp unexpected error: $e');
      // Auth account was created but Firestore write failed.
      // The authStateChanges() listener will still log them in.
      // Return true so the user isn't stuck — their profile will
      // be created lazily in _loadUserProfile on next launch.
      if (cred != null) {
        debugPrint(
            '[AuthProvider] Auth succeeded but Firestore write failed. User will still be logged in.');
        return true;
      }
      _setError('Sign up failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Write user document to Firestore
  // ---------------------------------------------------------------------------
  Future<void> _writeUserDocument(UserModel user) async {
    final data = user.toJson()..remove('id'); // don't store id inside document
    await _db.collection('users').doc(user.id).set(data,
        SetOptions(merge: true)); // merge:true = safe to call multiple times
    debugPrint('[AuthProvider] users/${user.id} written: $data');
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _auth.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      debugPrint('[AuthProvider] Signed out.');
    } catch (e) {
      debugPrint('[AuthProvider] signOut error: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Update profile
  // ---------------------------------------------------------------------------
  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? deliveryAddress,
  }) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      final updates = <String, dynamic>{
        'name': name.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (deliveryAddress != null && deliveryAddress.trim().isNotEmpty)
          'deliveryAddress': deliveryAddress.trim(),
      };
      await _db.collection('users').doc(_currentUser!.id).update(updates);
      await _auth.currentUser?.updateDisplayName(name.trim());
      _currentUser = _currentUser!.copyWith(
        name: name.trim(),
        phone: phone,
        deliveryAddress: deliveryAddress,
      );
      notifyListeners();
      debugPrint('[AuthProvider] Profile updated: $updates');
      return true;
    } catch (e) {
      debugPrint('[AuthProvider] updateProfile error: $e');
      _setError('Failed to update profile. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('[AuthProvider] Password reset email sent to $email');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthProvider] sendPasswordReset error: ${e.code}');
      _setError(_friendlyAuthError(e.code));
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] sendPasswordReset unexpected: $e');
      _setError('Could not send reset email.');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() => _clearError();

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    return local
        .replaceAll(RegExp(r'[._\-]'), ' ')
        .split(' ')
        .map(
            (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ')
        .trim();
  }
}
