// 1. FORCE IMPORT OF v1 (Generation 1) SDK
// This fixes the "functions.firestore.document is not a function" error
const functions = require("firebase-functions/v1");

const admin = require("firebase-admin");
const language = require("@google-cloud/language");

admin.initializeApp();

// Create the AI Client
const client = new language.LanguageServiceClient();

exports.analyzeComplaintPriority = functions.firestore
  .document("complaints/{complaintId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const description = data.description;
    const category = data.category;
    const docId = context.params.complaintId;

    console.log(`Analyzing complaint: ${docId}`);

    if (!description) return null;

    // 1. Send text to Google Cloud Natural Language API
    const document = {
      content: description,
      type: "PLAIN_TEXT",
    };

    try {
      // Analyze Entities (detects Fire, Flood, etc.)
      const [result] = await client.analyzeEntities({ document });
      const entities = result.entities;

      let calculatedPriority = "Low"; // Default

      // 2. AI LOGIC: Check for dangerous entities
      const criticalKeywords = ["fire", "smoke", "flood", "leak", "explode", "gas", "spark", "danger", "emergency", "blood", "robber", "thief"];
      const mediumKeywords = ["wifi", "internet", "aircond", "hot", "smell", "dirty", "power", "blackout"];

      let foundCritical = false;
      let foundMedium = false;

      entities.forEach((entity) => {
        const word = entity.name.toLowerCase();
        
        // Check if the entity word contains any keyword
        if (criticalKeywords.some((key) => word.includes(key))) {
          foundCritical = true;
        }
        if (mediumKeywords.some((key) => word.includes(key))) {
          foundMedium = true;
        }
      });

      // 3. APPLY RULES
      if (foundCritical) {
        calculatedPriority = "High";
      } else if (foundMedium) {
        calculatedPriority = "Medium";
      } else if (category === "Electrical" && foundMedium) {
        calculatedPriority = "High";
      } else if (category === "Plumbing" && foundMedium) {
        calculatedPriority = "High";
      }

      console.log(`AI Verdict: ${calculatedPriority}`);

      // 4. Update the Firestore Document
      return admin.firestore().collection("complaints").doc(docId).update({
        priority: calculatedPriority,
        aiAnalysis: "Analyzed by Google Cloud", 
      });

    } catch (error) {
      console.error("Error calling Google AI:", error);
      return null; // Keep default if AI fails
    }
  });

// NEW: FR-28 PUSH NOTIFICATIONS
exports.sendPushNotification = functions.firestore
  .document("notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const notifData = snap.data();
    const userId = notifData.userId;
    const title = notifData.title;
    const body = notifData.body;

    console.log(`Sending Push to User: ${userId}`);

    try {
      // 1. Get the User's FCM Token from their profile
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      
      if (!userDoc.exists) {
        console.log("User not found");
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;

      if (!fcmToken) {
        console.log("No FCM Token found for user - skipping push");
        return null;
      }

      // 2. Create the Message Payload
      const message = {
        notification: {
          title: title,
          body: body,
        },
        token: fcmToken,
      };

      // 3. Send via Firebase Messaging
      const response = await admin.messaging().send(message);
      console.log("Successfully sent message:", response);
      return null;

    } catch (error) {
      console.error("Error sending push:", error);
      return null;
    }
  });