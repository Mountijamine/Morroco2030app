import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/location/location_model.dart';
import 'package:flutter_application_1/location/location_service.dart';
import 'dart:typed_data';
import 'package:flutter_application_1/utils/image_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/location/location_detail_screen.dart';

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
  bool _isProcessingImages = false;
  final ScrollController _imageScrollController = ScrollController();

  final List<String> _locationTypes = [
    'hotel',
    'apartment',
    'hostel',
    'villa',
    'riad',
  ];

  Future<void> _pickImage() async {
    try {
      // Show options in bottom sheet
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: const Color(0xFF065d67),
                  ),
                  title: const Text('Select from gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    _pickMultipleFromGallery();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: const Color(0xFF065d67),
                  ),
                  title: const Text('Take a photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                if (_selectedImages.isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: const Text('Clear all images'),
                    onTap: () {
                      Navigator.pop(context);
                      _showClearImagesDialog();
                    },
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Error with image picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing image picker: $e')),
      );
    }
  }

  Future<void> _pickMultipleFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _isProcessingImages = true;
          _isLoading = true;
        });

        // Show progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Processing ${images.length} images...'),
                ],
              ),
            );
          },
        );

        // Process images in batches to avoid UI freezing
        List<String> newImages = [];
        for (var image in images) {
          // Read image file
          File imageFile = File(image.path);

          // Compress the image to reduce size
          List<int> imageBytes = await imageFile.readAsBytes();

          // Convert to base64
          String base64Image = base64Encode(imageBytes);
          newImages.add(base64Image);
        }

        // Close progress dialog
        Navigator.of(context).pop();

        setState(() {
          _selectedImages.addAll(newImages);
          _isProcessingImages = false;
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${images.length} images added')),
        );

        // Scroll to end of image list to show the new images
        if (_selectedImages.length > 2) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _imageScrollController.animateTo(
              _imageScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
      }
    } catch (e) {
      // Close progress dialog if open
      if (_isProcessingImages) {
        Navigator.of(context).pop();
      }

      print('Error picking images: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting images: $e')));

      setState(() {
        _isProcessingImages = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() => _isLoading = true);

        // Read image file
        File imageFile = File(photo.path);

        // Convert to base64
        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        setState(() {
          _selectedImages.add(base64Image);
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Photo added')));
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
      setState(() => _isLoading = false);
    }
  }

  void _showClearImagesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear all images?'),
          content: const Text(
            'This will remove all selected images. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImages.clear();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All images cleared')),
                );
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Image removed')));
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
                    controller: _imageScrollController,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ImageUtils.buildBase64Image(
                              _selectedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  color: Colors.black54,
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  // Add this helper method for displaying base64 images
  Widget _buildImageDisplay(String imageString) {
    return ImageUtils.buildBase64Image(imageString);
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.home, size: 40, color: Colors.grey[400]),
    );
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
