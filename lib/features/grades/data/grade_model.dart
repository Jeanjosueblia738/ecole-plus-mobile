// ─── Types d'évaluation (système ivoirien) ────────────────────────────────
enum EvalType { controle, devoir, examen }

extension EvalTypeLabel on EvalType {
  String get label => switch (this) {
        EvalType.controle => 'Contrôle',
        EvalType.devoir => 'Devoir',
        EvalType.examen => 'Examen',
      };
}

// ─── Matière avec coefficient ──────────────────────────────────────────────
class Subject {
  final String name;
  final int coefficient;

  const Subject({required this.name, required this.coefficient});
}

// Matières standard lycée/collège CI
const kSubjects = [
  Subject(name: 'Mathématiques', coefficient: 5),
  Subject(name: 'Français', coefficient: 4),
  Subject(name: 'Anglais', coefficient: 3),
  Subject(name: 'SVT', coefficient: 3),
  Subject(name: 'Physique-Chimie', coefficient: 3),
  Subject(name: 'Histoire-Géographie', coefficient: 3),
  Subject(name: 'Philosophie', coefficient: 2),
  Subject(name: 'EPS', coefficient: 2),
  Subject(name: 'Arts', coefficient: 1),
];

// ─── Note individuelle ────────────────────────────────────────────────────
class Grade {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String subject;
  final int coefficient;
  final double value; // note sur 20
  final EvalType evalType;
  final String trimestre; // '1er', '2ème', '3ème'
  final String date; // dd/MM/yyyy
  final String? comment;

  const Grade({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.subject,
    required this.coefficient,
    required this.value,
    required this.evalType,
    required this.trimestre,
    required this.date,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'className': className,
        'subject': subject,
        'coefficient': coefficient,
        'value': value,
        'evalType': evalType.name,
        'trimestre': trimestre,
        'date': date,
        'comment': comment,
      };

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        id: json['id'],
        studentId: json['studentId'],
        studentName: json['studentName'],
        className: json['className'],
        subject: json['subject'],
        coefficient: json['coefficient'],
        value: (json['value'] as num).toDouble(),
        evalType: EvalType.values.byName(json['evalType']),
        trimestre: json['trimestre'],
        date: json['date'],
        comment: json['comment'],
      );
}

// ─── Résultat par matière (pour bulletin) ─────────────────────────────────
class SubjectResult {
  final String subject;
  final int coefficient;
  final double moyenne; // moyenne des notes de la matière
  final List<Grade> grades;

  const SubjectResult({
    required this.subject,
    required this.coefficient,
    required this.moyenne,
    required this.grades,
  });

  double get moyennePonderee => moyenne * coefficient;
}

// ─── Bulletin complet d'un élève ──────────────────────────────────────────
class Bulletin {
  final String studentId;
  final String studentName;
  final String className;
  final String trimestre;
  final List<SubjectResult> results;
  final int rang;
  final int totalEleves;

  const Bulletin({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.trimestre,
    required this.results,
    required this.rang,
    required this.totalEleves,
  });

  double get moyenneGenerale {
    final totalCoef = results.fold(0, (s, r) => s + r.coefficient);
    if (totalCoef == 0) return 0;
    final totalPoints = results.fold(0.0, (s, r) => s + r.moyennePonderee);
    return totalPoints / totalCoef;
  }

  String get mention => switch (moyenneGenerale) {
        >= 16 => 'Très Bien',
        >= 14 => 'Bien',
        >= 12 => 'Assez Bien',
        >= 10 => 'Passable',
        _ => 'Insuffisant',
      };

  bool get estAdmis => moyenneGenerale >= 10;
}
