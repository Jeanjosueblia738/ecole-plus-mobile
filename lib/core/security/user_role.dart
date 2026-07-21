// Source unique de vérité pour les rôles — NE PAS redéfinir ailleurs
enum UserRole {
  admin, // ADMIN, FOUNDER, DIRECTOR
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
        UserRole.censor => 'Censeur',
        UserRole.surveillant => 'Surveillant Général',
        UserRole.secretary => 'Secrétaire',
        UserRole.accountant => 'Comptable',
        UserRole.cashier => 'Caissier',
        UserRole.teacher => 'Enseignant',
        UserRole.parent => 'Parent',
        UserRole.student => 'Élève',
      };
}
