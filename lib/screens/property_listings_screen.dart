// lib/screens/property_listings_screen.dart

import 'package:flutter/material.dart';

// Import only the required screen
import 'profile_screen.dart'; // Profile Screen

// Removed imports for: add_item_screen.dart, notifications_screen.dart, filter_search_screen.dart

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
          // 1. Profile Button <--- ONLY KEEP THIS ONE
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
      
      // Removed Floating Action Button (FAB) for Add Property/Item
      // It can be added back when 'add_item_screen.dart' is ready.
    );
  }
}