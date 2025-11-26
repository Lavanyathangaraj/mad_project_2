// lib/screens/login_signup_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart'; 
import 'property_listings_screen.dart'; 

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
  UserRole _selectedRole = UserRole.Buyer; 

  void toggleForm() {
    setState(() {
      isLogin = !isLogin;
      errorMessage = '';
      _nameController.clear(); 
      _passwordController.clear(); // Clear password when toggling
    });
  }

  Future<void> submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

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
        // --- LOGIN: Navigate on success ---
        user = await _authService.signIn(email: email, password: password);
        
        if (user != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PropertyListingsScreen()),
          );
        }
      } else {
        // --- SIGN UP: Show message and switch to Login view ---
        user = await _authService.signUp(
          name: name,
          email: email,
          password: password,
          role: _selectedRole, 
        );
        
        if (user != null && mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign Up Successful! Please log in now.')),
          );
          // Switch form back to Login view
          setState(() {
            isLogin = true;
            _nameController.clear();
            _passwordController.clear(); // Clear password after successful signup
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
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
              
              if (!isLogin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: TextField(
                    controller: _nameController,
                    decoration: _inputDecoration('Full Name'),
                  ),
                ),
                
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
              
              TextButton(
                onPressed: toggleForm,
                child: Text(isLogin
                    ? "Don't have an account? Sign Up"
                    : "Already have an account? Login"),
              ),
              
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