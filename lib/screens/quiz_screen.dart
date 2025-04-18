import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import localizations
import 'dart:async'; // For Timer
// import 'package:quiz_master/screens/results_screen.dart'; // No longer navigating here
import 'package:quiz_master/models/question_model.dart'; // Import Question model
import 'package:quiz_master/services/firestore_service.dart'; // Import Firestore service

class QuizScreen extends StatefulWidget {
  final String levelId;
  final String levelName;
  final int worldOrChapterId; // Add this parameter

  const QuizScreen({
    super.key,
    required this.levelId,
    required this.levelName,
    required this.worldOrChapterId, // Add to constructor
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // Service to fetch data
  final FirestoreService _firestoreService = FirestoreService();
  // List to hold fetched questions
  List<Question> _questions = [];
  // Loading state indicator
  bool _isLoading = true;

  int _currentQuestionIndex = 0;
  int _score = 0;
  int _coins = 0; // TODO: Manage coins earned
  String? _selectedAnswer;
  bool _isAnswered = false;
  bool? _isCorrect; // null initially, true/false after answer
  // Hint state
  bool _hintUsed = false;
  Set<String> _hiddenOptions = {};
  bool _isHintLoading = false;
  final int _hintCost = 5; // Cost of using a hint

  // TODO: Implement Timer logic
  // Timer? _timer;
  // int _timeLeft = 30; // Example: 30 seconds per question

  @override
  void initState() {
    super.initState();
    // Fetch questions from Firestore when the screen initializes
    _loadQuestions();
    // TODO: Start timer
    // _startTimer();
  }

  @override
  void dispose() {
    // TODO: Cancel timer
    // _timer?.cancel();
    super.dispose();
  }

  // Method to load questions from Firestore
  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true; // Set loading state
    });
    try {
      final fetchedQuestions = await _firestoreService.getQuestionsForLevel(widget.levelId);
      // Optional: Shuffle questions here if needed
      // fetchedQuestions.shuffle();
      setState(() {
        _questions = fetchedQuestions;
        _isLoading = false; // Set loading state to false
      });
    } catch (e) {
      print("Error loading questions in QuizScreen: $e");
      // Handle error state, maybe show a message to the user
      setState(() {
        _isLoading = false;
        // Optionally clear questions or set an error flag
        _questions = [];
      });
    }
  }

  // void _startTimer() {
  //   _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     if (_timeLeft > 0) {
  //       setState(() { _timeLeft--; });
  //     } else {
  //       _timer?.cancel();
  //       _handleTimeout(); // Handle timeout (e.g., mark as incorrect)
  //     }
  //   });
  // }

  void _handleTimeout() {
    if (!_isAnswered) {
      setState(() {
        _selectedAnswer = null; // No answer selected
        _isAnswered = true;
        _isCorrect = false;
        // TODO: Show explanation or timeout message
      });
    }
  }


  void _selectAnswer(String answer) {
    if (_isAnswered) return; // Prevent changing answer after selection

    // _timer?.cancel(); // Stop timer on answer selection

    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
      _isCorrect = (answer == _questions[_currentQuestionIndex].correctAnswer);
      if (_isCorrect!) {
        _score += 5; // Changed score increment to 5
        _coins += 1; // Keep coin increment as 1 (or adjust if needed)
      }
      // TODO: Add sound effects?
    });
  }

  // Renamed to async to allow awaiting the update
  Future<void> _nextQuestion() async {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
        _isCorrect = null;
        _hintUsed = false; // Reset hint status for next question
        _hiddenOptions = {}; // Clear hidden options
        // _timeLeft = 30; // Reset timer
        // _startTimer(); // Start timer for next question
      });
    } else {
      // Quiz finished
      print("Quiz Finished! Score: $_score, Coins: $_coins");

      // Get current user ID
      final String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null && userId.isNotEmpty) {
        // Try to parse the level number from the levelId (e.g., "level5" -> 5)
        int? completedLevelNum;
        try {
          // Remove non-digit characters and parse
          final numString = widget.levelId.replaceAll(RegExp(r'[^0-9]'), '');
          if (numString.isNotEmpty) {
            completedLevelNum = int.parse(numString);
          }
        } catch (e) {
          print("Error parsing level number from levelId '${widget.levelId}': $e");
        }

        // Update stats in Firestore, including the completed level number if parsed
        await _firestoreService.updateUserStats(
          userId,
          _score,
          _coins,
          completedLevelNumber: completedLevelNum,
          completedQuizId: widget.levelId, // Pass the quizId (which is levelId here)
        );
      } else {
        print("Error: Could not update stats. User not logged in.");
        // Handle case where user is somehow not logged in (e.g., show message)
      }

      // Pop the screen and return the results
      if (!mounted) return;
      Navigator.pop(context, {'score': _score, 'coins': _coins});
    }
  }

  Color _getOptionColor(String option) {
    if (!_isAnswered) {
      return Colors.white; // Default color
    }
    if (option == _selectedAnswer) {
      return _isCorrect! ? Colors.lightGreenAccent.shade100 : Colors.redAccent.shade100;
    }
    if (option == _questions[_currentQuestionIndex].correctAnswer) {
      return Colors.lightGreenAccent.shade100; // Highlight correct answer if wrong one selected
    }
    return Colors.white; // Other options remain default
  }

  IconData? _getOptionIcon(String option) {
     if (!_isAnswered) {
      return null; // No icon before answer
    }
     if (option == _selectedAnswer) {
      return _isCorrect! ? Icons.check_circle : Icons.cancel;
    }
    if (option == _questions[_currentQuestionIndex].correctAnswer) {
      return Icons.check_circle; // Show check for correct answer
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localization instance
    // Show loading indicator while fetching questions
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.levelName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show message if no questions were found after loading
    if (_questions.isEmpty) {
       return Scaffold(
        appBar: AppBar(title: Text(widget.levelName)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.noQuestionsFound(widget.levelName), // Use localized string
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          )
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        // Use localized string with placeholders
        title: Text(l10n.quizScreenTitle(widget.levelName, _currentQuestionIndex + 1, _questions.length)),
        // TODO: Add Timer display
        // actions: [ Padding(padding: EdgeInsets.all(16.0), child: Text('Time: $_timeLeft'))],
      ),
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.purple.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // Wrap the Column with SingleChildScrollView to prevent overflow
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Score/Coins Display ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(l10n.score(_score), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Use localized string
                  Text(l10n.coinsEarned(_coins), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Use localized string
                ],
              ),
            ),
            const Divider(),

            // --- Question Text ---
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                currentQuestion.questionText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),

            // --- Answer Options ---
            // --- Answer Options ---
            ...currentQuestion.options.map((option) {
              // If hint used and this option is marked hidden, show empty space
              if (_hintUsed && _hiddenOptions.contains(option)) {
                return const SizedBox(height: 50 + 12); // Match button height + padding
              }
              // Otherwise, show the button
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ElevatedButton(
                  onPressed: _isAnswered ? null : () => _selectAnswer(option), // Disable after answer
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getOptionColor(option),
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(color: Colors.grey.shade300)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: _isAnswered && _selectedAnswer == option ? 4 : 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(option, textAlign: TextAlign.center)),
                      if (_getOptionIcon(option) != null)
                        Icon(_getOptionIcon(option),
                            color: _isCorrect == true ? Colors.green : Colors.red),
                    ],
                  ),
                ),
              );
            }).toList(),

            // --- Feedback and Explanation ---
            if (_isAnswered)
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(top: 15.0, bottom: 10.0),
                decoration: BoxDecoration(
                  color: _isCorrect! ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: _isCorrect! ? Colors.green : Colors.red)
                ),
                child: Column(
                  children: [
                    Text(
                      _isCorrect! ? l10n.correct : l10n.incorrect, // Use localized strings
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isCorrect! ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                    if (currentQuestion.explanation.isNotEmpty) ...[
                       const SizedBox(height: 8),
                       Text(
                         currentQuestion.explanation,
                         textAlign: TextAlign.center,
                         style: TextStyle(color: _isCorrect! ? Colors.green.shade900 : Colors.red.shade900),
                       ),
                    ]
                  ],
                ),
              ),

            // --- Next Button ---
            if (_isAnswered)
              ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  _currentQuestionIndex < _questions.length - 1 ? l10n.nextQuestion : l10n.finishQuiz, // Use localized strings
                  style: const TextStyle(fontSize: 18),
                ),
              ),

            const SizedBox(height: 15), // Add some spacing

            // --- Hint Button ---
            if (!_isAnswered && !_hintUsed)
              _isHintLoading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                  : TextButton.icon(
                      icon: const Icon(Icons.lightbulb_outline),
                      label: Text(l10n.useHint(_hintCost)), // Use localized string
                      // Pass context to _useHint
                      onPressed: () => _useHint(context),
                      style: TextButton.styleFrom(foregroundColor: Colors.yellow.shade800),
                    ),
            // Add space below hint button if it's visible, otherwise add space before next button if answered
            if (!_isAnswered && !_hintUsed) const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  // Method to handle using a hint
  // Added BuildContext parameter
  Future<void> _useHint(BuildContext context) async {
    // Get localization instance inside the method
    final l10n = AppLocalizations.of(context)!;
    if (_isAnswered || _hintUsed || _isHintLoading) return; // Prevent multiple uses/clicks

    setState(() { _isHintLoading = true; });

    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      print("Hint Error: User not logged in.");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.mustBeLoggedIn), backgroundColor: Colors.red), // Use localized string
         );
         setState(() { _isHintLoading = false; });
       }
      return;
    }

    // Fetch current user data to check coins
    final userData = await _firestoreService.getUserData(userId);
    final currentCoins = userData?.coins ?? 0;

    if (currentCoins < _hintCost) {
      print("Hint Error: Not enough coins.");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.notEnoughCoins(_hintCost)), backgroundColor: Colors.orange), // Use localized string
         );
         setState(() { _isHintLoading = false; });
       }
      return;
    }

    // --- Apply Hint Logic ---
    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion.correctAnswer;
    // Get incorrect options
    final incorrectOptions = currentQuestion.options.where((opt) => opt != correctAnswer).toList();
    // Shuffle them to randomly pick which ones to hide
    incorrectOptions.shuffle();

    // Identify options to hide (usually 2 for a 50/50 hint)
    final optionsToHide = incorrectOptions.take(2).toSet(); // Take the first 2 incorrect options

    // Deduct coins (use negative value)
    await _firestoreService.updateUserStats(userId, 0, -_hintCost);

    // Update state
    if (mounted) {
      setState(() {
        _hiddenOptions = optionsToHide;
        _hintUsed = true;
        _isHintLoading = false;
        // Optional: Update local coin display immediately, though it will refresh on next screen load
        // _coins -= _hintCost; // Be careful if _coins isn't accurately reflecting DB state
      });
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(l10n.hintUsed(_hintCost)), backgroundColor: Colors.blue), // Use localized string
       );
    }
  }
}