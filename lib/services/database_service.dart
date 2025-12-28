import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Collection Reference
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
  }) async {
    return await userCollection.doc(uid).set({
      'email': email,
      'role': role,
      'isApproved': isApproved,
      'fullName': fullName,
      'idType': idType,
      'idNumber': idNumber,
      'contactNumber': contactNumber,
    });
  }

  // Get User Data Stream
  Stream<UserModel> get userData {
    return userCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(
            snapshot.data() as Map<String, dynamic>, snapshot.id);
      } else {
        // FIX: Added 'isApproved: false' to match the constructor
        return UserModel(
          uid: uid!, 
          email: '', 
          role: 'resident', 
          isApproved: false
        );
      }
    });
  }

  // Get List of All Maintainers
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

  // 1. GET PENDING RESIDENTS (Stream)
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

  // 2. APPROVE USER
  Future<void> approveUser(String uid) async {
    return await userCollection.doc(uid).update({
      'isApproved': true,
    });
  }

  // 3. REJECT USER (Deletes the profile so they cannot log in)
  Future<void> rejectUser(String uid) async {
    return await userCollection.doc(uid).delete();
  }
}