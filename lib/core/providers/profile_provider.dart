import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../security/user_role.dart';
import '../services/teacher_api_service.dart';
import '../services/users_api_service.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatarInitials;
  final UserRole role;
  final String? etablissement;
  final String? poste;
  final bool notifAbsence;
  final bool notifNote;
  final bool notifPaiement;
  final String langue;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarInitials,
    required this.role,
    this.etablissement,
    this.poste,
    this.notifAbsence = true,
    this.notifNote = true,
    this.notifPaiement = true,
    this.langue = 'fr',
  });

  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  String get roleLabel => switch (role) {
        UserRole.admin => 'Administrateur',
        UserRole.censor => 'Censeur',
        UserRole.surveillant => 'Surveillant Général',
        UserRole.secretary => 'Secrétaire',
        UserRole.accountant => 'Comptable',
        UserRole.teacher => 'Enseignant',
        UserRole.parent => 'Parent d\'élève',
        UserRole.student => 'Élève',
      };

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? etablissement,
    String? poste,
    bool? notifAbsence,
    bool? notifNote,
    bool? notifPaiement,
    String? langue,
  }) =>
      UserProfile(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role,
        etablissement: etablissement ?? this.etablissement,
        poste: poste ?? this.poste,
        notifAbsence: notifAbsence ?? this.notifAbsence,
        notifNote: notifNote ?? this.notifNote,
        notifPaiement: notifPaiement ?? this.notifPaiement,
        langue: langue ?? this.langue,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role.name,
        'etablissement': etablissement,
        'poste': poste,
        'notifAbsence': notifAbsence,
        'notifNote': notifNote,
        'notifPaiement': notifPaiement,
        'langue': langue,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        fullName: json['fullName'],
        email: json['email'],
        phone: json['phone'],
        role: UserRole.values.byName(json['role']),
        etablissement: json['etablissement'],
        poste: json['poste'],
        notifAbsence: json['notifAbsence'] ?? true,
        notifNote: json['notifNote'] ?? true,
        notifPaiement: json['notifPaiement'] ?? true,
        langue: json['langue'] ?? 'fr',
      );

  /// Placeholder sans faux noms (Koné, Kouassi, Lycée Excellence…).
  factory UserProfile.defaultForRole(
    UserRole role, {
    String? id,
    String? fullName,
    String? email,
    String? etablissement,
  }) {
    final name = (fullName ?? '').trim();
    return UserProfile(
      id: id ?? 'user_${role.name}',
      fullName: name.isNotEmpty ? name : 'Profil',
      email: (email ?? '').trim(),
      phone: '',
      role: role,
      etablissement: etablissement,
      poste: null,
    );
  }

  /// Découpe « Nom complet » → (prénom, nom).
  static (String firstName, String lastName) splitFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }
}

class ProfileNotifier extends StateNotifier<UserProfile?> {
  static const _key = 'user_profile';
  ProfileNotifier() : super(null);

  Future<void> loadForRole(
    UserRole role, {
    String? userId,
    String? fullName,
    String? email,
    String? etablissement,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_key}_${role.name}');
    if (data != null) {
      try {
        final saved = UserProfile.fromJson(jsonDecode(data));
        // Enrichir avec la session auth si le profil local est encore un placeholder.
        final sessionName = (fullName ?? '').trim();
        final looksPlaceholder = saved.fullName == 'Profil' ||
            saved.fullName.contains('Koné') ||
            saved.fullName.contains('Kouassi') ||
            (saved.etablissement ?? '') == 'Lycée Excellence Abidjan';
        if (looksPlaceholder && sessionName.isNotEmpty) {
          state = saved.copyWith(
            fullName: sessionName,
            email: (email ?? '').trim().isNotEmpty ? email!.trim() : saved.email,
            etablissement: etablissement ?? saved.etablissement,
          );
        } else {
          state = saved;
        }
        return;
      } catch (_) {
        // fall through to session / placeholder
      }
    }
    state = UserProfile.defaultForRole(
      role,
      id: userId,
      fullName: fullName,
      email: email,
      etablissement: etablissement,
    );
  }

  Future<void> update(UserProfile profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '${_key}_${profile.role.name}', jsonEncode(profile.toJson()));
  }

  Future<void> updateNotifs({bool? absence, bool? note, bool? paiement}) async {
    if (state == null) {
      return;
    }
    await update(state!.copyWith(
        notifAbsence: absence, notifNote: note, notifPaiement: paiement));
  }

  /// Charge le profil depuis l'API (enseignants → /teachers/me, sinon /users/me).
  /// Les préférences de notification restent locales.
  Future<bool> refreshFromApi() async {
    final current = state;
    if (current == null) return false;
    try {
      final Map<String, dynamic> remote;
      if (current.role == UserRole.teacher) {
        remote = await TeacherApiService.getMyProfile();
      } else {
        remote = await UsersApiService.getMyProfile();
      }
      final firstName = (remote['firstName'] as String?)?.trim() ?? '';
      final lastName = (remote['lastName'] as String?)?.trim() ?? '';
      final fullName = '$firstName $lastName'.trim();
      final phone = (remote['phone'] as String?)?.trim() ?? current.phone;
      final email = (remote['email'] as String?)?.trim() ?? current.email;
      final id = (remote['id'] as String?) ?? current.id;

      await update(current.copyWith(
        id: id,
        fullName: fullName.isNotEmpty ? fullName : current.fullName,
        email: email,
        phone: phone,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Synchronise prénom / nom / téléphone vers l'API, puis met à jour le stockage local.
  /// Retourne `null` en cas de succès, sinon un message d'erreur.
  Future<String?> syncProfile({
    required String fullName,
    required String phone,
    String? email,
    String? poste,
  }) async {
    final current = state;
    if (current == null) return 'Profil introuvable';

    final (firstName, lastName) = UserProfile.splitFullName(fullName);
    if (firstName.isEmpty) return 'Le nom complet est obligatoire';

    try {
      if (current.role == UserRole.teacher) {
        await TeacherApiService.updateMyProfile(
          firstName: firstName,
          lastName: lastName,
          phone: phone,
        );
      } else {
        await UsersApiService.updateMyProfile(
          firstName: firstName,
          lastName: lastName,
          phone: phone,
        );
      }

      await update(current.copyWith(
        fullName: fullName.trim(),
        phone: phone.trim(),
        email: (email ?? current.email).trim(),
        poste: poste ?? current.poste,
      ));
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is List) return msg.join(', ');
        return msg.toString();
      }
      return 'Impossible de synchroniser le profil. Vérifiez votre connexion.';
    } catch (_) {
      return 'Impossible de synchroniser le profil. Vérifiez votre connexion.';
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile?>(
  (ref) => ProfileNotifier(),
);
