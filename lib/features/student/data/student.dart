class Student {
  final String id;
  String fullName;
  String className;
  String? classId;
  String parentPhone;

  Student({
    required this.id,
    required this.fullName,
    required this.className,
    required this.parentPhone,
    this.classId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'className': className,
        'classId': classId,
        'parentPhone': parentPhone,
      };

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      className: json['className'] as String? ?? '',
      classId: json['classId'] as String?,
      parentPhone: json['parentPhone'] as String? ?? '',
    );
  }

  factory Student.fromApi(Map<String, dynamic> json) {
    final classObj = json['class'];
    final className = classObj is Map
        ? (classObj['name'] as String? ?? '')
        : (json['className'] as String? ?? '');
    final classId = json['classId'] as String? ??
        (classObj is Map ? classObj['id'] as String? : null);
    final first = json['firstName'] as String? ?? '';
    final last = json['lastName'] as String? ?? '';
    return Student(
      id: json['id'] as String,
      fullName: '$first $last'.trim(),
      className: className,
      classId: classId,
      parentPhone: json['parentPhone'] as String? ?? '',
    );
  }
}
