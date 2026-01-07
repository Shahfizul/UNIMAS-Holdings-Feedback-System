import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

// Service class handling all User-related database operations.
// This includes creating profiles, fetching lists of users (Maintainers/Residents),
// and managing account approvals/archiving.
class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Reference to the 'users' collection in Firestore
  final CollectionReference userCollection =
  FirebaseFirestore.instance.collection('users');

  // --- CREATE OR UPDATE USER PROFILE ---
  // Called during registration or when updating profile details.
  // Uses .set() with merge logic implicit in the design (or overwrite).
  Future<void> updateUserData({
    required String email,
    required String role,
    bool isApproved = false,
    String? fullName,
    String? idType,
    String? idNumber,
    String? contactNumber,
    String? specialization, // <--- Added
  }) async {
    return await userCollection.doc(uid).set({
      'email': email,
      'role': role,
      'isApproved': isApproved,
      'fullName': fullName,
      'idType': idType,
      'idNumber': idNumber,
      'contactNumber': contactNumber,
      'specialization': specialization, // <--- Added
    });
  }

  // --- GET SINGLE USER DATA STREAM ---
  // Listens to changes on the current user's document.
  // Used in the app to keep the local user profile in sync with the database.
  Stream<UserModel> get userData {
    return userCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(
            snapshot.data() as Map<String, dynamic>, snapshot.id);
      } else {
        // Return a default empty user if document doesn't exist yet
        return UserModel(uid: uid!, email: '', role: 'resident', isApproved: false);
      }
    });
  }

  // 1. GET ACTIVE MAINTAINERS (ADMIN VIEW)
  // Returns a list of Maintainers who are currently Active (isApproved = true).
  Stream<List<UserModel>> get maintainers {
    return userCollection
        .where('role', isEqualTo: 'maintainer')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 2. GET ARCHIVED MAINTAINERS (FR-13: Archive)
  // Returns a list of Maintainers who have been Archived/Disabled (isApproved = false).
  Stream<List<UserModel>> get archivedMaintainers {
    return userCollection
        .where('role', isEqualTo: 'maintainer')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 3. EDIT MAINTAINER (FR-13: Edit)
  // Allows Admin to update specific details of a maintainer's profile.
  Future<void> updateMaintainerDetails({
    required String uid,
    required String fullName,
    required String contactNumber,
    required String specialization,
  }) async {
    return await userCollection.doc(uid).update({
      'fullName': fullName,
      'contactNumber': contactNumber,
      'specialization': specialization,
    });
  }

  // 4. ARCHIVE/RESTORE (Toggle Status)
  // Switches a maintainer between Active (true) and Archived (false).
  Future<void> toggleMaintainerStatus(String uid, bool isActive) async {
    return await userCollection.doc(uid).update({
      'isApproved': isActive,
    });
  }

  // 5. GET PENDING RESIDENTS (ADMIN VIEW)
  // Returns a list of Residents who have signed up but are waiting for approval.
  Stream<List<UserModel>> get pendingResidents {
    return userCollection
        .where('role', isEqualTo: 'resident')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 6. APPROVE RESIDENT
  // Grants a pending resident access to the system.
  Future<void> approveUser(String uid) async {
    return await userCollection.doc(uid).update({'isApproved': true});
  }

  // 7. REJECT RESIDENT
  // Denies a pending resident request and deletes their user record.
  Future<void> rejectUser(String uid) async {
    return await userCollection.doc(uid).delete();
  }
}