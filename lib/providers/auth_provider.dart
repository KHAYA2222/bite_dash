// providers/auth_provider.dart
//
// Mock auth with simulated network delay.
// To integrate Firebase, replace the body of each method with:
//   FirebaseAuth.instance.signInWithEmailAndPassword(...)
//   FirebaseAuth.instance.createUserWithEmailAndPassword(...)
//   FirebaseAuth.instance.signOut()
// And listen to authStateChanges() stream instead of _currentUser.

import 'package:flutter/material.dart';
import '../models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _errorMessage;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

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
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1200));

      // --- Mock validation ---
      if (email.isEmpty || password.isEmpty) {
        _setError('Please fill in all fields.');
        return false;
      }
      if (!_isValidEmail(email)) {
        _setError('Please enter a valid email address.');
        return false;
      }
      if (password.length < 6) {
        _setError('Password must be at least 6 characters.');
        return false;
      }

      // Mock: any valid-looking credentials succeed
      _currentUser = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameFromEmail(email),
        email: email,
        deliveryAddress: '123 Greenway Avenue, Johannesburg',
        createdAt: DateTime.now(),
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;

      // --- Firebase replacement ---
      // final cred = await FirebaseAuth.instance
      //     .signInWithEmailAndPassword(email: email, password: password);
      // final doc = await FirebaseFirestore.instance
      //     .collection('users').doc(cred.user!.uid).get();
      // _currentUser = UserModel.fromJson({...doc.data()!, 'id': doc.id});
      // _status = AuthStatus.authenticated;
      // notifyListeners();
      // return true;
    } catch (e) {
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

    try {
      await Future.delayed(const Duration(milliseconds: 1400));

      if (name.trim().isEmpty) {
        _setError('Please enter your name.');
        return false;
      }
      if (!_isValidEmail(email)) {
        _setError('Please enter a valid email address.');
        return false;
      }
      if (password.length < 6) {
        _setError('Password must be at least 6 characters.');
        return false;
      }

      _currentUser = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone?.trim(),
        createdAt: DateTime.now(),
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;

      // --- Firebase replacement ---
      // final cred = await FirebaseAuth.instance
      //     .createUserWithEmailAndPassword(email: email, password: password);
      // final user = UserModel(id: cred.user!.uid, name: name, email: email,
      //     phone: phone, createdAt: DateTime.now());
      // await FirebaseFirestore.instance
      //     .collection('users').doc(user.id).set(user.toJson());
      // _currentUser = user;
      // _status = AuthStatus.authenticated;
      // notifyListeners();
      // return true;
    } catch (e) {
      _setError('Sign up failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _setLoading(false);
    notifyListeners();
    // Firebase: await FirebaseAuth.instance.signOut();
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
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = _currentUser!.copyWith(
      name: name,
      phone: phone,
      deliveryAddress: deliveryAddress,
    );
    _setLoading(false);
    notifyListeners();
    return true;
    // Firebase: update Firestore doc + FirebaseAuth.instance.currentUser?.updateDisplayName(name)
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

  bool _isValidEmail(String e) =>
      RegExp(r'^[\w\-.]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(e.trim());

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
