import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // For localization
import 'reaction_time_screen.dart'; // Import the reaction time screen
import 'memory_game_screen.dart'; // Import the memory game screen

// TODO: Import actual game screens later
// import 'memory_game_screen.dart';


class MiniGamesMenuScreen extends StatelessWidget {
  const MiniGamesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.miniGames), // Use localized title
        backgroundColor: Colors.purple.shade300,
      ),
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade100, Colors.deepPurple.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          // --- Updated Children List ---
          children: [
            _buildGameCard(
              context: context,
              title: l10n.miniGameMemory, // Use localized string
              icon: Icons.memory,
              color: Colors.teal,
              onTap: () {
                print("Navigate to Memory Game");
                // Navigate to the actual MemoryGameScreen
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MemoryGameScreen()));
                 // ScaffoldMessenger.of(context).showSnackBar(
                 //   SnackBar(content: Text(l10n.memoryGameNotImplemented), duration: const Duration(seconds: 1)), // Use localized string
                 // );
              },
            ),
            const SizedBox(height: 20),
            _buildGameCard(
              context: context,
              title: l10n.miniGameReaction, // Use localized string
              icon: Icons.timer,
              color: Colors.redAccent,
              onTap: () {
                 print("Navigate to Reaction Time Game");
                 // Navigate to the actual ReactionTimeScreen
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const ReactionTimeScreen()));
              },
            ),
            // Add more mini-game cards here
          ],
          // --- End Updated Children List ---
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}