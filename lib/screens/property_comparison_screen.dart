// lib/screens/property_comparison_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';

class PropertyComparisonScreen extends StatefulWidget {
  const PropertyComparisonScreen({super.key});

  @override
  State<PropertyComparisonScreen> createState() => _PropertyComparisonScreenState();
}

class _PropertyComparisonScreenState extends State<PropertyComparisonScreen> {
  final _firestore = FirebaseFirestore.instance;
  final List<TextEditingController> _idControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  List<PropertyModel?> _properties = [null, null, null];
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _idControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchProperties() async {
    setState(() {
      _isLoading = true;
      _properties = [null, null, null];
    });

    List<String> idsToFetch = _idControllers
        .map((c) => c.text.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (idsToFetch.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one property ID.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    List<Future<PropertyModel?>> fetchFutures = idsToFetch.map((id) async {
      try {
        final doc = await _firestore.collection('listings').doc(id).get();
        if (doc.exists) {
          return PropertyModel.fromDocument(doc);
        }
      } catch (e) {
        print('Error fetching property $id: $e');
      }
      return null;
    }).toList();

    List<PropertyModel?> fetched = await Future.wait(fetchFutures);
    
    List<PropertyModel?> updatedProperties = [null, null, null];
    for (int i = 0; i < fetched.length && i < 3; i++) {
      updatedProperties[i] = fetched[i];
    }
    
    if (mounted) {
      setState(() {
        _properties = updatedProperties;
        _isLoading = false;
      });
    }
  }

  Widget _buildPropertyInput(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _idControllers[index],
        decoration: InputDecoration(
          labelText: 'Property ${index + 1} ID',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildComparisonCell(String header, String? value, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
        color: color,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header.isNotEmpty)
            Text(
              header,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color == Colors.white ? Colors.black : Colors.black),
            ),
          if (header.isNotEmpty) const SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            style: TextStyle(
              fontSize: 14,
              fontStyle: value == 'N/A' ? FontStyle.italic : FontStyle.normal,
              color: color == Colors.white ? Colors.black : Colors.black,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String label, List<String?> values, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: color,
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...values.map((value) => _buildComparisonCell('', value, Colors.white)).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<PropertyModel?> validProperties = _properties.where((p) => p != null).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Comparison'),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter up to 3 Listing IDs to compare:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ...List.generate(3, (index) => _buildPropertyInput(index)),

            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchProperties,
                icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.compare),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(_isLoading ? 'Loading...' : 'Compare Properties', style: const TextStyle(fontSize: 18)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  'Tip: Listing IDs can be found in the "Contact Information" section of the Property Details Page.',
                  style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (validProperties.isNotEmpty)
              Text(
                'Comparison Results:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            if (validProperties.isNotEmpty)
              const Divider(),
              
            if (validProperties.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(width: 120, padding: const EdgeInsets.all(8), color: Colors.grey.shade100, child: const Text('Feature', style: TextStyle(fontWeight: FontWeight.bold))),
                        ...validProperties.map((p) => _buildComparisonCell(
                          '', 
                          p!.title, 
                          Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        )).toList(),
                        ...List.generate(3 - validProperties.length, (index) => Container(width: 150, padding: const EdgeInsets.all(8), color: Colors.grey.shade100, child: const Text(''))),
                      ],
                    ),
                    const Divider(height: 0),
                    
                    _buildPropertyRow('Price', validProperties.map((p) => '\$${p!.price}').toList(), Colors.white),
                    _buildPropertyRow('Type', validProperties.map((p) => p!.type).toList(), Colors.grey.shade50),
                    _buildPropertyRow('Address', validProperties.map((p) => p!.address).toList(), Colors.white),
                    _buildPropertyRow('Description', validProperties.map((p) => p!.description).toList(), Colors.grey.shade50),
                    _buildPropertyRow('Seller ID', validProperties.map((p) => p!.sellerId).toList(), Colors.white),
                    _buildPropertyRow('Listing Date', validProperties.map((p) => p!.timestamp.toDate().toString().split(' ')[0]).toList(), Colors.grey.shade50),
                  ],
                ),
              ),

            if (validProperties.isEmpty && !_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 50.0),
                  child: Text('No properties loaded for comparison. Enter IDs above and click Compare.'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}