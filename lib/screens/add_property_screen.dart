// lib/screens/add_property_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; 
import '../models/property_model.dart';

// --- Cloudinary Config ---
const String CLOUDINARY_CLOUD_NAME = 'dvdfvxphf';
const String CLOUDINARY_UPLOAD_PRESET = 'flutter_upload';
final String CLOUDINARY_URL =
    'https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController(); 
  final _descriptionController = TextEditingController();
  
  String? _selectedType = 'Apartment'; 

  File? _imageFile;
  Uint8List? _webImage;
  bool _isLoading = false;

  final List<String> _propertyTypes = [
    'Apartment', 
    'House', 
    'Condo', 
    'Land', 
    'Commercial'
  ];

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _webImage = bytes);
    } else {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    if (_imageFile == null && _webImage == null) return null;
    
    try {
      final request = http.MultipartRequest('POST', Uri.parse(CLOUDINARY_URL));
      request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;

      if (kIsWeb && _webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _webImage!,
            filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      } else if (!kIsWeb && _imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));
      } else {
        return null;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['secure_url'];
      } else {
        print('Cloudinary Error: ${response.statusCode} - ${response.body}'); 
        return null;
      }
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }

  void _submitProperty() async {
    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a property image.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _uploadImageToCloudinary();
      if (imageUrl == null) {
        throw Exception('Failed to upload image to Cloudinary.');
      }

      final newProperty = PropertyModel(
        id: '', 
        title: _titleController.text.trim(),
        address: _addressController.text.trim(),
        type: _selectedType!,
        price: int.tryParse(_priceController.text.trim()) ?? 0, 
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl, 
        sellerId: FirebaseAuth.instance.currentUser?.uid ?? '',
        timestamp: Timestamp.now(), 
      );

      await FirebaseFirestore.instance.collection('listings').add(newProperty.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newProperty.title} listed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save property: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)), 
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      labelStyle: TextStyle(color: Colors.black54),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Property Listing"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: inputDecoration.copyWith(labelText: 'Listing Title', prefixIcon: const Icon(Icons.title)),
                validator: (value) => value!.isEmpty ? 'Please enter a title for your listing' : null,
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                decoration: inputDecoration.copyWith(labelText: 'Property Type', prefixIcon: const Icon(Icons.category)),
                value: _selectedType,
                items: _propertyTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a property type' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _addressController,
                decoration: inputDecoration.copyWith(labelText: 'Full Address', prefixIcon: const Icon(Icons.location_on_outlined)),
                validator: (value) => value!.isEmpty ? 'Please enter the property address' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _priceController,
                decoration: inputDecoration.copyWith(labelText: 'Price', prefixIcon: const Icon(Icons.monetization_on), hintText: 'e.g., 5000'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter a price';
                  if (int.tryParse(value) == null || int.parse(value)! <= 0) return 'Price must be a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _descriptionController,
                decoration: inputDecoration.copyWith(labelText: 'Description', prefixIcon: const Icon(Icons.description)),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              
              const SizedBox(height: 30),
              const Divider(color: Colors.black12),
              const SizedBox(height: 20),

              Text('Property Image', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              const SizedBox(height: 15),
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: _imageFile == null && _webImage == null
                          ? const Center(child: Text('No image selected.', style: TextStyle(color: Colors.grey)))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.memory(_webImage!, fit: BoxFit.cover)
                                  : Image.file(_imageFile!, fit: BoxFit.cover),
                            ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Upload Image'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submitProperty,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.green.shade600, 
                  foregroundColor: Colors.white, 
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Listing',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}