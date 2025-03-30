import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddCityScreen extends StatefulWidget {
  const AddCityScreen({Key? key}) : super(key: key);

  @override
  State<AddCityScreen> createState() => _AddCityScreenState();
}

class _AddCityScreenState extends State<AddCityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  
  String _selectedType = 'Imperial'; // Default type
  bool _isLoading = false;
  
  // For image handling
  File? _selectedImage;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  // List of city types
  final List<String> _cityTypes = [
    'Imperial',
    'Coastal',
    'Modern',
    'Mountain',
    'Desert',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Reduce image size for Firestore limits
      maxHeight: 600,
      imageQuality: 70, // Reduce quality to keep Base64 string smaller
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      
      // Convert to Base64
      final bytes = await _selectedImage!.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _addCity() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You need to be logged in');
      }
      
      // Create the new city data
      final cityData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': '', // Keep this for compatibility with existing code
        'imageBase64': _base64Image, // Store image as Base64
        'location': GeoPoint(
          double.parse(_latitudeController.text), 
          double.parse(_longitudeController.text)
        ),
        'type': _selectedType,
        'favoritedBy': [],
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('cities')
          .add(cityData);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('City added successfully!'))
        );
        // Clear the form
        _formKey.currentState!.reset();
        _nameController.clear();
        _descriptionController.clear();
        _latitudeController.clear();
        _longitudeController.clear();
        setState(() {
          _selectedType = 'Imperial';
          _selectedImage = null;
          _base64Image = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding city: $e'))
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New City'),
        backgroundColor: const Color(0xFFFDCB00),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'City Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the city name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // City Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'City Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _cityTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a city type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Image Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('City Image', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to add image', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                          hintText: '34.0209'
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                          hintText: '-6.8416'
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _addCity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF065d67),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ADD CITY'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}