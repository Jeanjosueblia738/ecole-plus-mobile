import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/user_role.dart';
import '../session/user_session.dart';
import '../services/auth_api_service.dart';
import '../services/auth_storage_service.dart';

class AuthState {
  final UserRole? role;
  final bool isLoading;
  final String? error;
  final String? tenantCode;
  final String? tenantName;
  final String? userId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? className;

  const AuthState({
    this.role,
    this.isLoading = false,
    this.error,
    this.tenantCode,
    this.tenantName,
    this.userId,
    this.email,
    this.firstName,
    this.lastName,
    this.className,
  });

  bool get isLoggedIn => role != null;
  bool get isAdmin => role == UserRole.admin;
  bool get isTeacher => role == UserRole.teacher;
  bool get isParent => role == UserRole.parent;
  bool get isStudent => role == UserRole.student;
  bool get isCensor => role == UserRole.censor;
  bool get isSurveillant => role == UserRole.surveillant;
  bool get isSecretary => role == UserRole.secretary;
  bool get isAccountant => role == UserRole.accountant;

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) {
      return firstName!;
    }
    if (lastName != null) {
      return lastName!;
    }
    return email ?? '';
  }

  AuthState copyWith({
    UserRole? role,
    bool? isLoading,
    String? error,
    String? tenantCode,
    String? tenantName,
    String? userId,
    String? email,
    String? firstName,
    String? lastName,
    String? className,
  }) =>
      AuthState(
        role: role ?? this.role,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        tenantCode: tenantCode ?? this.tenantCode,
        tenantName: tenantName ?? this.tenantName,
        userId: userId ?? this.userId,
        email: email ?? this.email,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        className: className ?? this.className,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkStoredAuth();
  }

  Future<void> _checkStoredAuth() async {
    final isLogged = await AuthStorageService.isLoggedIn();
    if (!isLogged) {
      return;
    }
    final role = await AuthStorageService.getUserRole();
    final tenantCode = await AuthStorageService.getTenantCode();
    final tenantName = await AuthStorageService.getTenantName();
    final userId = await AuthStorageService.getUserId();
    final email = await AuthStorageService.getUserEmail();
    final firstName = await AuthStorageService.read('first_name');
    final lastName = await AuthStorageService.read('last_name');
    final className = await AuthStorageService.read('class_name');
    final parsed = _parseRole(role);
    if (parsed != null) {
      UserSession.setRole(parsed);
    }
    state = state.copyWith(
      role: parsed,
      tenantCode: tenantCode,
      tenantName: tenantName,
      userId: userId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      className: className,
    );
  }

  Future<void> login({
    required String tenantCode,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      Map<String, dynamic> data;

      if (role == 'TEACHER') {
        data = await AuthApiService.loginTeacher(
          tenantCode: tenantCode,
          email: email,
          password: password,
        );
        final teacher = data['teacher'] as Map<String, dynamic>;
        final tenant = data['tenant'] as Map<String, dynamic>?;
        await AuthStorageService.write(
            'first_name', teacher['firstName'] ?? '');
        await AuthStorageService.write('last_name', teacher['lastName'] ?? '');
        UserSession.setRole(UserRole.teacher);
        state = state.copyWith(
          role: UserRole.teacher,
          tenantCode: tenant?['code'] ?? tenantCode,
          tenantName: tenant?['name'] ?? tenantCode,
          userId: teacher['id'],
          email: teacher['email'],
          firstName: teacher['firstName'],
          lastName: teacher['lastName'],
          isLoading: false,
        );
      } else {
        data = await AuthApiService.login(
          tenantCode: tenantCode,
          email: email,
          password: password,
        );
        final user = data['user'] as Map<String, dynamic>;
        final tenant = data['tenant'] as Map<String, dynamic>;
        final expected = _parseRole(role);
        final actual = _parseRole(user['role'] as String?);

        if (actual == null) {
          await AuthStorageService.clearAll();
          state = state.copyWith(
            isLoading: false,
            error: 'Rôle non reconnu pour ce compte',
          );
          return;
        }

        if (expected != null && expected != actual) {
          await AuthStorageService.clearAll();
          state = state.copyWith(
            isLoading: false,
            error:
                'Profil incorrect. Ce compte est « ${actual.label} ». Sélectionnez le bon profil.',
          );
          return;
        }

        await AuthStorageService.write('first_name', user['firstName'] ?? '');
        await AuthStorageService.write('last_name', user['lastName'] ?? '');
        if (user['class'] != null) {
          await AuthStorageService.write(
              'class_name', user['class']['name'] ?? '');
        }
        UserSession.setRole(actual);
        state = state.copyWith(
          role: actual,
          tenantCode: tenant['code'],
          tenantName: tenant['name'],
          userId: user['id'],
          email: user['email'],
          firstName: user['firstName'],
          lastName: user['lastName'],
          className: user['class']?['name'],
          isLoading: false,
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Erreur de connexion';
      state = state.copyWith(isLoading: false, error: message.toString());
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Impossible de joindre le serveur');
    }
  }

  Future<void> loginAs(UserRole role) async {
    if (!kDebugMode) {
      throw StateError('Mode demo désactivé hors debug');
    }
    UserSession.setRole(role);
    state = AuthState(role: role, tenantCode: 'DEMO', tenantName: 'Mode Demo');
  }

  /// Applique une session réelle déjà persistée (ex. après join).
  Future<void> applyJoinedSession({
    required UserRole role,
    required String tenantCode,
    required String tenantName,
    String? userId,
    String? email,
    String? firstName,
    String? lastName,
    String? className,
  }) async {
    UserSession.setRole(role);
    state = AuthState(
      role: role,
      tenantCode: tenantCode,
      tenantName: tenantName,
      userId: userId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      className: className,
    );
  }

  Future<void> logout() async {
    await AuthApiService.logout();
    await UserSession.clear();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(error: null);

  UserRole? _parseRole(String? role) => switch (role) {
        'ADMIN' => UserRole.admin,
        'FOUNDER' => UserRole.admin,
        'DIRECTOR' => UserRole.admin,
        'CENSOR' => UserRole.censor,
        'SURVEILLANT' => UserRole.surveillant,
        'EDUCATOR' => UserRole.surveillant,
        'SECRETARY' => UserRole.secretary,
        'ACCOUNTANT' => UserRole.accountant,
        'CASHIER' => UserRole.accountant,
        'TEACHER' => UserRole.teacher,
        'PARENT' => UserRole.parent,
        'STUDENT' => UserRole.student,
        _ => null,
      };
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
