import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import 'package:lottie/lottie.dart'; // Import Lottie package
import 'package:quiz_master/screens/home_screen.dart'; // Import HomeScreen
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In
import 'package:quiz_master/services/firestore_service.dart'; // Import FirestoreService

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false; // To show a loading indicator
  final FirestoreService _firestoreService = FirestoreService(); // Instance of FirestoreService

  // --- Placeholder methods for login logic ---
  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; });

    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Handle case where user cancelled the sign-in
      if (googleUser == null) {
        print(AppLocalizations.of(context)!.signInCancelled); // Use localized string
        if (mounted) setState(() { _isLoading = false; });
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        print("Successfully signed in with Google: ${user.displayName}");

        // Check if user exists in Firestore, if not, create a document
        await _firestoreService.createUserIfNeeded(user);

        // Navigate to HomeScreen on success
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
         print("Google Sign-In failed after obtaining credential.");
         if (mounted) setState(() { _isLoading = false; });
         // Show error message
         _showErrorSnackbar(AppLocalizations.of(context)!.signInFailed); // Use localized string
      }

    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception during Google Sign-In: ${e.message}");
      if (mounted) setState(() { _isLoading = false; });
      // Use localized string with placeholder
      _showErrorSnackbar(AppLocalizations.of(context)!.signInError(e.message ?? 'Unknown error'));
    } catch (e) {
      print("An unexpected error occurred during Google Sign-In: $e");
      if (mounted) setState(() { _isLoading = false; });
      // Use localized string with placeholder (reusing signInError for generic case)
      _showErrorSnackbar(AppLocalizations.of(context)!.signInError(e.toString()));
    }
  }

  // Sign in Anonymously
  Future<void> _signInAsGuest() async {
    setState(() { _isLoading = true; });
    final l10n = AppLocalizations.of(context)!; // Get localizations

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final User? user = userCredential.user;

      if (user != null) {
        print("Successfully signed in anonymously: ${user.uid}");
        // Ensure Firestore document exists for anonymous user
        await _firestoreService.createUserIfNeeded(user);

        // Navigate to HomeScreen on success
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        print("Anonymous sign-in failed.");
        if (mounted) setState(() { _isLoading = false; });
        _showErrorSnackbar(l10n.signInFailed);
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception during Anonymous Sign-In: ${e.message}");
      if (mounted) setState(() { _isLoading = false; });
      _showErrorSnackbar(l10n.signInError(e.message ?? 'Unknown error'));
    } catch (e) {
      print("An unexpected error occurred during Anonymous Sign-In: $e");
      if (mounted) setState(() { _isLoading = false; });
      _showErrorSnackbar(l10n.signInError(e.toString()));
    }
  }
  // -----------------------------------------

  // Helper to show error messages
  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the localization instance
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // TODO: Add a professional background/design (maybe using Stack and Lottie)
      backgroundColor: Colors.lightBlue[50], // Simple background for now
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator() // Show loading indicator
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Add Lottie Animation
                    SizedBox(
                      height: 200, // Adjust height as needed
                      child: Lottie.asset(
                        'assets/lottie/login_animation.json', // Make sure this file exists
                        repeat: true, // Loop the animation
                      ),
                    ),
                    const SizedBox(height: 20), // Spacing after animation

                    // App Title
                    Text(
                      l10n.loginScreenTitle, // Use localized string
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                    ),
                    const SizedBox(height: 50),

                    // --- Google Sign-In Button ---
                    ElevatedButton.icon(
                      icon: Image.asset('assets/images/google_logo.png', height: 24.0), // TODO: Add google logo asset
                      label: Text(l10n.signInWithGoogle), // Use localized string
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black, backgroundColor: Colors.white, // Text color
                        minimumSize: const Size(double.infinity, 50), // Full width
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Guest Login Button ---
                    OutlinedButton(
                      child: Text(l10n.continueAsGuest), // Use localized string
                      onPressed: _signInAsGuest,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[800], side: BorderSide(color: Colors.blue[800]!), // Text and border color
                        minimumSize: const Size(double.infinity, 50), // Full width
                         shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // TODO: Add Terms of Service/Privacy Policy links if needed
                  ],
                ),
              ),
      ),
    );
  }
}