import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/location/location_model.dart';
import 'package:flutter_application_1/location/location_service.dart';

class AddLocationScreen extends StatefulWidget {
  final City city;

  const AddLocationScreen({Key? key, required this.city}) : super(key: key);

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocationService _locationService = LocationService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _imageUrlsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _roomsController = TextEditingController();
  final TextEditingController _amenitiesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<String> _selectedImages = [];

  String _selectedType = 'hotel';
  bool _isLoading = false;

  final List<String> _locationTypes = ['hotel', 'apartment', 'hostel'];

  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() => _isLoading = true);
        
        List<String> base64Images = [];
        for (var image in images) {
          File imageFile = File(image.path);
          List<int> imageBytes = await imageFile.readAsBytes();
          String base64Image = base64Encode(imageBytes);
          
          // Store the clean base64 string (no prefix, no whitespace)
          base64Images.add(base64Image.trim());
        }
        
        setState(() {
          _selectedImages = base64Images;
          _isLoading = false;
        });
        
        // Debug first image if available
        if (base64Images.isNotEmpty) {
          print('First image encoded successfully. Length: ${base64Images.first.length}');
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Location'),
        backgroundColor: const Color(0xFFFDCB00),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items:
                    _locationTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Description is required'
                            : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Latitude is required'
                                  : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Longitude is required'
                                  : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Phone number is required'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per Night',
                  helperText: 'Enter a positive number',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Price is required';
                  }
                  try {
                    double price = double.parse(value);
                    if (price <= 0) {
                      return 'Price must be greater than 0';
                    }
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomsController,
                decoration: const InputDecoration(labelText: 'Number of Rooms'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Number of rooms is required'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amenitiesController,
                decoration: const InputDecoration(
                  labelText: 'Amenities',
                  helperText:
                      'Separate with commas (e.g., WiFi, Pool, Parking)',
                ),
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'At least one amenity is required'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(
                  labelText: 'Rating',
                  helperText: 'Enter a number between 0 and 5',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Rating is required';
                  }
                  try {
                    double rating = double.parse(value);
                    if (rating < 0 || rating > 5) {
                      return 'Rating must be between 0 and 5';
                    }
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Images'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF065d67),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Image.memory(
                          base64Decode(_selectedImages[index]),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDCB00),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Add Location'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);

        // Validate and parse numeric values
        double rating = 0.0;
        try {
          rating = double.parse(_ratingController.text.trim());
          if (rating < 0 || rating > 5) {
            throw FormatException('Rating must be between 0 and 5');
          }
        } catch (e) {
          throw Exception(
            'Invalid rating value. Please enter a number between 0 and 5',
          );
        }

        double price = 0.0;
        try {
          price = double.parse(_priceController.text.trim());
          if (price <= 0) {
            throw FormatException('Price must be greater than 0');
          }
        } catch (e) {
          throw Exception('Invalid price value. Please enter a valid number');
        }

        double latitude = 0.0;
        double longitude = 0.0;
        try {
          latitude = double.parse(_latitudeController.text.trim());
          longitude = double.parse(_longitudeController.text.trim());
          if (latitude < -90 ||
              latitude > 90 ||
              longitude < -180 ||
              longitude > 180) {
            throw FormatException('Invalid coordinates');
          }
        } catch (e) {
          throw Exception(
            'Invalid coordinates. Please enter valid latitude and longitude',
          );
        }

        int rooms = 0;
        try {
          rooms = int.parse(_roomsController.text.trim());
          if (rooms <= 0) {
            throw FormatException('Number of rooms must be greater than 0');
          }
        } catch (e) {
          throw Exception(
            'Invalid number of rooms. Please enter a valid number',
          );
        }

        List<String> amenities =
            _amenitiesController.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList();

        final location = Location(
          id: '',
          name: _nameController.text.trim(),
          cityId: widget.city.id,
          address: _addressController.text.trim(),
          rating: rating,
          location: GeoPoint(latitude, longitude),
          imageUrls: _selectedImages,
          description: _descriptionController.text.trim(),
          type: _selectedType,
          phoneNumber: _phoneController.text.trim(),
          website: _websiteController.text.trim(),
          pricePerNight: price,
          amenities: amenities,
          numberOfRooms: rooms,
        );

        await _locationService.addLocation(location);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location added successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _ratingController.dispose();
    _imageUrlsController.dispose();
    _priceController.dispose();
    _roomsController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }
}
