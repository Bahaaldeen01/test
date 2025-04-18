import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import localizations
import 'package:lottie/lottie.dart'; // Import Lottie
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:quiz_master/models/user_data.dart'; // Import UserData model
import 'package:quiz_master/services/firestore_service.dart'; // Import FirestoreService
// import 'package:quiz_master/screens/quiz_level_screen.dart'; // No longer used for navigation here
import 'package:quiz_master/screens/level_map_screen.dart'; // Import LevelMapScreen
import 'package:quiz_master/screens/leaderboard_screen.dart'; // Import LeaderboardScreen
import 'package:quiz_master/screens/mini_games_menu_screen.dart'; // Import MiniGamesMenuScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserData? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() { _isLoading = true; });
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final data = await _firestoreService.getUserData(currentUser.uid);
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } else {
      // Should not happen if StreamBuilder in main.dart works correctly,
      // but handle defensively. Could log out here.
      print("Error: Current user is null in HomeScreen initState.");
       if (mounted) {
         setState(() { _isLoading = false; });
         // Optionally sign out and let StreamBuilder handle navigation
         // await _auth.signOut();
       }
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // No need to navigate here, StreamBuilder in main.dart will handle it
      print("User logged out successfully.");
    } catch (e) {
      print("Error logging out: $e");
      // Show error message if needed
      if (mounted) {
         // Use localized string with placeholder
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.logoutError(e.toString())), backgroundColor: Colors.red),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get localization instance
    final l10n = AppLocalizations.of(context)!;
    // Use fetched data or defaults/loading state
    // Use localized default if name is unavailable
    final String userName = _userData?.displayName ?? _auth.currentUser?.displayName ?? l10n.anonymousPlayer;
    final int userPoints = _userData?.points ?? 0;
    final int userCoins = _userData?.coins ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeScreenTitle), // Use localized string
        // TODO: Add user profile icon/button?
        actions: [
          // Display Points and Coins
          // Wrap the Row with Flexible to prevent overflow in AppBar actions
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Use minimum space necessary
                children: [
                  Icon(Icons.star, color: Colors.amber), // Points icon
                  const SizedBox(width: 4),
                  // Add tooltip for clarity
                  Tooltip(message: l10n.points, child: Text('$userPoints')),
                  const SizedBox(width: 16),
                  Icon(Icons.monetization_on, color: Colors.green), // Coins icon
                  const SizedBox(width: 4),
                  // Add tooltip for clarity
                  Tooltip(message: l10n.coins, child: Text('$userCoins')),
                ],
              ),
            ),
          ),
          // TODO: Add Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout, // Use localized string
            onPressed: _logout, // Call the logout method
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : Container(
              // TODO: Add background design (maybe gradient or image)
              // Wrap the Column with SingleChildScrollView
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // --- Welcome Message / Lottie Animation ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      l10n.welcomeMessage(userName), // Use localized string with placeholder
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Add Lottie Animation
                  SizedBox(
                    height: 150, // Adjust height as needed
                    child: Lottie.asset(
                      'assets/lottie/welcome_animation.json', // Make sure this file exists
                      repeat: false, // Don't loop welcome animation
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- Main Action Buttons ---
                  _buildActionButton(
                    context: context,
                    icon: Icons.play_circle_fill,
                    label: l10n.startQuiz, // Use localized string
                    color: Colors.blue,
                    onPressed: () {
                      // Navigate to Level Map Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LevelMapScreen()), // Removed const
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    context: context,
                    icon: Icons.leaderboard,
                    label: l10n.leaderboard, // Use localized string
                    color: Colors.orange,
                    onPressed: () {
                      // Navigate to Leaderboard Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    context: context,
                    icon: Icons.games,
                    label: l10n.miniGames, // Use localized string
                    color: Colors.purple,
                    onPressed: () {
                      // Navigate to Mini-Games Menu Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MiniGamesMenuScreen()),
                      );
                    },
                  ),
                   const SizedBox(height: 20),
                   _buildActionButton(
                    context: context,
                    icon: Icons.settings,
                    label: l10n.settings, // Use localized string
                    color: Colors.grey,
                    onPressed: () {
                      // TODO: Navigate to Settings Screen
                      print("Navigate to Settings Screen Placeholder");
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
                    },
                  ),

                  // TODO: Add other elements like daily challenges, store, etc.
                  ],
                ),
              ),
            ),
    );
  }

  // Helper widget for creating styled action buttons
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      // Use the provided label directly as it's already localized
      label: Text(label, style: const TextStyle(fontSize: 18)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: color, // Text color
        minimumSize: const Size(double.infinity, 60), // Full width, larger height
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}