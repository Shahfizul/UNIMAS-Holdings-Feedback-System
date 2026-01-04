class UserModel {
  final String uid;
  final String email;
  final String role; // 'resident', 'admin', 'maintainer'
  final bool isApproved;
  
  // --- PROFILE FIELDS ---
  final String? fullName;
  final String? idType;
  final String? idNumber;
  final String? contactNumber;
  final String? specialization; // <--- NEW FIELD

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.isApproved,
    this.fullName,
    this.idType,
    this.idNumber,
    this.contactNumber,
    this.specialization, // <--- Add to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'isApproved': isApproved,
      'fullName': fullName,
      'idType': idType,
      'idNumber': idNumber,
      'contactNumber': contactNumber,
      'specialization': specialization, // <--- Add to Map
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      role: (data['role'] ?? 'resident').toString().trim().toLowerCase(),
      isApproved: data['isApproved'] ?? false,
      fullName: data['fullName'],
      idType: data['idType'],
      idNumber: data['idNumber'],
      contactNumber: data['contactNumber'],
      specialization: data['specialization'], // <--- Read from Map
    );
  }
}