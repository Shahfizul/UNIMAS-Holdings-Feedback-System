// This is the "Brain." It handles Login, Register, and automatically calls the Database Service to save the role.

import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create User Object based on FirebaseUser
  UserModel? _userFromFirebaseUser(User? user) {
    if (user == null) {
      return null;
    }
    // We only get basic info here. Role comes from Firestore later.
    return UserModel(uid: user.uid, email: user.email!, role: 'resident');
  }

  // Auth Change Stream (Listens for login/logout)
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // Register with Email & Password
  Future<dynamic> registerWithEmail(
      String email, String password, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      // Create a new document for the user with the uid
      await DatabaseService(uid: user!.uid).updateUserData(email, role);

      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign In with Email & Password
  Future<dynamic> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign Out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}