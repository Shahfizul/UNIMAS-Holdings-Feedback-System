// Model class representing a User in the system.
// This is used to store profile information and manage roles (Admin, Maintainer, Resident).
class UserModel {
  final String uid;       // Unique ID from Firebase Authentication
  final String email;     // User's email address
  final String role;      // Determines app access: 'resident', 'admin', 'maintainer'
  final bool isApproved;  // Gatekeeping flag: Users can't log in until Admin approves them

  // --- PROFILE FIELDS ---
  // Optional details filled out during registration or profile update
  final String? fullName;
  final String? idType;       // e.g., 'Matric No', 'Staff ID'
  final String? idNumber;     // The actual ID value
  final String? contactNumber;
  final String? specialization; // <--- NEW FIELD: Specific to Maintainers (e.g., "Plumber", "Electrician")

  // --- CONSTRUCTOR ---
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

  // --- CONVERT TO MAP (Write to Firestore) ---
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

  // --- FACTORY: Create Object from Map (Read from Firestore) ---
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      // Normalize role string to lowercase/trimmed to prevent typo bugs
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