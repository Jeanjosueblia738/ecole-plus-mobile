class Parent {
  final String id;
  String fullName;
  String phoneNumber;
  List<String> studentIds;

  Parent({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.studentIds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'studentIds': studentIds,
      };

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      studentIds: List<String>.from(json['studentIds'] ?? []),
    );
  }
}