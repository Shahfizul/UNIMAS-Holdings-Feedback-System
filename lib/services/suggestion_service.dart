import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/suggestion_model.dart';
import 'notification_service.dart';

// Service class handling all Suggestion/Feedback operations.
// This allows Residents to submit ideas and Admins to view them.
class SuggestionService {
  // Reference to the 'suggestions' collection in Firestore
  final CollectionReference suggestionCollection =
  FirebaseFirestore.instance.collection('suggestions');

  // 1. SUBMIT SUGGESTION
  // Creates a new suggestion document in Firestore.
  // Sets status to 'New' and alerts Admins.
  Future<void> submitSuggestion({
    required String uid,
    required String title,
    required String description,
    required String category,
    List<String> imageUrls = const [],
    String? videoUrl,
    required String fullName,
    required String userType,
    required String matricNo,
    required String contactNumber,
  }) async {
    // Generate a new document reference to get a unique ID
    DocumentReference docRef = suggestionCollection.doc();

    // Create the model object with all user details attached
    SuggestionModel suggestion = SuggestionModel(
      id: docRef.id,
      uid: uid,
      title: title,
      description: description,
      category: category,
      status: 'New',
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      timestamp: DateTime.now(),
      fullName: fullName,
      userType: userType,
      matricNo: matricNo,
      contactNumber: contactNumber,
    );

    // Write to Firestore
    await docRef.set(suggestion.toMap());

    // --- NOTIFY ADMINS ---
    // REVERTED TO SAFE MODE:
    // We pass complaintId: null so the app doesn't try to open it as a complaint.
    // The notification will simply just alert the user without a deep link.
    await NotificationService().notifyAdmins(
      title: "New Suggestion",
      body: "$fullName suggested: $title",
      type: 'info',
      complaintId: null, // <--- SAFE: No deep link, no error.
    );
  }

  // 2. GET ALL SUGGESTIONS (ADMIN VIEW)
  // Returns a stream of ALL suggestions, ordered by newest first.
  Stream<List<SuggestionModel>> get allSuggestions {
    return suggestionCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SuggestionModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // 3. GET USER SUGGESTIONS (RESIDENT VIEW)
  // Returns a stream of suggestions submitted ONLY by the specific user.
  Stream<List<SuggestionModel>> getUserSuggestions(String uid) {
    return suggestionCollection
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SuggestionModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // 4. MARK AS READ
  // Updates the 'isRead' flag to true.
  // Used by Admin when they open a suggestion details screen.
  Future<void> markAsRead(String id) async {
    await suggestionCollection.doc(id).update({'isRead': true});
  }
}