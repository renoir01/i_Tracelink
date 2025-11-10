import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _authService.authStateChanges.listen((user) {
      _firebaseUser = user;
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      _userModel = await _authService.getUserProfile(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmailPassword(email, password);
      if (credential != null) {
        await _saveLoginState(true);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String phone,
    required String name,
    required String userType,
    required String language,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.registerWithEmailPassword(email, password);
      if (credential != null && credential.user != null) {
        final user = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          userType: userType,
          language: language,
          createdAt: DateTime.now(),
          isVerified: false,
        );
        
        await _authService.createUserProfile(user);
        await _saveLoginState(true);
        
        // Send welcome email
        try {
          await EmailService().sendWelcomeEmail(
            toEmail: email,
            userName: email.split('@')[0], // Use email prefix as name for now
            userType: userType,
          );
        } catch (e) {
          // Don't fail registration if email fails
          print('Welcome email failed to send: $e');
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await _saveLoginState(false);
    _userModel = null;
    notifyListeners();
  }

  Future<void> updateLanguage(String language) async {
    if (_firebaseUser != null) {
      await _authService.updateUserLanguage(_firebaseUser!.uid, language);
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(language: language);
        notifyListeners();
      }
    }
  }

  Future<void> _saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, isLoggedIn);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
