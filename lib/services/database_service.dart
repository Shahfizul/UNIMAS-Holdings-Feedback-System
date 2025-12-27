// This file handles saving the user's role to Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Collection Reference
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  // Create or Update User Data
  Future<void> updateUserData(String email, String role) async {
    return await userCollection.doc(uid).set({
      'email': email,
      'role': role,
      'isApproved': false, // Default to pending
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get User Data Stream (To check role changes live)
  Stream<UserModel> get userData {
    return userCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(
            snapshot.data() as Map<String, dynamic>, snapshot.id);
      } else {
        // Fallback for new users before data is written
        return UserModel(uid: uid!, email: '', role: 'resident');
      }
    });
  }

  // Get List of All Maintainers (For Admin Dropdown)
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
}