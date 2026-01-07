import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- NEW IMPORT
import 'package:firebase_core/firebase_core.dart'; // Needed for the trick
import 'database_service.dart';
import '../models/user_model.dart';

// Service class handling all Authentication logic (Login, Register, Logout).
// It interacts with Firebase Auth and syncs user data to Firestore.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Static messages to pass status to the UI after logic execution
  static String? pendingErrorMessage;
  static String? registrationSuccessMessage;

  // --- HELPER: CONVERT FIREBASE USER TO CUSTOM USER MODEL ---
  // We use this to abstract away the raw FirebaseUser and use our own simple 'UserModel'.
  UserModel? _userFromFirebaseUser(User? user) {
    if (user == null) {
      return null;
    }
    // Defaulting role/approval here is temporary; the real data comes from Firestore later
    return UserModel(
        uid: user.uid,
        email: user.email!,
        role: 'resident',
        isApproved: false
    );
  }

  // --- AUTH STREAM ---
  // This stream listens for auth changes (Log In / Log Out).
  // The Provider in main.dart listens to this to decide which screen to show.
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // --- LOGIN FUNCTION ---
  // Authenticates with email/pass, then checks Firestore for approval status.
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      // 1. Attempt to sign in with Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // 2. Fetch the user's role and approval status from Firestore
        // We do this immediately to prevent unapproved users from accessing the app
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          bool isApproved = doc.get('isApproved') ?? false;
          String role = doc.get('role') ?? 'resident';

          // 3. LOGIC CHECK:
          // Allow access if they are 'isApproved' OR if they are an 'admin'
          if (isApproved == true || role == 'admin') {
            return null; // returning null means SUCCESS
          } else {
            // 4. DENIED:
            // The user exists in Auth, but isn't approved in Firestore.
            // We must sign them out immediately so the App Wrapper doesn't let them in.
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

  // --- REGISTER FUNCTION (RESIDENTS) ---
  // Registers a new user, saves their profile, and immediately signs them out
  // so they have to wait for approval.
  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String idType,
    required String idNumber,
    required String contactNumber,
  }) async {
    try {
      // 1. Create Account in Firebase Auth (This logs them in automatically by default)
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );
      User? user = result.user;

      if (user != null) {
        // 2. Create the User Document in Firestore
        await DatabaseService(uid: user.uid).updateUserData(
          email: email,
          role: 'resident',
          isApproved: false, // Default to false (Pending)
          fullName: fullName,
          idType: idType,
          idNumber: idNumber,
          contactNumber: contactNumber,
        );
        registrationSuccessMessage = "Account successfully created! Please wait for admin approval.";

        // 3. CRITICAL STEP: Sign Out Immediately!
        // Since createUser logs them in, we force logout so the stream doesn't
        // redirect them to the Home screen.
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

  // --- SIGN OUT ---
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // --- ADMIN: CREATE MAINTAINER ACCOUNT ---
  // This allows an Admin to create a NEW account for a maintainer without
  // logging themselves out. We use a secondary 'Temporary' Firebase App instance.
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
      // Standard FirebaseAuth.instance.createUser... would replace the current
      // Admin session with the new user. Using a named app prevents this.
      tempApp = await Firebase.initializeApp(
        name: 'TemporaryRegisterApp',
        options: Firebase.app().options,
      );

      // 2. Create the User using the TEMP app instance
      UserCredential result = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      User? newMaintainer = result.user;

      if (newMaintainer != null) {
        // 3. Save to Firestore (We can use the main DatabaseService for this)
        // because Firestore writes don't depend on the Auth session instance
        await DatabaseService(uid: newMaintainer.uid).updateUserData(
          email: email,
          role: 'maintainer',       // Force Role to maintainer
          isApproved: true,         // Auto-Approve Staff (they don't need to wait)
          fullName: fullName,
          contactNumber: contactNumber,
          idType: 'Staff ID',       // Default ID type
          idNumber: 'STAFF',        // Placeholder
        );

        // Add the specialization field specifically for maintainers
        await FirebaseFirestore.instance.collection('users').doc(newMaintainer.uid).update({
          'specialization': specialization
        });

        // 4. Delete the Temp App (Cleanup) to free resources
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