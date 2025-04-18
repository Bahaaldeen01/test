import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import localizations
import 'package:quiz_master/models/leaderboard_entry.dart';
import 'package:quiz_master/services/firestore_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<LeaderboardEntry>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _firestoreService.getLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localization instance
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaderboardScreenTitle), // Use localized string
        backgroundColor: Colors.orangeAccent,
      ),
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.deepOrange.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<LeaderboardEntry>>(
          future: _leaderboardFuture,
          builder: (context, snapshot) {
            // --- Loading State ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // --- Error State ---
            if (snapshot.hasError) {
              print("Leaderboard Error: ${snapshot.error}");
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  // Replace with AppLocalizations
                  // Use localized string with placeholder
                  child: Text(
                    l10n.leaderboardError(snapshot.error.toString()),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            // --- Empty State ---
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center( // Removed const
                // Replace with AppLocalizations
                child: Text(l10n.leaderboardEmpty), // Use localized string
              );
            }

            // --- Data Loaded State ---
            final leaderboard = snapshot.data!;
            return ListView.builder(
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final entry = leaderboard[index];
                final rank = index + 1;

                // Highlight top 3?
                Color tileColor = Colors.white.withOpacity(0.8);
                IconData rankIcon = Icons.emoji_events_outlined;
                Color rankColor = Colors.grey;
                if (rank == 1) {
                  tileColor = Colors.amber.shade100.withOpacity(0.9);
                  rankIcon = Icons.emoji_events;
                  rankColor = Colors.amber.shade800;
                } else if (rank == 2) {
                  tileColor = Colors.grey.shade300.withOpacity(0.9);
                   rankColor = Colors.grey.shade700;
                } else if (rank == 3) {
                  tileColor = Colors.brown.shade100.withOpacity(0.9);
                   rankColor = Colors.brown.shade600;
                }

                return Card(
                  elevation: 3.0,
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  color: tileColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rankColor,
                      foregroundColor: Colors.white,
                      child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                      entry.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade600, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.points}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    // TODO: Add onTap to view user profile? (Future enhancement)
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}