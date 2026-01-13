import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import 'user_service.dart';

/// Authentication service to manage current user session with Firebase Auth
class AuthService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final UserService _userService = UserService();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    // Listen to auth state changes
    _firebaseAuth.authStateChanges().listen((firebase_auth.User? firebaseUser) {
      if (firebaseUser != null) {
        _loadUserData(firebaseUser.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      final user = await _userService.getUser(userId);
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  /// Sign up a new user with Firebase Auth
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user object
        final user = User(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        // Save to Firestore
        await _userService.createUser(user);

        // Update display name in Firebase Auth
        await userCredential.user!.updateDisplayName(name);

        // Set as current user
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Sign up error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in an existing user with Firebase Auth
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sign in with Firebase Auth
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update last login
        await _userService.updateLastLogin(userCredential.user!.uid);
        
        // Load user data
        await _loadUserData(userCredential.user!.uid);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Sign in error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Password reset error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Password reset error: $e');
      return false;
    }
  }

  /// Get Firebase Auth error message
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      default:
        return 'An error occurred. Please try again';
    }
  }
}
