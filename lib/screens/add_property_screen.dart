// lib/screens/add_property_screen.dart

import 'package:flutter/material.dart';

class AddPropertyScreen extends StatelessWidget {
  const AddPropertyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Property Listing"),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.house, size: 80, color: Colors.blueGrey),
              SizedBox(height: 20),
              Text(
                'Property submission form will go here.',
                style: TextStyle(fontSize: 20, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              // TODO: Implement the form fields for property details (title, address, price, etc.)
            ],
          ),
        ),
      ),
    );
  }
}