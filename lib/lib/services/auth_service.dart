import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- NEW IMPORT
import 'package:firebase_core/firebase_core.dart'; // Needed for the trick
import 'database_service.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? pendingErrorMessage;
  static String? registrationSuccessMessage;

  // Create User Object based on FirebaseUser
  UserModel? _userFromFirebaseUser(User? user) {
    if (user == null) {
      return null;
    }
    return UserModel(
      uid: user.uid, 
      email: user.email!, 
      role: 'resident', 
      isApproved: false
    );
  }

  // Auth Change Stream
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // --- THE FIXED SIGN IN FUNCTION ---
Future<String?> signInWithEmail(String email, String password) async {
  try {
    // 1. Sign in normally
    UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    User? user = result.user;

    if (user != null) {
      // 2. Fetch the data IMMEDIATELY
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        bool isApproved = doc.get('isApproved') ?? false;
        String role = doc.get('role') ?? 'resident';

        // 3. Check approval
        if (isApproved == true || role == 'admin') {
          return null; // SUCCESS - Wrapper will now show the Home Screen
        } else {
          // 4. DENIED - Sign out BEFORE returning the error
          pendingErrorMessage = "Account pending approval. Please wait for Admin.";
          await _auth.signOut();
          return pendingErrorMessage;
        }
      }
    }
    return "User data not found.";
  } on FirebaseAuthException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}

  // NEW Register Function (With Immediate Sign Out)
  // Returns: String? (Error message) or null (Success)
  Future<String?> registerWithEmailAndPassword({
    required String email, 
    required String password,
    required String fullName,
    required String idType,
    required String idNumber,
    required String contactNumber,
  }) async {
    try {
      // 1. Create Account (This logs them in automatically)
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      User? user = result.user;

      if (user != null) {
        // 2. Save Data to Firestore
        await DatabaseService(uid: user.uid).updateUserData(
          email: email,
          role: 'resident', 
          isApproved: false, 
          fullName: fullName,
          idType: idType,
          idNumber: idNumber,
          contactNumber: contactNumber,
          );
          registrationSuccessMessage = "Account successfully created! Please wait for admin approval.";
        // 3. CRITICAL: Sign Out Immediately!
        // This prevents the 'user' stream from redirecting to Home
        await _auth.signOut();
        
        return null; // Null means SUCCESS
      }
      return "User creation failed";
    } on FirebaseAuthException catch (e) {
      return e.message; 
    } catch (e) {
      return e.toString();
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

  // --- ADMIN: CREATE MAINTAINER (Without Logging Out) ---
  Future<String?> createMaintainerAccount({
    required String email,
    required String password,
    required String fullName,
    required String contactNumber,
    required String specialization, // e.g., 'Plumber', 'Electrician'
  }) async {
    FirebaseApp? tempApp;
    try {
      // 1. Initialize a "Temporary" Firebase App
      // This lets us talk to Auth without affecting the current logged-in Admin
      tempApp = await Firebase.initializeApp(
        name: 'TemporaryRegisterApp',
        options: Firebase.app().options,
      );

      // 2. Create the User using the TEMP app
      UserCredential result = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);
      
      User? newMaintainer = result.user;

      if (newMaintainer != null) {
        // 3. Save to Firestore (We can use the main DatabaseService for this)
        await DatabaseService(uid: newMaintainer.uid).updateUserData(
          email: email,
          role: 'maintainer',       // Force Role
          isApproved: true,         // Auto-Approve Staff
          fullName: fullName,
          contactNumber: contactNumber,
          idType: 'Staff ID',       // Default for maintainers
          idNumber: 'STAFF',        // Placeholder or add arg if needed
        );
        
        // Optional: Save Specialization (Module 5 Extra)
        // We can just add it to the user doc directly
        await FirebaseFirestore.instance.collection('users').doc(newMaintainer.uid).update({
          'specialization': specialization
        });

        // 4. Delete the Temp App (Cleanup)
        await tempApp.delete();
        return null; // Success
      }
      return "Failed to create user";

    } on FirebaseAuthException catch (e) {
      if (tempApp != null) await tempApp.delete();
      return e.message;
    } catch (e) {
      if (tempApp != null) await tempApp.delete();
      return e.toString();
    }
  }
}