import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/models.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String?    _token;
  bool       _loading = false;
  String?    _error;

  UserModel? get user      => _user;
  String?    get token     => _token;
  bool       get loading   => _loading;
  String?    get error     => _error;
  bool       get isLoggedIn => _token != null;

  final _api         = ApiClient.instance;
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<void> init() async {
    _token = await _api.getToken();
    notifyListeners();
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _api.dio.post('/auth/register', data: {
        'name': name, 'email': email,
        'phone': phone, 'password': password,
      });
      _clearError();
      return true;
    } on DioException catch (e) {
      _setError(_extractError(e));
      return false;
    } finally { _setLoading(false); }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<bool> verifyOtp({required String email, required String otp}) async {
    _setLoading(true);
    try {
      await _api.dio.post('/auth/verify-otp', data: {'email': email, 'otp': otp});
      _clearError();
      return true;
    } on DioException catch (e) {
      _setError(_extractError(e));
      return false;
    } finally { _setLoading(false); }
  }

  Future<bool> resendOtp(String email) async {
    try {
      await _api.dio.post('/auth/resend-otp', data: {'email': email});
      return true;
    } on DioException { return false; }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      final response = await _api.dio.post('/auth/login', data: {
        'email': email, 'password': password,
      });
      _token = response.data['access_token'];
      _user  = UserModel.fromJson(response.data['user']);
      await _api.saveToken(_token!);
      _clearError();
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _setError(_extractError(e));
      return false;
    } finally { _setLoading(false); }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false; // user cancelled
      }
      final googleAuth  = await googleUser.authentication;
      final credential  = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw Exception('No ID token');

      // Send Firebase token to our backend for account creation / JWT
      final response = await _api.dio.post('/auth/google-login', data: {
        'id_token': idToken,
        'name':  googleUser.displayName ?? '',
        'email': googleUser.email,
      });
      _token = response.data['access_token'];
      _user  = UserModel.fromJson(response.data['user']);
      await _api.saveToken(_token!);
      _clearError();
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _setError(_extractError(e));
      return false;
    } catch (e) {
      _setError('Google Sign-In failed: ${e.toString()}');
      return false;
    } finally { _setLoading(false); }
  }

  // ── Forgot / Reset Password ───────────────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await _api.dio.post('/auth/forgot-password', data: {'email': email});
      _clearError(); return true;
    } on DioException catch (e) { _setError(_extractError(e)); return false; }
    finally { _setLoading(false); }
  }

  Future<bool> resetPassword({required String email, required String otp, required String newPassword}) async {
    _setLoading(true);
    try {
      await _api.dio.post('/auth/reset-password', data: {
        'email': email, 'otp': otp, 'new_password': newPassword,
      });
      _clearError(); return true;
    } on DioException catch (e) { _setError(_extractError(e)); return false; }
    finally { _setLoading(false); }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try { await _googleSignIn.signOut(); } catch (_) {}
    try { await FirebaseAuth.instance.signOut(); } catch (_) {}
    _token = null; _user = null;
    await _api.clearToken();
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _setLoading(bool v) { _loading = v; notifyListeners(); }
  void _setError(String m)  { _error = m; notifyListeners(); }
  void _clearError()        { _error = null; }

  String _extractError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Make sure the server is running and your WiFi is connected.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach server. Check your network and server IP address.';
    }
    final data = e.response?.data;
    if (data is Map && data.containsKey('detail')) return data['detail'].toString();
    return e.message ?? 'Something went wrong';
  }
}
