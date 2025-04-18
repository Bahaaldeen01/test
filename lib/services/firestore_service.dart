import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_master/models/question_model.dart';
import 'package:quiz_master/models/category_tile.dart'; // Import CategoryTile model
import 'package:quiz_master/models/quiz_level.dart'; // Import QuizLevel model
import 'package:quiz_master/models/leaderboard_entry.dart'; // Import LeaderboardEntry model
import 'package:quiz_master/models/user_data.dart'; // Import UserData model
import 'package:firebase_auth/firebase_auth.dart'; // Import User for type hint

class FirestoreService {
  // Get a reference to the Firestore database instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Question Operations ---

  /// Fetches a list of questions for a specific level ID from the 'questions' collection.
  /// Questions are fetched randomly and limited to a specified count (e.g., 10 questions per quiz).
  Future<List<Question>> getQuestionsForLevel(String levelId, {int limit = 10}) async {
    try {
      // Query the 'questions' collection where 'levelId' matches the requested level
      QuerySnapshot querySnapshot = await _db
          .collection('questions')
          .where('levelId', isEqualTo: levelId)
          // TODO: Implement random fetching if needed. Firestore doesn't directly support random order easily.
          // One common approach is to fetch all, shuffle in Dart, then take the limit.
          // Another is to generate random IDs/numbers and query based on those (more complex).
          // For now, we'll just limit the results. Consider adding an 'order' field if needed.
          // .orderBy('someField') // Add ordering if needed
          .limit(limit) // Limit the number of questions fetched
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No questions found for level ID: $levelId");
        return []; // Return empty list if no questions found
      }

      // Convert each document snapshot into a Question object
      List<Question> questions = querySnapshot.docs
          .map((doc) => Question.fromFirestore(doc))
          .toList();

      // Optional: Shuffle the list in Dart if true randomness per session is desired
      // questions.shuffle();

      // If we fetched more than the limit due to lack of random query, take the limit here after shuffling.
      // return questions.take(limit).toList();

      return questions;

    } catch (e) {
      print("Error fetching questions for level $levelId: $e");
      // Consider throwing a custom exception or returning an empty list/error state
      return []; // Return empty list on error
    }
  }

  // --- User Data Operations (Placeholders - To be implemented later) ---

  /// Fetches user data (UserData model) for a given user ID.
  /// Returns null if the user document doesn't exist or an error occurs.
  Future<UserData?> getUserData(String userId) async {
    if (userId.isEmpty) return null; // Prevent query with empty ID

    try {
      final docSnapshot = await _db.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return UserData.fromFirestore(docSnapshot);
      } else {
        print("User document not found for UID: $userId");
        return null; // User document doesn't exist
      }
    } catch (e) {
      print("Error fetching user data for $userId: $e");
      return null; // Return null on error
    }
  }

  /// Atomically increments the user's points and coins in Firestore.
  /// Optionally updates the highest level completed if the current level is higher,
  /// and adds the completed quizId to the completedQuizzes list.
  Future<void> updateUserStats(String userId, int scoreToAdd, int coinsToAdd, {int? completedLevelNumber, String? completedQuizId}) async {
    if (userId.isEmpty) return; // Invalid user ID

    // Prepare data for update, always include increments even if zero
    Map<String, dynamic> updateData = {
      'points': FieldValue.increment(scoreToAdd),
      'coins': FieldValue.increment(coinsToAdd),
      // Optionally update last activity time as well
      // 'lastActivity': Timestamp.now(),
    };

    // Add completedQuizId to the update if provided
    if (completedQuizId != null && completedQuizId.isNotEmpty) {
      updateData['completedQuizzes'] = FieldValue.arrayUnion([completedQuizId]);
    }

    final userRef = _db.collection('users').doc(userId);

    // Use a transaction to safely read and update highestLevelCompleted
    await _db.runTransaction((transaction) async {
      DocumentSnapshot userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        print("Error updating stats: User document $userId does not exist.");
        // Optionally, we could try creating the user here if needed,
        // but ideally, they should exist from login.
        return; // Exit transaction
      }

      // Check if the completed level needs to update the highest level
      if (completedLevelNumber != null) {
        int currentHighest = (userDoc.data() as Map<String, dynamic>)['highestLevelCompleted'] ?? 0;
        if (completedLevelNumber > currentHighest) {
          updateData['highestLevelCompleted'] = completedLevelNumber;
          print("Updating highestLevelCompleted for $userId to $completedLevelNumber");
        }
      }

      // Perform the update within the transaction
      transaction.update(userRef, updateData);

    }).then((_) {
      print("User stats transaction completed successfully for UID: $userId");
    }).catchError((error) {
      print("Error updating user stats transaction for $userId: $error");
      // Consider how to handle errors - maybe retry? Log?
    });
  }

  /// Checks if a user document exists for the given UID in the 'users' collection.
  /// If not, creates a new document with default values.
  Future<void> createUserIfNeeded(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    final docSnapshot = await userRef.get();

    if (!docSnapshot.exists) {
      // User document doesn't exist, create it
      print('Creating new user document for UID: ${user.uid}');
      final newUser = UserData(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        lastLogin: Timestamp.now(),
        // points and coins default to 0 in the model constructor
      );
      try {
        await userRef.set(newUser.toMap());
        print('User document created successfully.');
      } catch (e) {
        print("Error creating user document: $e");
        // Handle error appropriately, maybe rethrow or log
      }
    } else {
      // User exists, maybe update lastLogin time? (Optional)
      print('User document already exists for UID: ${user.uid}');
      // Example: Update last login time on every login
      // try {
      //   await userRef.update({'lastLogin': Timestamp.now()});
      // } catch (e) {
      //   print("Error updating lastLogin for user ${user.uid}: $e");
      // }
    }
  }


  // --- Leaderboard Operations (Placeholders) ---

  /// Fetches leaderboard data, ordered by points descending.
  /// Returns a list of LeaderboardEntry objects.
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .orderBy('points', descending: true) // Order by points
          .limit(limit) // Limit to top N users
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No users found for leaderboard.");
        return [];
      }

      // Map documents to LeaderboardEntry objects
      List<LeaderboardEntry> leaderboard = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return LeaderboardEntry(
          uid: doc.id,
          // Use display name, fallback to 'Anonymous' or similar if null/empty
          displayName: (data['displayName'] != null && data['displayName'].isNotEmpty)
              ? data['displayName']
              : 'Anonymous Player',
          points: data['points'] ?? 0,
        );
      }).toList();

      return leaderboard;

    } catch (e) {
      print("Error fetching leaderboard: $e");
      // Consider creating a Firestore index for users collection ordered by points descending
      // if you get an error message about needing an index.
      return []; // Return empty list on error
    }
  }


  // --- Level/Category Operations (Placeholders) ---

  /// Fetches the available quiz levels, ordered by levelNumber.
  Future<List<QuizLevel>> getLevels() async {
    try {
      final querySnapshot = await _db
          .collection('levels') // Assuming collection name is 'levels'
          .orderBy('levelNumber') // Order by level number
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No levels found in Firestore.");
        return [];
      }

      // Map documents to QuizLevel objects
      List<QuizLevel> levels = querySnapshot.docs
          .map((doc) => QuizLevel.fromFirestore(doc))
          .toList();

      return levels;

    } catch (e) {
      print("Error fetching levels: $e");
      // Consider creating a Firestore index for levels collection ordered by levelNumber
      // if you get an error message about needing an index.
      return []; // Return empty list on error
    }
  }

  /// Fetches category tiles for a specific chapter/world ID.
  Future<List<CategoryTile>> getCategoryTilesForChapter(int chapterId) async {
    try {
      final querySnapshot = await _db
          .collection('category_tiles') // Assuming collection name is 'category_tiles'
          .where('chapterId', isEqualTo: chapterId)
          // Optional: Order tiles if needed (e.g., by positionY, positionX)
          // .orderBy('positionY')
          .get();

       if (querySnapshot.docs.isEmpty) {
        print("No category tiles found for chapter ID: $chapterId");
        return [];
      }

      // Map documents to CategoryTile objects
      List<CategoryTile> tiles = querySnapshot.docs
          .map((doc) => CategoryTile.fromFirestore(doc))
          .toList();

      return tiles;

    } catch (e) {
       print("Error fetching category tiles for chapter $chapterId: $e");
       // Consider creating a Firestore index if needed for filtering/ordering
       return []; // Return empty list on error
    }
  }
}

// No more TODOs for models here