// lib/screens/property_listings_screen.dart

import 'package:flutter/material.dart';

// Import the required screens
import 'profile_screen.dart'; 
import 'add_property_screen.dart'; // Import the new screen

class PropertyListingsScreen extends StatelessWidget {
  const PropertyListingsScreen({super.key});

  // Helper function for navigation
  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Pulse'),
        actions: [
          // 1. Add Property Button (Moved from FAB to AppBar) <-- NEW
          IconButton(
            icon: const Icon(Icons.add_home_work),
            tooltip: 'Add New Property',
            onPressed: () => _navigateToScreen(
              context, 
              const AddPropertyScreen(), 
            ),
          ),
          
          // 2. Profile Button (Existing)
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _navigateToScreen(
              context, 
              const ProfileScreen(), // Navigates to the Profile Screen
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Property Listings will appear here.',
          style: TextStyle(fontSize: 20, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
      
      // REMOVED: The floatingActionButton property is now removed
      // floatingActionButton: ... (Removed)
    );
  }
}