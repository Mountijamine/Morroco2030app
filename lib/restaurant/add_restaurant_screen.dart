import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/restaurant/restaurant_model.dart';
import 'package:flutter_application_1/restaurant/restaurant_service.dart';

class AddRestaurantScreen extends StatefulWidget {
  final City city;

  const AddRestaurantScreen({Key? key, required this.city}) : super(key: key);

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final RestaurantService _restaurantService = RestaurantService();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _cuisineController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _menuItemsController = TextEditingController();
  final TextEditingController _imageUrlsController = TextEditingController();

  bool _isLoading = false;

  // Main app color - matching your existing theme
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _cuisineController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _ratingController.dispose();
    _menuItemsController.dispose();
    _imageUrlsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Parse menu items (comma-separated)
        List<String> menuItems =
            _menuItemsController.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList();

        // Parse image URLs (comma-separated)
        List<String> imageUrls =
            _imageUrlsController.text
                .split(',')
                .map((url) => url.trim())
                .where((url) => url.isNotEmpty)
                .toList();

        // Create restaurant object
        final restaurant = Restaurant(
          id: '', // ID will be assigned by Firestore
          name: _nameController.text.trim(),
          cityId: widget.city.id,
          address: _addressController.text.trim(),
          rating: double.parse(_ratingController.text),
          location: GeoPoint(
            double.parse(_latitudeController.text),
            double.parse(_longitudeController.text),
          ),
          menuItems: menuItems,
          imageUrls: imageUrls,
          description: _descriptionController.text.trim(),
          cuisine: _cuisineController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          website: _websiteController.text.trim(),
        );

        // Save to Firestore using service
        await _restaurantService.addRestaurant(restaurant);

        // Show success message and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restaurant added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to refresh parent screen
        }
      } catch (e) {
        print('Error adding restaurant: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add restaurant: $e'),
              backgroundColor: Colors.red,
            ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Restaurant in ${widget.city.name}'),
        backgroundColor: primaryColor,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading
                      Text(
                        'Restaurant Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Required fields section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Basic Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Name field
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Restaurant Name *',
                                hintText: 'Enter restaurant name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.restaurant,
                                  color: primaryColor,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Restaurant name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Address field
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Address *',
                                hintText: 'Enter restaurant address',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.location_on,
                                  color: primaryColor,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Address is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Cuisine field
                            TextFormField(
                              controller: _cuisineController,
                              decoration: InputDecoration(
                                labelText: 'Cuisine Type *',
                                hintText: 'e.g., Moroccan, Italian, etc.',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.restaurant_menu,
                                  color: primaryColor,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Cuisine type is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Location section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Latitude field
                            TextFormField(
                              controller: _latitudeController,
                              decoration: InputDecoration(
                                labelText: 'Latitude *',
                                hintText: 'e.g., 33.589886',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Latitude is required';
                                }
                                try {
                                  double.parse(value);
                                } catch (e) {
                                  return 'Enter valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Longitude field
                            TextFormField(
                              controller: _longitudeController,
                              decoration: InputDecoration(
                                labelText: 'Longitude *',
                                hintText: 'e.g., -7.603869',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Longitude is required';
                                }
                                try {
                                  double.parse(value);
                                } catch (e) {
                                  return 'Enter valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tip: You can find coordinates by right-clicking a location in Google Maps',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Details section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Additional Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Description field
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description *',
                                hintText: 'Describe the restaurant',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Description is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Rating field
                            TextFormField(
                              controller: _ratingController,
                              decoration: InputDecoration(
                                labelText: 'Rating (0-5) *',
                                hintText: 'e.g., 4.5',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.star,
                                  color: primaryColor,
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
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
                                  return 'Enter valid rating';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Menu section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menu Items',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter menu item names separated by commas (you can add detailed menu items with prices later)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Menu items field
                            TextFormField(
                              controller: _menuItemsController,
                              decoration: InputDecoration(
                                labelText: 'Menu Items *',
                                hintText: 'Couscous, Tagine, Mint Tea',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.menu_book,
                                  color: primaryColor,
                                ),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter at least one menu item';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Note: After adding the restaurant, you can add detailed menu items with prices from the restaurant details page',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Image URLs section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Image URLs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter direct image URLs or base64 encoded images separated by commas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Image URLs field
                            TextFormField(
                              controller: _imageUrlsController,
                              decoration: InputDecoration(
                                labelText: 'Image URLs or Base64 *',
                                hintText:
                                    'https://example.com/image1.jpg, data:image/jpeg;base64,...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.image,
                                  color: primaryColor,
                                ),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter at least one image URL or base64 string';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Note: For base64 images, include the data:image prefix',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Contact section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Information (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Phone field
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                hintText: 'e.g., +212-522-123456',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.phone,
                                  color: primaryColor,
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),

                            // Website field
                            TextFormField(
                              controller: _websiteController,
                              decoration: InputDecoration(
                                labelText: 'Website',
                                hintText: 'e.g., https://www.restaurant.com',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.language,
                                  color: primaryColor,
                                ),
                              ),
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ADD RESTAURANT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }
}
