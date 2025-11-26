// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your core screens
import 'screens/login_signup_screen.dart';
import 'screens/property_listings_screen.dart'; 

void main() async {
  // 1. Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize Firebase Core
  // This must complete before running the app
  await Firebase.initializeApp(); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Property Pulse',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      
      // FIX: Use 'initialRoute' and 'routes' map, but DO NOT use 'home'
      initialRoute: '/',
      routes: {
        // The root route points to the checker (AuthWrapper)
        '/': (context) => const AuthWrapper(), 
      },
    );
  }
}

// ----------------------------------------------------
// AUTH WRAPPER
// Checks the authentication state and navigates accordingly
// ----------------------------------------------------
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to changes in the authentication state
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. User is Logged In
        if (snapshot.hasData && snapshot.data != null) {
          // If a user object exists, show the main application screen
          return const PropertyListingsScreen();
        } 
        
        // 3. User is NOT Logged In
        else {
          // If no user object exists, show the login/signup screen
          return const LoginSignupScreen();
        }
      },
    );
  }
}