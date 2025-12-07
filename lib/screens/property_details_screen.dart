// lib/screens/property_details_screen.dart

import 'package:flutter/material.dart';
import '../models/property_model.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(property.title),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      extendBodyBehindAppBar: true, 
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Property Image (Header) ---
            SizedBox(
              height: 300,
              width: double.infinity,
              child: property.imageUrl != null && property.imageUrl!.isNotEmpty
                  ? Image.network(
                      property.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey));
                      },
                    )
                  : const Center(
                      child: Icon(Icons.house, size: 100, color: Colors.blueGrey),
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. Price and Title ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${property.price}',
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- 3. Location and Type ---
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        property.address,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Chip(
                    label: Text(property.type),
                    backgroundColor: Colors.blue.shade100,
                  ),

                  const SizedBox(height: 25),
                  
                  // --- 4. Description ---
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  Text(
                    property.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 30),
                  
                  // --- 5. Seller/Contact Info Placeholder (MODIFIED HERE) ---
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    
                    // --- REMOVED: (Display Name Here) placeholder from title ---
                    title: const Text('Seller ID: (Name Loading...)'), 
                    // --- REMOVED: Comma and kept only Listing ID in subtitle ---
                    subtitle: Text('Listing ID: ${property.id}'), 

                    trailing: IconButton(
                      icon: const Icon(Icons.chat),
                      onPressed: () {
                        // TODO: Implement chat/contact functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat feature coming soon!')),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // --- Action Button (Buy/Message) ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement Purchase Logic (transaction creation, token transfer)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Initiating purchase for ${property.title}')),
                        );
                      },
                      icon: const Icon(Icons.attach_money),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('Buy for \$${property.price}', style: const TextStyle(fontSize: 18)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}