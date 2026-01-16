

library;

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final bool isAnonymous;
  final DateTime? createdAt;
  final DateTime? lastSignIn;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.isAnonymous = false,
    this.createdAt,
    this.lastSignIn,
  });

  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime,
      lastSignIn: user.metadata.lastSignInTime,
    );
  }

  factory AppUser.guest() {
    return AppUser(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      isAnonymous: true,
      createdAt: DateTime.now(),
    );
  }

  bool get isGuest => isAnonymous || uid.startsWith('guest_');

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'emailVerified': emailVerified,
        'isAnonymous': isAnonymous,
      };

  @override
  String toString() => 'AppUser(uid: $uid, email: $email, isGuest: $isGuest)';
}

enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class FirebaseAuthService {
  static FirebaseAuthService? _instance;
  static FirebaseAuthService get instance {
    _instance ??= FirebaseAuthService._();
    return _instance!;
  }

  FirebaseAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateStream => _authStateController.stream;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  AuthState _authState = AuthState.initial;
  AuthState get authState => _authState;

  Future<void> initialize() async {
    try {

      _auth.authStateChanges().listen((User? user) {
        if (user != null) {
          _currentUser = AppUser.fromFirebaseUser(user);
          _setAuthState(AuthState.authenticated);
        } else {
          _currentUser = null;
          _setAuthState(AuthState.unauthenticated);
        }
      });

      final user = _auth.currentUser;
      if (user != null) {
        _currentUser = AppUser.fromFirebaseUser(user);
        _setAuthState(AuthState.authenticated);
      } else {

        final prefs = await SharedPreferences.getInstance();
        final isGuest = prefs.getBool(AppConstants.guestKey) ?? false;
        if (isGuest) {
          _currentUser = AppUser.guest();
          _setAuthState(AuthState.authenticated);
        } else {
          _setAuthState(AuthState.unauthenticated);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('FirebaseAuthService initialization error: $e');
      _setAuthState(AuthState.error);
      throw AuthException(
        message: 'Failed to initialize authentication',
        code: AuthException.unknown,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _setAuthState(AuthState state) {
    _authState = state;
    _authStateController.add(state);
  }

  Future<Result<AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setAuthState(AuthState.loading);

      final validationError = _validateCredentials(email, password);
      if (validationError != null) {
        _setAuthState(AuthState.unauthenticated);
        return Result.failure(validationError);
      }

      final credential = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            AppConstants.networkTimeout,
            onTimeout: () => throw const AuthException(
              message: 'Sign in timed out',
              code: AuthException.networkError,
            ),
          );

      if (credential.user == null) {
        _setAuthState(AuthState.unauthenticated);
        return Result.failure(const AuthException(
          message: 'Sign in failed - no user returned',
          code: AuthException.unknown,
        ));
      }

      await _saveSession(credential.user!);

      _currentUser = AppUser.fromFirebaseUser(credential.user!);
      _setAuthState(AuthState.authenticated);

      return Result.success(_currentUser!);
    } on FirebaseAuthException catch (e, stackTrace) {
      _setAuthState(AuthState.unauthenticated);
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } on AuthException catch (e) {
      _setAuthState(AuthState.unauthenticated);
      return Result.failure(e);
    } catch (e, stackTrace) {
      _setAuthState(AuthState.unauthenticated);
      return Result.failure(AuthException(
        message: 'An unexpected error occurred',
        code: AuthException.unknown,
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<Result<AppUser>> createAccountWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setAuthState(AuthState.loading);

      final validationError = _validateCredentials(email, password);
      if (validationError != null) {
        _setAuthState(AuthState.unauthenticated);
        return Result.failure(validationError);
      }

      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            AppConstants.networkTimeout,
            onTimeout: () => throw const AuthException(
              message: 'Registration timed out',
              code: AuthException.networkError,
            ),
          );

      if (credential.user == null) {
        _setAuthState(AuthState.unauthenticated);
        return Result.failure(const AuthException(
          message: 'Registration failed - no user returned',
          code: AuthException.unknown,
        ));
      }

      await _saveSession(credential.user!);

      _currentUser = AppUser.fromFirebaseUser(credential.user!);
      _setAuthState(AuthState.authenticated);

      return Result.success(_currentUser!);
    } on FirebaseAuthException catch (e, stackTrace) {
      _setAuthState(AuthState.unauthenticated);
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } on AuthException catch (e) {
      _setAuthState(AuthState.unauthenticated);
      return Result.failure(e);
    } catch (e, stackTrace) {
      _setAuthState(AuthState.unauthenticated);
      return Result.failure(AuthException(
        message: 'An unexpected error occurred',
        code: AuthException.unknown,
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<Result<AppUser>> continueAsGuest() async {
    try {
      _setAuthState(AuthState.loading);

      try {
        final credential = await _auth.signInAnonymously().timeout(
              AppConstants.networkTimeout,
              onTimeout: () => throw const AuthException(
                message: 'Anonymous sign in timed out',
                code: AuthException.networkError,
              ),
            );

        if (credential.user != null) {
          _currentUser = AppUser.fromFirebaseUser(credential.user!);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(AppConstants.guestKey, true);

          _setAuthState(AuthState.authenticated);
          return Result.success(_currentUser!);
        }
      } catch (e) {
        debugPrint('Firebase anonymous auth failed, using local guest: $e');
      }

      final guestUser = AppUser.guest();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.guestKey, true);
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userEmailKey);

      _currentUser = guestUser;
      _setAuthState(AuthState.authenticated);

      return Result.success(guestUser);
    } catch (e, stackTrace) {
      _setAuthState(AuthState.unauthenticated);
      return Result.failure(AuthException(
        message: 'Failed to continue as guest',
        code: AuthException.unknown,
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<Result<AppUser>> signInWithGoogle() async {
    try {
      _setAuthState(AuthState.loading);

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final credential = await _auth.signInWithPopup(googleProvider).timeout(
              const Duration(minutes: 2),
              onTimeout: () => throw const AuthException(
                message: 'Google sign in timed out',
                code: AuthException.networkError,
              ),
            );

        if (credential.user == null) {
          _setAuthState(AuthState.unauthenticated);
          return Result.failure(const AuthException(
            message: 'Google sign in failed - no user returned',
            code: AuthException.unknown,
          ));
        }

        await _saveSession(credential.user!);
        _currentUser = AppUser.fromFirebaseUser(credential.user!);
        _setAuthState(AuthState.authenticated);

        return Result.success(_currentUser!);
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {

        _setAuthState(AuthState.unauthenticated);
        return Result.failure(const AuthException(
          message: 'Sign in cancelled',
          code: AuthException.operationNotAllowed,
        ));
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(credential).timeout(
                const Duration(minutes: 2),
                onTimeout: () => throw const AuthException(
                  message: 'Google sign in timed out',
                  code: AuthException.networkError,
                ),
              );

      if (userCredential.user == null) {
        _setAuthState(AuthState.unauthenticated);
        return Result.failure(const AuthException(
          message: 'Google sign in failed - no user returned',
          code: AuthException.unknown,
        ));
      }

      await _saveSession(userCredential.user!);
      _currentUser = AppUser.fromFirebaseUser(userCredential.user!);
      _setAuthState(AuthState.authenticated);

      return Result.success(_currentUser!);
    } on FirebaseAuthException catch (e, stackTrace) {
      _setAuthState(AuthState.unauthenticated);
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      _setAuthState(AuthState.unauthenticated);
      return Result.failure(AuthException(
        message: 'Google sign in failed',
        code: AuthException.unknown,
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      if (!_isValidEmail(email)) {
        return Result.failure(const AuthException(
          message: 'Please enter a valid email address',
          code: AuthException.invalidEmail,
        ));
      }

      await _auth.sendPasswordResetEmail(email: email.trim()).timeout(
            AppConstants.networkTimeout,
            onTimeout: () => throw const AuthException(
              message: 'Request timed out',
              code: AuthException.networkError,
            ),
          );

      return Result.success(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(AuthException(
        message: 'Failed to send reset email',
        code: AuthException.unknown,
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  Future<Result<void>> signOut() async {
    try {
      _setAuthState(AuthState.loading);

      await _auth.signOut();
      await _clearSession();

      _currentUser = null;
      _setAuthState(AuthState.unauthenticated);

      return Result.success(null);
    } catch (e, stackTrace) {
      _setAuthState(AuthState.error);
      return Result.failure(AuthException(
        message: 'Failed to sign out',
        code: AuthException.unknown,
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  bool get isAuthenticated =>
      _currentUser != null && _authState == AuthState.authenticated;

  bool get isGuest => _currentUser?.isGuest ?? false;

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user != null) {
        _currentUser = AppUser.fromFirebaseUser(user);
      }
    } catch (e) {
      debugPrint('Failed to reload user: $e');
    }
  }

  ValidationException? _validateCredentials(String email, String password) {
    if (email.trim().isEmpty) {
      return const ValidationException(
        message: 'Email is required',
        field: 'email',
      );
    }
    if (!_isValidEmail(email)) {
      return const ValidationException(
        message: 'Please enter a valid email address',
        field: 'email',
      );
    }
    if (password.isEmpty) {
      return const ValidationException(
        message: 'Password is required',
        field: 'password',
      );
    }
    if (password.length < AppConstants.minPasswordLength) {
      return const ValidationException(
        message:
            'Password must be at least ${AppConstants.minPasswordLength} characters',
        field: 'password',
      );
    }
    return null;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  Future<void> _saveSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await user.getIdToken();
      if (token != null) {
        await prefs.setString(AppConstants.tokenKey, token);
      }
      await prefs.setString(AppConstants.userIdKey, user.uid);
      if (user.email != null) {
        await prefs.setString(AppConstants.userEmailKey, user.email!);
      }
      await prefs.setBool(AppConstants.guestKey, false);
    } catch (e) {
      debugPrint('Failed to save session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userEmailKey);
      await prefs.remove(AppConstants.guestKey);
    } catch (e) {
      debugPrint('Failed to clear session: $e');
    }
  }

  AuthException _mapFirebaseAuthException(
      FirebaseAuthException e, StackTrace stackTrace) {
    String code;
    switch (e.code) {
      case 'invalid-email':
        code = AuthException.invalidEmail;
        break;
      case 'user-disabled':
        code = AuthException.userDisabled;
        break;
      case 'user-not-found':
        code = AuthException.userNotFound;
        break;
      case 'wrong-password':
        code = AuthException.wrongPassword;
        break;
      case 'email-already-in-use':
        code = AuthException.emailAlreadyInUse;
        break;
      case 'weak-password':
        code = AuthException.weakPassword;
        break;
      case 'operation-not-allowed':
        code = AuthException.operationNotAllowed;
        break;
      case 'too-many-requests':
        code = AuthException.tooManyRequests;
        break;
      case 'network-request-failed':
        code = AuthException.networkError;
        break;
      default:
        code = AuthException.unknown;
    }

    return AuthException(
      message: e.message ?? 'Authentication failed',
      code: code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  void dispose() {
    _authStateController.close();
  }
}
