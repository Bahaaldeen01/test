import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // For localization

// Represents a single card in the memory game
class MemoryCard {
  final int id; // Unique identifier for the pair
  final IconData icon; // The icon to display
  bool isFaceUp; // Is the card currently showing its icon?
  bool isMatched; // Has the card been successfully matched?

  MemoryCard({
    required this.id,
    required this.icon,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  List<MemoryCard> _cards = [];
  List<int> _flippedCardIndices = []; // Indices of currently flipped cards (max 2)
  int _pairsFound = 0;
  bool _isChecking = false; // To prevent rapid tapping while checking match

  // Define the icons to use (ensure pairs)
  final List<IconData> _icons = [
    Icons.star, Icons.favorite, Icons.anchor, Icons.bug_report,
    Icons.lightbulb, Icons.ac_unit, Icons.pets, Icons.spa,
    // Add more pairs as needed for difficulty
  ];

  @override
  void initState() {
    super.initState();
    _setupGame();
  }

  void _setupGame() {
    setState(() {
      _pairsFound = 0;
      _flippedCardIndices = [];
      _isChecking = false;
      _cards = [];

      // Create pairs of cards
      List<MemoryCard> cardPairs = [];
      for (int i = 0; i < _icons.length; i++) {
        cardPairs.add(MemoryCard(id: i, icon: _icons[i]));
        cardPairs.add(MemoryCard(id: i, icon: _icons[i]));
      }

      // Shuffle the cards
      cardPairs.shuffle();
      _cards = cardPairs;
    });
  }

  void _handleCardTap(int index) {
    // Ignore taps if already checking, card is matched, or card is already face up
    if (_isChecking || _cards[index].isMatched || _cards[index].isFaceUp) {
      return;
    }

    setState(() {
      _cards[index].isFaceUp = true;
      _flippedCardIndices.add(index);
    });

    // Check if two cards are flipped
    if (_flippedCardIndices.length == 2) {
      setState(() { _isChecking = true; }); // Prevent further taps while checking

      int index1 = _flippedCardIndices[0];
      int index2 = _flippedCardIndices[1];

      // Check for match after a short delay
      Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return; // Check if widget is still mounted

        if (_cards[index1].id == _cards[index2].id) {
          // Match found
          setState(() {
            _cards[index1].isMatched = true;
            _cards[index2].isMatched = true;
            _pairsFound++;
            _flippedCardIndices = [];
            _isChecking = false;
          });
          // Check if game is finished
          if (_pairsFound == _icons.length) {
             // Pass l10n instance to the dialog function
            _showGameFinishedDialog(AppLocalizations.of(context)!);
          }
        } else {
          // No match, flip back
          setState(() {
            _cards[index1].isFaceUp = false;
            _cards[index2].isFaceUp = false;
            _flippedCardIndices = [];
            _isChecking = false;
          });
        }
      });
    }
  }

  // Updated to accept l10n instance
  void _showGameFinishedDialog(AppLocalizations l10n) {
     showDialog(
       context: context,
       barrierDismissible: false, // User must tap button
       builder: (BuildContext context) {
         return AlertDialog(
           title: Text(l10n.congratulations), // Use localized string
           // TODO: Add a specific key for this message if needed
           content: Text("You found all the pairs!"), // Keep hardcoded or add key
           actions: <Widget>[
             TextButton(
               // Use reactionPlayAgain key as it exists
               child: Text(l10n.reactionPlayAgain),
               onPressed: () {
                 Navigator.of(context).pop(); // Close the dialog
                 _setupGame(); // Restart game
               },
             ),
           ],
         );
       },
     );
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localization instance

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.miniGameMemory), // Use localized title
        backgroundColor: Colors.teal,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // Adjust number of columns
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          return _buildCard(index); // Pass l10n if needed inside _buildCard
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setupGame, // Reset button
        tooltip: l10n.reactionTryAgain, // Use existing localized string
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // Updated to accept l10n if needed for future text inside card
  Widget _buildCard(int index) {
    final card = _cards[index];
    // Use AnimatedSwitcher for flip animation (optional but nice)
    return GestureDetector(
      onTap: () => _handleCardTap(index),
      child: Card(
        elevation: card.isFaceUp || card.isMatched ? 0 : 4,
        color: card.isMatched ? Colors.grey.shade300 : (card.isFaceUp ? Colors.white : Colors.blue.shade300),
        child: Center(
          child: card.isFaceUp || card.isMatched
              ? Icon(card.icon, size: 40.0, color: card.isMatched ? Colors.grey.shade500 : Colors.black87)
              : const Icon(Icons.question_mark, size: 40.0, color: Colors.white), // Card back
        ),
      ),
    );
  }
}