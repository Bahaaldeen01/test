import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // For localization

enum ReactionGameState { waiting, ready, tooSoon, finished }

class ReactionTimeScreen extends StatefulWidget {
  const ReactionTimeScreen({super.key});

  @override
  State<ReactionTimeScreen> createState() => _ReactionTimeScreenState();
}

class _ReactionTimeScreenState extends State<ReactionTimeScreen> {
  ReactionGameState _gameState = ReactionGameState.waiting;
  Timer? _timer;
  Stopwatch _stopwatch = Stopwatch();
  int _reactionTimeMs = 0;
  Random _random = Random();

  @override
  void initState() {
    super.initState();
    _setupGame();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer if screen is disposed
    super.dispose();
  }

  void _setupGame() {
    setState(() {
      _gameState = ReactionGameState.waiting;
      _reactionTimeMs = 0;
      _stopwatch.reset();
    });

    // Schedule the color change after a random delay (e.g., 1.5 to 4.5 seconds)
    final waitDuration = Duration(milliseconds: 1500 + _random.nextInt(3000));
    _timer = Timer(waitDuration, () {
      // Check if the widget is still mounted before changing state
      if (mounted) {
        setState(() {
          _gameState = ReactionGameState.ready;
        });
        _stopwatch.start(); // Start timer when color changes
      }
    });
  }

  void _handleTap() {
    if (!mounted) return; // Check if widget is still mounted

    _timer?.cancel(); // Stop the timer regardless of state

    if (_gameState == ReactionGameState.waiting) {
      // Tapped too soon
      setState(() {
        _gameState = ReactionGameState.tooSoon;
      });
    } else if (_gameState == ReactionGameState.ready) {
      // Tapped on time
      _stopwatch.stop();
      setState(() {
        _reactionTimeMs = _stopwatch.elapsedMilliseconds;
        _gameState = ReactionGameState.finished;
      });
    }
    // If already finished or tooSoon, tap does nothing until reset
  }

  Color _getBackgroundColor() {
    switch (_gameState) {
      case ReactionGameState.waiting:
        return Colors.blueGrey; // Initial waiting color
      case ReactionGameState.ready:
        return Colors.green; // Ready color
      case ReactionGameState.tooSoon:
        return Colors.redAccent; // Too soon color
      case ReactionGameState.finished:
        return Colors.lightBlueAccent; // Finished color
    }
  }

  Widget _buildContent(AppLocalizations l10n) { // Pass l10n instance
    switch (_gameState) {
      case ReactionGameState.waiting:
        return Text(
          l10n.reactionWait, // Use localized string
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        );
      case ReactionGameState.ready:
         return Text(
          l10n.reactionTapNow, // Use localized string
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
           textAlign: TextAlign.center,
        );
      case ReactionGameState.tooSoon:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Text(
              l10n.reactionTooSoon, // Use localized string
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
               textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _setupGame, child: Text(l10n.reactionTryAgain)) // Use localized string
          ],
        );
      case ReactionGameState.finished:
         return Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Text(
              l10n.reactionYourTime, // Use localized string
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87),
               textAlign: TextAlign.center,
            ),
             Text(
              "$_reactionTimeMs ms", // Keep ms unit hardcoded for now
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
               textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _setupGame, child: Text(l10n.reactionPlayAgain)) // Use localized string
           ],
         );
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations instance

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reactionGameTitle), // Use localized string
        backgroundColor: _getBackgroundColor(), // Change AppBar color based on state
      ),
      body: GestureDetector(
        onTap: _handleTap, // Handle taps anywhere on the body
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100), // Quick color transition
          color: _getBackgroundColor(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildContent(l10n), // Pass l10n to helper
            ),
          ),
        ),
      ),
    );
  }
}