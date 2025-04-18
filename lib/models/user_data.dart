import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String uid; // Matches FirebaseAuth user ID
  final String? displayName; // From Auth provider or custom
  final String? email; // From Auth provider
  final int points;
  final int coins;
  final Timestamp lastLogin;
  final int highestLevelCompleted; // Track user progress
  final List<String> completedQuizzes; // List of completed quiz IDs (from CategoryTile quizId)
  // Add other fields as needed, e.g., avatarUrl, etc.

  UserData({
    required this.uid,
    this.displayName,
    this.email,
    this.points = 0, // Default values for new users
    this.coins = 0,  // Default values for new users
    required this.lastLogin,
    this.highestLevelCompleted = 0, // Default for new users
    this.completedQuizzes = const [], // Default to empty list
  });

  // Factory constructor from Firestore document
  factory UserData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id, // Use document ID as UID
      displayName: data['displayName'],
      email: data['email'],
      points: data['points'] ?? 0,
      coins: data['coins'] ?? 0,
      lastLogin: data['lastLogin'] ?? Timestamp.now(), // Provide default if missing
      highestLevelCompleted: data['highestLevelCompleted'] ?? 0,
      // Handle potential type issues when reading from Firestore
      completedQuizzes: List<String>.from(data['completedQuizzes'] ?? []),
    );
  }

  // Method to convert UserData object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'points': points,
      'coins': coins,
      'lastLogin': lastLogin,
      'highestLevelCompleted': highestLevelCompleted,
      'completedQuizzes': completedQuizzes,
      // Don't include uid here as it's the document ID
    };
  }
}