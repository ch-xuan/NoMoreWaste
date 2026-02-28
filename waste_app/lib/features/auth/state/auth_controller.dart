import 'package:flutter/foundation.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/user_role.dart';
import '../../../data/repositories/user_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthService authService,
    required UserRepository userRepository,
  })  : _auth = authService,
        _users = userRepository;

  final AuthService _auth;
  final UserRepository _users;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? orgName,
    String? displayName,
  }) async {
    _setError(null);
    _setLoading(true);
    try {
      final cred = await _auth.signUpWithEmail(email: email, password: password);
      final uid = cred.user!.uid;

      // ✅ STEP 2: Create Firestore document on signup
      await _users.createUserProfile(
        uid: uid,
        email: email,
        role: role,
        orgName: orgName,
        displayName: displayName,
      );

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setError(null);
    _setLoading(true);
    try {
      await _auth.signInWithEmail(email: email, password: password);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
