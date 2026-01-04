import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  // Create or Update User Data
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

  // Get User Data Stream
  Stream<UserModel> get userData {
    return userCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(
            snapshot.data() as Map<String, dynamic>, snapshot.id);
      } else {
        return UserModel(uid: uid!, email: '', role: 'resident', isApproved: false);
      }
    });
  }

  // 1. GET ACTIVE MAINTAINERS
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
  Future<void> toggleMaintainerStatus(String uid, bool isActive) async {
    return await userCollection.doc(uid).update({
      'isApproved': isActive,
    });
  }

  // 5. GET PENDING RESIDENTS
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
  Future<void> approveUser(String uid) async {
    return await userCollection.doc(uid).update({'isApproved': true});
  }

  // 7. REJECT RESIDENT
  Future<void> rejectUser(String uid) async {
    return await userCollection.doc(uid).delete();
  }
}