// ============================================================
// core/providers/auth_provider.dart
// OOP Encapsulation: all auth state transitions managed here.
//     Polymorphism: role drives navigation destination.
// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

// Immutable auth state — Encapsulation
class AuthState {
  final bool    isLoggedIn;
  final String? role;
  final String? token;
  final String? fullName;
  final String? email;
  final int?    ownerId;
  final int?    staffId;
  final bool    isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.isLoggedIn = false, this.role,    this.token,
    this.fullName,           this.email,   this.ownerId,
    this.staffId,            this.isLoading = false, this.error, this.isInitialized = false
  });

  AuthState copyWith({
  bool? isLoggedIn,
  String? role,
  String? token,
  String? fullName,
  String? email,
  int? ownerId,
  int? staffId,
  bool? isLoading,
  String? error,
  bool? isInitialized,   // 👈 ADD THIS
}) => AuthState(
  isLoggedIn: isLoggedIn ?? this.isLoggedIn,
  role: role ?? this.role,
  token: token ?? this.token,
  fullName: fullName ?? this.fullName,
  email: email ?? this.email,
  ownerId: ownerId ?? this.ownerId,
  staffId: staffId ?? this.staffId,
  isLoading: isLoading ?? this.isLoading,
  error: error,
  isInitialized: isInitialized ?? this.isInitialized, // 👈 ADD
);
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
        (ref) => AuthNotifier(ref.read(authServiceProvider)));

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _svc;

  AuthNotifier(this._svc) : super(const AuthState()) {
    _restore();
  }

  Future<void> _restore() async {
  final saved = await _svc.getSavedSession();

  if (saved != null && saved.accessToken.isNotEmpty) {
    state = state.copyWith(
      isLoggedIn: true,
      role: saved.role,
      token: saved.accessToken,
      fullName: saved.fullName,
      email: saved.email,
      ownerId: saved.ownerId,
      staffId: saved.staffId,
      isInitialized: true,
    );
  } else {
    state = state.copyWith(isInitialized: true);
  }
}

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final r = await _svc.login(email, password);
      await _svc.saveSession(r);
      state = state.copyWith(
        isLoggedIn: true, isLoading: false,
        role:       r.role,        token:    r.accessToken,
        fullName:   r.fullName,    email:    r.email,
        ownerId:    r.ownerId,     staffId:  r.staffId,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await _svc.clearSession();
    state = const AuthState();
  }
}
