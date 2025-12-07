// lib/models/property_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyModel {
  final String id;
  final String title;
  final String description;
  final String address;
  final String type;
  final int price;
  final String sellerId;
  final String? imageUrl;
  final Timestamp timestamp;

  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.type,
    required this.price,
    required this.sellerId,
    this.imageUrl,
    required this.timestamp,
  });

  // Factory constructor to create a PropertyModel from a Firestore DocumentSnapshot
  factory PropertyModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyModel(
      id: doc.id, // Use the Firestore document ID
      title: data['title'] as String,
      description: data['description'] as String,
      address: data['address'] as String,
      type: data['type'] as String,
      price: data['price'] as int,
      sellerId: data['sellerId'] as String,
      imageUrl: data['imageUrl'] as String?,
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  // Method to convert the PropertyModel to a Map for Firestore submission
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'address': address,
      'type': type,
      'price': price,
      'sellerId': sellerId,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    };
  }
}