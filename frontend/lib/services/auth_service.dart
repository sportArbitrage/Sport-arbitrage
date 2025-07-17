import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/user.dart';
import 'api_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthService extends ChangeNotifier {
  // Enable this flag for development mode to bypass authentication
  static const bool DEV_MODE = true;
  
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiService _apiService = ApiService();
  
  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;
  String _error = '';

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isAuthenticated => DEV_MODE || _firebaseUser != null;

  // Constructor sets up auth state listener
  AuthService() {
    if (DEV_MODE) {
      _user = UserModel(
        id: 1,
        email: 'dev@example.com',
        firebaseUid: 'dev-firebase-uid',
        isActive: true,
        isAdmin: true,
        displayName: 'Development User',
        selectedBookmakers: ['Bet9ja', '1xBet', 'BetKing'],
        minProfitPercentage: 2.0,
        totalStakeAmount: 10000.0,
        notificationPreferences: {
          'email': true,
          'push': true,
          'minProfitThreshold': 3.0
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    } else {
      _firebaseAuth.authStateChanges().listen((User? user) {
        _firebaseUser = user;
        if (user != null) {
          _loadUserData();
        } else {
          _user = null;
        }
        notifyListeners();
      });
    }
  }

  // Load user data from backend API
  Future<void> _loadUserData() async {
    if (DEV_MODE) return; // Skip in dev mode
    
    if (_firebaseUser == null) return;
    
    try {
      _setLoading(true);
      final idToken = await _firebaseUser!.getIdToken();
      final response = await _apiService.get('/users/me', token: idToken);
      
      if (response.statusCode == 200) {
        _user = UserModel.fromJson(json.decode(response.body));
      } else {
        _setError('Failed to load user data');
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Register with email/password
  Future<bool> registerWithEmail(String email, String password) async {
    if (DEV_MODE) {
      // In dev mode, just simulate successful registration
      return true;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      // Create user in Firebase
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Send verification email
      await userCredential.user!.sendEmailVerification();
      
      // Register with backend
      final idToken = await userCredential.user!.getIdToken();
      await _apiService.post(
        '/users/register',
        body: {
          'email': email,
          'firebase_uid': userCredential.user!.uid,
        },
        token: idToken,
      );
      
      // Sign out until email verified
      await _firebaseAuth.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email address is already in use.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        default:
          errorMessage = 'Registration failed. Please try again.';
      }
      
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('Registration error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign in with email/password
  Future<bool> signInWithEmail(String email, String password) async {
    if (DEV_MODE) {
      // In dev mode, just simulate successful login
      return true;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        _setError('Please verify your email before logging in.');
        await _firebaseAuth.signOut();
        return false;
      }
      
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }
      
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('Login error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    if (DEV_MODE) {
      // In dev mode, just simulate successful login
      return true;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      // Begin Google sign in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        _setError('Google sign in aborted.');
        return false;
      }
      
      // Obtain auth details from Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with credential
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      // Register with backend if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final idToken = await userCredential.user!.getIdToken();
        await _apiService.post(
          '/users/register',
          body: {
            'email': userCredential.user!.email,
            'firebase_uid': userCredential.user!.uid,
            'display_name': userCredential.user!.displayName,
            'photo_url': userCredential.user!.photoURL,
          },
          token: idToken,
        );
      }
      
      return true;
    } catch (e) {
      _setError('Google sign in error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    if (DEV_MODE) {
      // Do nothing in dev mode
      return;
    }
    
    try {
      _setLoading(true);
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      _setError('Sign out error: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Password reset
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _setError('Password reset error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = '';
    notifyListeners();
  }
} 