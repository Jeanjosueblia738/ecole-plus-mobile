// Source unique de vérité pour les rôles — NE PAS redéfinir ailleurs
enum UserRole {
  admin, // ADMIN
  founder, // FOUNDER
  director, // DIRECTOR
  censor, // CENSOR
  surveillant, // SURVEILLANT, EDUCATOR
  secretary, // SECRETARY
  accountant, // ACCOUNTANT
  cashier, // CASHIER
  teacher, // TEACHER
  parent, // PARENT
  student, // STUDENT
}

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
        UserRole.admin => 'Administrateur',
        UserRole.founder => 'Fondateur',
        UserRole.director => 'Directeur',
        UserRole.censor => 'Censeur',
        UserRole.surveillant => 'Surveillant Général',
        UserRole.secretary => 'Secrétaire',
        UserRole.accountant => 'Comptable',
        UserRole.cashier => 'Caissier',
        UserRole.teacher => 'Enseignant',
        UserRole.parent => 'Parent',
        UserRole.student => 'Élève',
      };

  /// Direction (vue d'ensemble) — admin / fondateur / directeur
  bool get isDirection =>
      this == UserRole.admin ||
      this == UserRole.founder ||
      this == UserRole.director;

  /// Création classes / users (OWNER web = ADMIN + FOUNDER)
  bool get canManageSchool =>
      this == UserRole.admin || this == UserRole.founder;
}

extension UserRoleApi on UserRole {
  static UserRole? fromApi(String? role) => switch (role?.toUpperCase()) {
        'ADMIN' => UserRole.admin,
        'FOUNDER' => UserRole.founder,
        'DIRECTOR' => UserRole.director,
        'CENSOR' => UserRole.censor,
        'SURVEILLANT' => UserRole.surveillant,
        'EDUCATOR' => UserRole.surveillant,
        'SECRETARY' => UserRole.secretary,
        'ACCOUNTANT' => UserRole.accountant,
        'CASHIER' => UserRole.cashier,
        'TEACHER' => UserRole.teacher,
        'PARENT' => UserRole.parent,
        'STUDENT' => UserRole.student,
        _ => null,
      };
}
