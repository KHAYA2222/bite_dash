// providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

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
  // Init
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
        // Init FCM — save token to Firestore, wire up foreground handler
        NotificationService().init(firebaseUser.uid);
        NotificationService().onForegroundMessage = (title, body) {
          NotificationOverlay.show(title, body);
        };
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Load profile
  // ---------------------------------------------------------------------------
  Future<void> _loadUserProfile(String uid) async {
    await _safeCall(() async {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromJson({...doc.data()!, 'id': doc.id});
      } else {
        final fbUser = _auth.currentUser!;
        _currentUser = UserModel(
          id: fbUser.uid,
          name: fbUser.displayName ?? _nameFromEmail(fbUser.email ?? ''),
          email: fbUser.email ?? '',
          createdAt: DateTime.now(),
        );
        await _writeUserDocument(_currentUser!);
      }
    }, fallback: () {
      final fbUser = _auth.currentUser;
      if (fbUser != null) {
        _currentUser = UserModel(
          id: fbUser.uid,
          name: fbUser.displayName ?? _nameFromEmail(fbUser.email ?? ''),
          email: fbUser.email ?? '',
          createdAt: DateTime.now(),
        );
      }
    });
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

    bool success = false;
    await _safeCall(() async {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      success = true;
    }, onError: (msg) => _setError(msg));

    _setLoading(false);
    return success;
  }

  // ---------------------------------------------------------------------------
  // Sign Up — two completely independent safe calls so no Firebase type
  // is ever held as a nullable across scope boundaries (web JS issue).
  // ---------------------------------------------------------------------------
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    // ── Step 1: Create Auth account ──────────────────────────────────────────
    String? uid;
    await _safeCall(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      uid = cred.user!.uid;
      await cred.user!.updateDisplayName(name.trim());
      debugPrint('[Auth] Account created: $uid');
    }, onError: (msg) {
      _setError(msg);
    });

    if (uid == null) {
      _setLoading(false);
      return false;
    }

    // ── Step 2: Write Firestore document (non-fatal if it fails) ─────────────
    await _safeCall(() async {
      final user = UserModel(
        id: uid!,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
        createdAt: DateTime.now(),
      );
      await _writeUserDocument(user);
      debugPrint('[Auth] Firestore doc written for $uid');
    });
    // Non-fatal — authStateChanges() will still log the user in

    _setLoading(false);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Write Firestore user document
  // ---------------------------------------------------------------------------
  Future<void> _writeUserDocument(UserModel user) async {
    final data = Map<String, dynamic>.from(user.toJson())..remove('id');
    await _db
        .collection('users')
        .doc(user.id)
        .set(data, SetOptions(merge: true));
    debugPrint('[Auth] users/${user.id} written');
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    _setLoading(true);
    await _safeCall(() async {
      final uid = _currentUser?.id;
      await _auth.signOut();
      if (uid != null) await NotificationService().clearToken(uid);
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    });
    _setLoading(false);
    notifyListeners();
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
    bool success = false;
    await _safeCall(() async {
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
      success = true;
    }, onError: (_) => _setError('Failed to update profile.'));
    _setLoading(false);
    return success;
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------
  Future<bool> sendPasswordReset(String email) async {
    bool success = false;
    await _safeCall(() async {
      await _auth.sendPasswordResetEmail(email: email.trim());
      success = true;
    }, onError: (msg) => _setError(msg));
    return success;
  }

  // ---------------------------------------------------------------------------
  // _safeCall — the web-compatible error wrapper.
  //
  // On Flutter Web, Firebase throws raw JavaScript objects that are NOT
  // Dart types. You cannot use "on FirebaseAuthException" or even
  // "e is FirebaseAuthException" reliably. The only safe approach is:
  //
  //   1. Catch everything as Object (not Exception or Error)
  //   2. Convert .toString() to extract the Firebase error code
  //   3. Never hold a Firebase type as nullable across try/catch scope
  // ---------------------------------------------------------------------------
  Future<void> _safeCall(
    Future<void> Function() action, {
    void Function(String message)? onError,
    void Function()? fallback,
  }) async {
    try {
      await action();
    } catch (e, stack) {
      debugPrint('[Auth] Error: $e');
      debugPrint('[Auth] Stack: $stack');
      fallback?.call();
      onError?.call(_parseError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Parse any exception type into a user-friendly message.
  // Works by converting to String — the only reliable approach on web.
  // ---------------------------------------------------------------------------
  String _parseError(Object e) {
    final raw = e.toString().toLowerCase();

    // Map of Firebase error code substrings → friendly messages
    final Map<String, String> errorMap = {
      'user-not-found': 'No account found with this email.',
      'wrong-password': 'Incorrect email or password.',
      'invalid-credential': 'Incorrect email or password.',
      'email-already-in-use': 'An account already exists with this email.',
      'weak-password': 'Password is too weak. Minimum 6 characters.',
      'invalid-email': 'Please enter a valid email address.',
      'user-disabled': 'This account has been disabled.',
      'too-many-requests': 'Too many attempts. Try again later.',
      'network-request-failed': 'No internet connection.',
      'permission-denied': 'Permission denied. Check Firestore rules.',
      'unavailable': 'Service unavailable. Try again.',
      'not-found': 'Account not found.',
      'expired-action-code': 'This link has expired.',
      'invalid-action-code': 'This link is invalid.',
    };

    for (final entry in errorMap.entries) {
      if (raw.contains(entry.key)) return entry.value;
    }

    return 'Something went wrong. Please try again.';
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
