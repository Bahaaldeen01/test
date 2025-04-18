import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id; // Document ID from Firestore
  final String questionText;
  final List<String> options; // List of possible answers
  final String correctAnswer;
  final String explanation; // Explanation shown after answering
  final String levelId; // To associate question with a level/category
  // Add other fields if needed, e.g., difficulty, imageURL

  Question({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.levelId,
  });

  // Factory constructor to create a Question object from a Firestore document snapshot
  factory Question.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Basic validation or default values
    List<String> optionsList = List<String>.from(data['options'] ?? []);
    if (optionsList.length < 2) {
      // Ensure there are at least some options, handle error or default
      print("Warning: Question ${doc.id} has less than 2 options.");
      // optionsList.addAll(['Default Option 1', 'Default Option 2']); // Example default
    }

    return Question(
      id: doc.id,
      questionText: data['questionText'] ?? 'No question text provided',
      options: optionsList,
      correctAnswer: data['correctAnswer'] ?? '', // Should ideally have a correct answer
      explanation: data['explanation'] ?? 'No explanation available.',
      levelId: data['levelId'] ?? 'unknown', // Associate with a level
    );
  }

  // Method to convert Question object to a Map for Firestore (optional, if needed for writing)
  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'levelId': levelId,
    };
  }
}