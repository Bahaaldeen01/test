// Represents a single entry in the leaderboard
class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int points;
  // Add other fields if needed, e.g., rank, avatarUrl

  LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.points,
  });

  // Helper factory to create from UserData (if needed, or adapt Firestore query)
  // factory LeaderboardEntry.fromUserData(UserData userData) {
  //   return LeaderboardEntry(
  //     uid: userData.uid,
  //     displayName: userData.displayName ?? 'Unknown Player',
  //     points: userData.points,
  //   );
  // }
}