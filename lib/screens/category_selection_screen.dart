import 'dart:math'; // Import Random
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // For potential future localization
import 'package:quiz_master/models/category_tile.dart'; // Import model
import 'package:quiz_master/services/firestore_service.dart'; // Import service
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:quiz_master/models/user_data.dart'; // Import UserData model
import 'package:quiz_master/screens/quiz_screen.dart'; // Import QuizScreen

class CategorySelectionScreen extends StatefulWidget {
  final int worldOrChapterId; // ID from LevelMapScreen

  const CategorySelectionScreen({
    super.key,
    required this.worldOrChapterId,
  });

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add auth instance
  late Future<List<CategoryTile>> _tilesFuture;
  List<CategoryTile> _fetchedTiles = []; // Store fetched tiles to access name on tap
  UserData? _userData; // Store fetched user data
  bool _isLoadingUserData = true; // Loading state for user data

  @override
  void initState() {
    super.initState();
    // Fetch tiles and user data when the screen initializes
    _loadInitialData();
  }

  // Helper to load both tiles and user data
  Future<void> _loadInitialData() async {
    setState(() { _isLoadingUserData = true; }); // Start loading user data

    // Fetch tiles
    _tilesFuture = _firestoreService.getCategoryTilesForChapter(widget.worldOrChapterId);
    // Store tiles once future completes (needed for navigation logic)
    _tilesFuture.then((tiles) {
       if (mounted) {
         setState(() { _fetchedTiles = tiles; });
       }
    });


    // Fetch user data
    final currentUser = _auth.currentUser;
    UserData? fetchedUserData;
    if (currentUser != null) {
      fetchedUserData = await _firestoreService.getUserData(currentUser.uid);
    } else {
       print("CategorySelectionScreen: User not logged in.");
       // Handle guest case if necessary, maybe default UserData?
    }

    if (mounted) {
      setState(() {
        _userData = fetchedUserData;
        _isLoadingUserData = false; // Finish loading user data
      });
    }
  }

  // Handles tile taps - now async to await quiz result
  Future<void> _navigateToQuiz(String tileId) async {
    // Find the tapped tile in the fetched list
    final tappedTile = _fetchedTiles.firstWhere(
      (tile) => tile.id == tileId,
      orElse: () => CategoryTile(
          id: '', chapterId: 0, type: TileType.level, name: 'Error',
          iconName: '', colorHex: ''
      ),
    );

    // Only navigate if it's a level tile and has a quizId
    if (tappedTile.type == TileType.level && tappedTile.quizId != null && tappedTile.quizId!.isNotEmpty) {
       print("Navigating to Quiz for Tile: ${tappedTile.name} (ID: ${tappedTile.quizId})");

       // Await the result from QuizScreen
       final result = await Navigator.push<Map<String, int>>( // Specify expected result type
         context,
         MaterialPageRoute(
           builder: (context) => QuizScreen(
             levelId: tappedTile.quizId!,
             levelName: tappedTile.name,
             worldOrChapterId: widget.worldOrChapterId,
           ),
         ),
       );

       // --- Process Quiz Result ---
       if (result != null && mounted) {
         final score = result['score'] ?? 0;
         final coins = result['coins'] ?? 0;
         final l10n = AppLocalizations.of(context)!; // Get localizations

         // Show results snackbar
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             // TODO: Create better localized result message
             content: Text('Quiz Complete! Score: $score, Coins Earned: $coins'),
             duration: const Duration(seconds: 3),
           ),
         );

         // Refresh user data to update top bar and tile completion status
         await _loadInitialData();
       }
       // --- End Result Processing ---

    } else if (tappedTile.type == TileType.special) {
       // Handle special tile tap (e.g., show reward)
       print("Special Tile tapped: ${tappedTile.name} (ID: $tileId)");
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Special Tile "${tappedTile.name}" tapped!')), // TODO: Localize
       );
    } else {
       print("Level Tile tapped but missing quizId: ${tappedTile.name} (ID: $tileId)");
        ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Quiz not available for "${tappedTile.name}" yet.')), // TODO: Localize
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context)!; // Get localization instance if needed

    return Scaffold(
      backgroundColor: Colors.orange[50], // Light background
      body: SafeArea( // Ensure content doesn't overlap status bar etc.
        child: Column(
          children: [
            _buildTopBar(context),
            _buildProgressBar(context),
            Expanded( // Make the main area fill remaining space
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  // Use FutureBuilder to display tiles
                  child: FutureBuilder<List<CategoryTile>>(
                    future: _tilesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        // TODO: Localize error message
                        return Center(child: Text('Error loading categories: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                         // TODO: Localize empty message
                        return const Center(child: Text('No categories found for this chapter.'));
                      }
                      // Pass the fetched tiles to the layout builder
                      return _buildTileLayout(context, snapshot.data!);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets (To be implemented below) ---

  // Builds the top bar with settings, stats, and back button
  Widget _buildTopBar(BuildContext context) {
    // TODO: Fetch actual stats (lives, points, coins)
    const int lives = 5;
    const int points = 1250;
    const int coins = 300;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Settings Button
          IconButton(
            icon: Icon(Icons.settings, color: Colors.grey.shade800, size: 28),
            onPressed: () {
              // TODO: Navigate to Settings Screen
              print("Settings button tapped");
            },
          ),
          // Stats Counters
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatCounter(Icons.favorite, Colors.red, lives),
              const SizedBox(width: 16),
              _buildStatCounter(Icons.spa, Colors.green, points), // Using spa for points
              const SizedBox(width: 16),
              _buildStatCounter(Icons.monetization_on, Colors.amber.shade700, coins),
            ],
          ),
          // Back/Exit Button
          IconButton(
            icon: Icon(Icons.arrow_forward, color: Colors.grey.shade800, size: 28), // Use arrow_forward for back in LTR context
            onPressed: () => Navigator.maybePop(context),
          ),
        ],
      ),
    );
  }

  // Helper for individual stat counters in the top bar
  Widget _buildStatCounter(IconData icon, Color color, int value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
// Builds the progress bar section
Widget _buildProgressBar(BuildContext context) {
  // TODO: Fetch actual progress value (e.g., 0.0 to 1.0)
  const double progress = 0.6; // Placeholder 60%
  const double barHeight = 12.0;
  const double starSize = 28.0;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
    child: Stack(
      clipBehavior: Clip.none, // Allow stars to overflow slightly
      alignment: Alignment.centerLeft,
      children: [
        // Background Bar
        Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(barHeight / 2),
          ),
        ),
        // Progress Bar
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade400,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),
        ),
        // Stars (Positioned along the bar)
        // TODO: Calculate positions based on actual milestones
        Positioned(
          left: MediaQuery.of(context).size.width * 0.2 - (starSize / 2) - 20, // Adjust based on padding
          top: -(starSize / 2) + (barHeight / 2), // Center vertically
          child: Icon(Icons.star, color: Colors.blue.shade700, size: starSize),
        ),
         Positioned(
          left: MediaQuery.of(context).size.width * 0.5 - (starSize / 2) - 20, // Adjust based on padding
          top: -(starSize / 2) + (barHeight / 2),
          child: Icon(Icons.star, color: Colors.blue.shade700, size: starSize),
        ),
         Positioned(
          left: MediaQuery.of(context).size.width * 0.8 - (starSize / 2) - 20, // Adjust based on padding
          top: -(starSize / 2) + (barHeight / 2),
          child: Icon(Icons.star, color: Colors.blue.shade700, size: starSize),
        ),
      ],
    ),
     );
  }

  // Builds the main area with randomly positioned tiles, considering completion status
  Widget _buildTileLayout(BuildContext context, List<CategoryTile> tiles) {
    // Use the already fetched _userData which contains completedQuizzes
    final Set<String> completedQuizIds = _userData?.completedQuizzes.toSet() ?? {}; // Use a Set for efficient lookup
    final random = Random();
    final screenWidth = MediaQuery.of(context).size.width - 32; // Subtract padding
    final tileWidgets = <Widget>[];
    double currentY = 20.0; // Starting Y position
    double maxStackHeight = currentY;

    // Simple random placement logic (can be improved for better distribution)
    for (var tile in tiles) {
      // Random horizontal position (e.g., 10% to 80% of width)
      double leftPos = (random.nextDouble() * (screenWidth * 0.7)) + (screenWidth * 0.1);
      // Ensure it doesn't go too far right if we calculate width
      // double tileWidth = (tile.type == TileType.level) ? 100 : 70;
      // if (leftPos + tileWidth > screenWidth) {
      //   leftPos = screenWidth - tileWidth;
      // }

      // Increment Y position for the next tile, with some randomness
      double topPos = currentY;
      currentY += 100 + (random.nextDouble() * 50); // Base spacing + random variation

      if (topPos + 120 > maxStackHeight) { // Estimate tile bottom position
         maxStackHeight = topPos + 120;
      }

      // Check if this level tile is completed
      bool isCompleted = tile.type == TileType.level &&
                         tile.quizId != null &&
                         completedQuizIds.contains(tile.quizId!);

      if (tile.type == TileType.level) {
        tileWidgets.add(Positioned(
          top: topPos,
          left: leftPos,
          child: LevelTile(
            id: tile.id,
            icon: tile.iconData,
            color: tile.color,
            level: tile.difficultyLevel ?? 1,
            onTap: _navigateToQuiz,
            isCompleted: isCompleted, // Pass completion status
          ),
        ));
      } else { // Special Tile
        // TODO: Add logic for special tile completion if needed
         tileWidgets.add(Positioned(
          top: topPos,
          left: leftPos,
          child: SpecialTile(
            id: tile.id,
            icon: tile.iconData,
            color: tile.color,
            shape: BoxShape.circle, // Assuming special are circles
            onTap: _navigateToQuiz,
          ),
        ));
      }
    }
     maxStackHeight += 50; // Add final padding

    return SizedBox( // Use SizedBox to constrain Stack height for scrolling
      height: maxStackHeight,
      child: Stack(
        children: tileWidgets,
      ), // <-- Added missing closing parenthesis for Stack
    );
  }

  // --- Tile Widgets ---

  // Represents a standard level/category tile
  Widget LevelTile({
    required String id,
    required IconData icon,
    required Color color,
    required int level,
    required Function(String) onTap,
    required bool isCompleted, // Add parameter
  }) {
    return GestureDetector(
      onTap: () => onTap(id),
      // Wrap the main content and the conditional overlay in a Stack
      child: Stack(
        children: [
          // Main Tile Content Container
          Container(
            width: 100, // Adjust size
            height: 100, // Adjust size
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: Offset(2, 2)),
              ],
            ),
            child: Stack( // Inner stack for icon and level number
              children: [
                Center(child: Icon(icon, color: Colors.white, size: 45)),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      level.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Conditional Overlay for completed tiles
          if (isCompleted)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3), // Darken completed tiles
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Icon(Icons.check_circle_outline, color: Colors.white.withOpacity(0.8), size: 30),
              ),
            ),
        ],
      ),
    );
  }

  // Represents a special tile (e.g., gift box, bonus)
  Widget SpecialTile({
    required String id,
    required IconData icon,
    required Color color,
    required BoxShape shape,
    required Function(String) onTap,
  }) {
     return GestureDetector(
      onTap: () => onTap(id),
      child: Container(
        width: 70, // Adjust size
        height: 70, // Adjust size
        decoration: BoxDecoration(
          color: color,
          shape: shape,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 35)),
      ),
    );
  }

}