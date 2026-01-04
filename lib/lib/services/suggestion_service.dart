import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/suggestion_model.dart';
import 'notification_service.dart';

class SuggestionService {
  final CollectionReference suggestionCollection =
      FirebaseFirestore.instance.collection('suggestions'); 

  // 1. SUBMIT SUGGESTION
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
    DocumentReference docRef = suggestionCollection.doc();

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

    await docRef.set(suggestion.toMap());

    // --- REVERTED TO SAFE MODE ---
    // We pass complaintId: null so the app doesn't try to open it as a complaint.
    // The notification will simply just alert the user.
    await NotificationService().notifyAdmins(
      title: "New Suggestion", 
      body: "$fullName suggested: $title",
      type: 'info',
      complaintId: null, // <--- SAFE: No deep link, no error.
    );
  }

  // 2. GET ALL SUGGESTIONS (Stream)
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

  // 3. GET USER SUGGESTIONS
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
  Future<void> markAsRead(String id) async {
    await suggestionCollection.doc(id).update({'isRead': true});
  }
}