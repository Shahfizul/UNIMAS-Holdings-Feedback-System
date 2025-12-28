class UserModel {
  final String uid;
  final String email;
  final String role; // 'resident', 'admin', 'maintainer'
  final bool isApproved;
  
  // --- NEW PROFILE FIELDS ---
  final String? fullName;
  final String? idType;   // 'Matric No', 'Passport', 'NRIC'
  final String? idNumber; // The actual number (e.g., 99451)
  final String? contactNumber;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.isApproved,
    this.fullName,
    this.idType,
    this.idNumber,
    this.contactNumber,
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
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      // --- THE FIX ---
      // 1. Handle missing role
      // 2. Convert to String safely
      // 3. Force lowercase (fixes 'Maintainer' vs 'maintainer')
      // 4. Remove extra spaces (.trim)
      role: (data['role'] ?? 'resident').toString().trim().toLowerCase(),
      
      isApproved: data['isApproved'] ?? false,
      fullName: data['fullName'],
      idType: data['idType'],
      idNumber: data['idNumber'],
      contactNumber: data['contactNumber'],
    );
  }
}