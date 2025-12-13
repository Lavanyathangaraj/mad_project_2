import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingReviewScreen extends StatefulWidget {
  final String propertyId; // Pass the property ID
  const RatingReviewScreen({super.key, required this.propertyId});

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  double rating = 0;
  final TextEditingController reviewController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a star rating")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('listings') // Changed to your current collection name
          .doc(widget.propertyId)
          .collection('reviews')
          .add({
        'userId': user.uid,
        'userEmail': user.email ?? 'Anonymous',
        'rating': rating,
        'review': reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rate & Review")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("How was your experience?", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            const SizedBox(height: 30),
            // Star Rating Row...
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 40),
                  onPressed: () => setState(() => rating = index + 1.0),
                );
              }),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: reviewController,
              decoration: const InputDecoration(labelText: "Write a review (Optional)", border: OutlineInputBorder()),
              maxLines: 4,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: _isSubmitting 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("Submit Review", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}