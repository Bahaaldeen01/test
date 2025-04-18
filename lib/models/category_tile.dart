import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For IconData and Color parsing

enum TileType { level, special }

class CategoryTile {
  final String id; // Document ID from Firestore
  final int chapterId; // Which chapter/world this tile belongs to
  final TileType type; // Type of tile (level or special)
  final String name; // Display name (e.g., "Geography", "Bonus Chest")
  final String iconName; // String name of the Material Icon
  final String colorHex; // Hex string for the color (e.g., "FF4CAF50")
  // Removed positionX and positionY - will be generated locally
  final int? difficultyLevel; // Optional difficulty for level tiles
  final String? quizId; // Optional ID for the quiz associated with level tiles

  CategoryTile({
    required this.id,
    required this.chapterId,
    required this.type,
    required this.name,
    required this.iconName,
    required this.colorHex,
    // required this.positionX, // Removed
    // required this.positionY, // Removed
    this.difficultyLevel,
    this.quizId,
  });

  // Factory constructor from Firestore document
  factory CategoryTile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    TileType tileType = TileType.level; // Default to level
    if (data['type'] == 'special') {
      tileType = TileType.special;
    }

    return CategoryTile(
      id: doc.id,
      chapterId: data['chapterId'] ?? 0, // Default or handle error
      type: tileType,
      name: data['name'] ?? 'Unnamed Tile',
      iconName: data['iconName'] ?? 'help_outline',
      colorHex: data['colorHex'] ?? 'FF757575', // Default grey
      // Removed position parsing
      difficultyLevel: data['difficultyLevel'], // Can be null
      quizId: data['quizId'], // Can be null
    );
  }

   // Helper method to get IconData from string name
  IconData get iconData {
     switch (iconName) {
      // Add icons used in your categories/tiles
      case 'public': return Icons.public;
      case 'local_florist': return Icons.local_florist;
      case 'sports_soccer': return Icons.sports_soccer;
      case 'face': return Icons.face;
      case 'theater_comedy': return Icons.theater_comedy;
      case 'science': return Icons.science;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'sync': return Icons.sync;
      // Add more icons as needed
      default: return Icons.help_outline;
    }
  }

  // Helper method to get Color from hex string
  Color get color {
    try {
      final String hex = colorHex.startsWith('FF') ? colorHex : 'FF$colorHex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      print("Error parsing color hex '$colorHex': $e");
      return Colors.grey; // Default color on error
    }
  }

  // Method to convert object to Map (optional)
   Map<String, dynamic> toMap() {
    return {
      'chapterId': chapterId,
      'type': type == TileType.special ? 'special' : 'level',
      'name': name,
      'iconName': iconName,
      'colorHex': colorHex,
      // Removed positions from map
      'difficultyLevel': difficultyLevel,
      'quizId': quizId,
    };
  }
}