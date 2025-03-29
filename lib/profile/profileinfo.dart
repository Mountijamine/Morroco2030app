import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';

class ProfileInfoPage extends StatefulWidget {
  static route() => MaterialPageRoute(
      builder: (context) => const ProfileInfoPage());
  
  const ProfileInfoPage({Key? key}) : super(key: key);

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _countryController = TextEditingController();
  
  DateTime? _selectedDate;
  String _phoneNumber = '';
  String _phoneCountryCode = '+1';
  
  File? _profileImage;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  LatLng? _selectedLocation;
  String _locationAddress = '';
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300, // Restrict image size
        maxHeight: 300,
        imageQuality: 70, // Compress the image
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        
        // Convert to base64
        final bytes = await _profileImage!.readAsBytes();
        
        // Check if image size is too large (800KB limit to stay under Firestore's 1MB document limit)
        if (bytes.length > 800 * 1024) {
          setState(() {
            _errorMessage = "Image too large. Please select a smaller image.";
            _profileImage = null;
          });
          return;
        }
        
        setState(() {
          _base64Image = base64Encode(bytes);
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage = "Failed to pick image: ${e.message}";
      });
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred while selecting image";
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final location = loc.Location();
      
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }
      
      loc.PermissionStatus permissionStatus = await location.hasPermission();
      if (permissionStatus == loc.PermissionStatus.denied) {
        permissionStatus = await location.requestPermission();
        if (permissionStatus != loc.PermissionStatus.granted) {
          return;
        }
      }
      
      final locationData = await location.getLocation();
      final latLng = LatLng(locationData.latitude!, locationData.longitude!);
      
      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _selectedLocation = latLng;
          _locationAddress = '${place.street}, ${place.locality}, ${place.country}';
          _countryController.text = place.country ?? '';
        });
      }
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get location. Please try again."))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _showLocationPicker() async {
    // For simplicity, we're just using current location
    await _getCurrentLocation();
  }
Future<void> _submitProfile() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }
  
  // Check if phone number is provided
  if (_phoneNumber.isEmpty) {
    setState(() {
      _errorMessage = "Please enter your phone number";
    });
    return;
  }
  
  // Check if date of birth is selected
  if (_selectedDate == null) {
    setState(() {
      _errorMessage = "Please select your date of birth";
    });
    return;
  }
  
  // Check if user is 18 or older
  final DateTime today = DateTime.now();
  final DateTime minimumDate = DateTime(
    today.year - 18,
    today.month,
    today.day,
  );
  
  if (_selectedDate!.isAfter(minimumDate)) {
    setState(() {
      _errorMessage = "You must be at least 18 years old to register";
    });
    return;
  }
  
  // Check if location is selected
  if (_selectedLocation == null) {
    setState(() {
      _errorMessage = "Please select your location";
    });
    return;
  }
  
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
  
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    
    // Create profile data with optional base64 image
    final profileData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'country': _countryController.text.trim(),
      'phoneNumber': _phoneNumber,
      'phoneCountryCode': _phoneCountryCode,
      'dateOfBirth': Timestamp.fromDate(_selectedDate!),
      'location': GeoPoint(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      ),
      'locationAddress': _locationAddress,
      'profileImageBase64': _base64Image, // Store image as base64 string
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'hasCompletedProfile': true,
    };
    
    // Save to Firestore database
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(profileData);
    
    // Navigate to home page
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyHomePage()),
        (route) => false,
      );
    }
  } catch (e) {
    setState(() {
      _errorMessage = "Failed to save profile: ${e.toString()}";
    });
    print("Error saving profile: $e");
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
        title: const Text('Complete Your Profile'),
        backgroundColor: const Color(0xFF065d67),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!) as ImageProvider
                          : const AssetImage('assets/images/placeholder_profile.jpg'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065d67),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              Text(
                'Please complete your profile',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Country of Residence
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country of Residence',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your country';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Phone Number with country code
             IntlPhoneField(
  decoration: const InputDecoration(
    labelText: 'Phone Number',
    border: OutlineInputBorder(),
  ),
  initialCountryCode: 'MA',
  onChanged: (phone) {
    setState(() {
      _phoneNumber = phone.number;
      _phoneCountryCode = phone.countryCode;
    });
  },
  validator: (phone) {
    if (phone == null || phone.number.isEmpty) {
      return 'Please enter your phone number';
    }
    return null;
  },
),
              
              const SizedBox(height: 16),
              
              // Date of Birth
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select your date of birth'
                        : DateFormat('MMMM d, yyyy').format(_selectedDate!),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Location picker
              InkWell(
                onTap: _showLocationPicker,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Your Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _locationAddress.isEmpty
                        ? 'Select your location'
                        : _locationAddress,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Get current location button
              TextButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Use current location'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF065d67),
                ),
              ),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Submit button
              _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF065d67),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _submitProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF065d67),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'SAVE PROFILE',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}