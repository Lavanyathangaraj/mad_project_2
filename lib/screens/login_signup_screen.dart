// lib/screens/login_signup_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart'; 
import 'property_listings_screen.dart'; // Target screen for successful login/signup

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  _LoginSignupScreenState createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool isLogin = true;
  String errorMessage = '';
  bool _isLoading = false;
  
  // State for Role Selection (defaults to Buyer)
  UserRole _selectedRole = UserRole.Buyer; 

  void toggleForm() {
    setState(() {
      isLogin = !isLogin;
      errorMessage = '';
      _nameController.clear(); // Clear name field when toggling
    });
  }

  Future<void> submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // Basic Validation
    if (email.isEmpty || password.isEmpty || (!isLogin && name.isEmpty)) {
      setState(() {
        errorMessage = "Please fill all required fields.";
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user;
      if (isLogin) {
        // Use the sign-in function from AuthService
        user = await _authService.signIn(email: email, password: password);
      } else {
        // Use the sign-up function from AuthService
        user = await _authService.signUp(
          name: name,
          email: email,
          password: password,
          role: _selectedRole, // Pass the selected role
        );
      }

      // Check for successful authentication
      if (user != null && mounted) {
        // Navigate to the main listing screen upon success
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PropertyListingsScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        // Display user-friendly error messages from Firebase
        errorMessage = e.message ?? "An authentication error occurred."; 
      });
    } catch (e) {
      setState(() {
        errorMessage = "An unexpected error occurred: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  // Custom Input Decoration for cleaner UI
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLogin ? 'Welcome Back!' : 'Join Property Pulse',
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 30),
              
              // Name Field (Sign Up Only)
              if (!isLogin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: TextField(
                    controller: _nameController,
                    decoration: _inputDecoration('Full Name'),
                  ),
                ),
                
              // Role Selection (Sign Up Only)
              if (!isLogin)
                Column(
                  children: [
                    const Text('Select Your Primary Role:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SegmentedButton<UserRole>(
                      segments: const <ButtonSegment<UserRole>>[
                        ButtonSegment<UserRole>(
                          value: UserRole.Buyer, 
                          label: Text('Buyer'),
                        ),
                        ButtonSegment<UserRole>(
                          value: UserRole.SellerAgent, 
                          label: Text('Seller/Agent'),
                        ),
                      ],
                      selected: <UserRole>{_selectedRole},
                      onSelectionChanged: (Set<UserRole> newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first; 
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                  ],
                ),

              // Email & Password Fields
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: TextField(
                  controller: _emailController,
                  decoration: _inputDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              TextField(
                controller: _passwordController,
                decoration: _inputDecoration('Password'),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isLogin ? 'Login' : 'Sign Up', style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 10),
              
              // Toggle Button
              TextButton(
                onPressed: toggleForm,
                child: Text(isLogin
                    ? "Don't have an account? Sign Up"
                    : "Already have an account? Login"),
              ),
              
              // Error Message
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}