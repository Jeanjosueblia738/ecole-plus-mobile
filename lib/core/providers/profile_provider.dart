import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../security/user_role.dart';

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
        id: id,
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
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile?>(
  (ref) => ProfileNotifier(),
);
