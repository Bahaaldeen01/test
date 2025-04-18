import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For IconData and Color parsing

class QuizLevel {
  final String id; // Document ID from Firestore
  final String name; // Display name (consider localization later)
  final int levelNumber; // For ordering
  final String iconName; // String name of the Material Icon
  final String colorHex; // Hex string for the color (e.g., "FF4CAF50" for Colors.green)
  // Add other fields if needed, e.g., description, unlockRequirement (points/level)

  QuizLevel({
    required this.id,
    required this.name,
    required this.levelNumber,
    required this.iconName,
    required this.colorHex,
  });

  // Factory constructor from Firestore document
  factory QuizLevel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return QuizLevel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Level',
      levelNumber: data['levelNumber'] ?? 999, // Default to high number if missing
      iconName: data['iconName'] ?? 'help_outline', // Default icon
      colorHex: data['colorHex'] ?? 'FF757575', // Default grey color (Colors.grey.value.toRadixString(16))
    );
  }

  // Helper method to get IconData from string name
  // This is basic; a more robust solution might use a map or code generation
  IconData get iconData {
    switch (iconName) {
      case 'star_border': return Icons.star_border;
      case 'star_half': return Icons.star_half;
      case 'star': return Icons.star;
      case 'verified': return Icons.verified;
      case 'school': return Icons.school;
      // Add more icons as needed
      default: return Icons.help_outline;
    }
  }

  // Helper method to get Color from hex string
  Color get color {
    try {
      // Ensure hex string starts with FF for opacity if not provided
      final String hex = colorHex.startsWith('FF') ? colorHex : 'FF$colorHex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      print("Error parsing color hex '$colorHex': $e");
      return Colors.grey; // Default color on error
    }
  }

   // Method to convert QuizLevel object to a Map for Firestore (optional)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'levelNumber': levelNumber,
      'iconName': iconName,
      'colorHex': colorHex,
    };
  }
}