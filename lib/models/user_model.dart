class UserModel {
  final String uid;
  final String email;
  final String role; // 'resident', 'admin', 'maintainer'
  final bool isApproved; // For FR-11 (Pending Approval)

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.isApproved = false,
  });

  // Convert Firestore Document to User Model
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? 'resident',
      isApproved: data['isApproved'] ?? false,
    );
  }

  // Convert User Model to Map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'isApproved': isApproved,
    };
  }
}