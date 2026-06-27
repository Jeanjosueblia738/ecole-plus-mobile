import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../security/user_role.dart';

// ─── Modèle profil utilisateur ────────────────────────────────────────────
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
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  String get roleLabel => switch (role) {
        UserRole.admin => 'Administrateur',
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

  // Profils par défaut selon le rôle
  factory UserProfile.defaultForRole(UserRole role) => UserProfile(
        id: 'user_${role.name}',
        fullName: switch (role) {
          UserRole.admin => 'Administrateur ECOLE+',
          UserRole.teacher => 'M. Koné Enseignant',
          UserRole.parent => 'M. Kouassi Jean-Baptiste',
          UserRole.student => 'Élève ECOLE+',
        },
        email: '${role.name}@ecoleplus.ci',
        phone: '+225 07 00 00 00',
        role: role,
        etablissement: 'Lycée Excellence Abidjan',
        poste: switch (role) {
          UserRole.admin => 'Directeur Général',
          UserRole.teacher => 'Professeur de Mathématiques',
          UserRole.parent => 'Parent d\'élève',
          UserRole.student => '3ème A',
        },
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────
class ProfileNotifier extends StateNotifier<UserProfile?> {
  static const _key = 'user_profile';

  ProfileNotifier() : super(null);

  Future<void> loadForRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_key}_${role.name}');
    if (data != null) {
      state = UserProfile.fromJson(jsonDecode(data));
    } else {
      state = UserProfile.defaultForRole(role);
    }
  }

  Future<void> update(UserProfile profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '${_key}_${profile.role.name}', jsonEncode(profile.toJson()));
  }

  Future<void> updateNotifs({
    bool? absence,
    bool? note,
    bool? paiement,
  }) async {
    if (state == null) return;
    await update(state!.copyWith(
      notifAbsence: absence,
      notifNote: note,
      notifPaiement: paiement,
    ));
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile?>(
  (ref) => ProfileNotifier(),
);
