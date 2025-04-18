import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quiz_master/screens/category_selection_screen.dart'; // Import Category screen
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:quiz_master/services/firestore_service.dart'; // Import FirestoreService
import 'package:quiz_master/models/user_data.dart'; // Import UserData model
// TODO: Import AppLocalizations if localizing text

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  final int totalLevels = 100;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _highestLevelCompleted = 0;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load data first

    // Schedule scroll jump after the first frame *after* loading is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if loading is done and controller is attached
      if (!_isLoading && _scrollController.hasClients) {
        // Add a small delay to ensure layout is fully complete after loading state change
        Future.delayed(const Duration(milliseconds: 50), () {
           if (_scrollController.hasClients) { // Check again after delay
             _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
           }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the controller
    super.dispose();
  }

  // Method to load user data
  Future<void> _loadUserData() async {
    // Avoid calling setState if already loading or disposed
    if (!_isLoading) {
       setState(() { _isLoading = true; });
    } else if (!mounted) {
       return; // Don't proceed if disposed
    }

    final currentUser = _auth.currentUser;
    int fetchedLevel = 0;

    if (currentUser != null) {
      final data = await _firestoreService.getUserData(currentUser.uid);
      fetchedLevel = data?.highestLevelCompleted ?? 0;
    } else {
      print("LevelMapScreen: User not logged in, defaulting unlocked level to 0.");
    }

    if (mounted) {
      setState(() {
        _highestLevelCompleted = fetchedLevel;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/map_background.jpg', // Ensure this image exists
                    fit: BoxFit.cover,
                  ),
                ),

                // Scrollable Level Path
                Positioned.fill(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
                      child: Column(
                        children: List.generate(totalLevels, (index) {
                          final level = totalLevels - index;
                          final isUnlocked = level <= (_highestLevelCompleted + 1);
                          final isLeft = level % 2 != 0; // Odd levels on the left

                          return Stack(
                            clipBehavior: Clip.none, // Allow connection lines to draw outside bounds
                            children: [
                              // Connection Line (Draw above current level)
                              if (level < totalLevels)
                                Positioned(
                                  // Position based on the *next* level's alignment (level + 1)
                                  left: (level + 1) % 2 != 0 ? 85 : null, // If next level is odd (left), line starts left
                                  right: (level + 1) % 2 == 0 ? 85 : null, // If next level is even (right), line starts right
                                  // Adjust top/bottom positioning relative to the *current* marker's center
                                  top: -25, // Start above the current marker's vertical padding
                                  bottom: 80 + 25, // Extend below the current marker's height + padding
                                  child: Container(width: 3, color: Colors.black.withOpacity(0.4)),
                                ),

                              // Level Marker Row
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 25),
                                child: Row(
                                  mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (isUnlocked) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CategorySelectionScreen(
                                                worldOrChapterId: level,
                                              ),
                                            ),
                                          ).then((_) {
                                            // Optional: Refresh user data when returning from category screen
                                            // _loadUserData();
                                          });
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('المرحلة $level مقفلة'), // TODO: Localize
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      },
                                      child: CircleAvatar(
                                        radius: 40,
                                        backgroundColor: isUnlocked ? Colors.amber.shade700 : Colors.blueGrey.shade600,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Text(
                                              '$level',
                                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2.0, color: Colors.black.withOpacity(0.5), offset: Offset(1.0, 1.0))]),
                                            ),
                                            if (!isUnlocked) Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle)),
                                            if (!isUnlocked) Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.8), size: 30),
                                            if (isUnlocked) Positioned(top: 5, right: 5, child: Icon(Icons.star, color: Colors.yellow.shade600, size: 18)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                // Back Button
                Positioned(
                  top: 10,
                  left: 10,
                  child: SafeArea(
                    child: FloatingActionButton.small(
                      heroTag: 'levelMapBack',
                      backgroundColor: Colors.black.withOpacity(0.5),
                      foregroundColor: Colors.white,
                      onPressed: () => Navigator.maybePop(context),
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
