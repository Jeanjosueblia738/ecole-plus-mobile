class Student {
  final String id;
  String fullName;
  String className;
  String parentPhone;

  Student({
    required this.id,
    required this.fullName,
    required this.className,
    required this.parentPhone,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'className': className,
        'parentPhone': parentPhone,
      };

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      fullName: json['fullName'],
      className: json['className'],
      parentPhone: json['parentPhone'],
    );
  }
}
