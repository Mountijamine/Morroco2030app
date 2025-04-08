import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_application_1/location/location_model.dart';
import 'dart:convert';
import 'dart:typed_data'; // Add this import for Uint8List
import 'package:image_picker/image_picker.dart'; // Add this import for ImagePicker

class LocationDetailScreen extends StatefulWidget {
  final Location location;

  const LocationDetailScreen({Key? key, required this.location})
    : super(key: key);

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  int _currentImageIndex = 0;
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);

  bool isBase64Image(String str) {
    try {
      if (str.startsWith('data:image')) {
        return true;
      }
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          widget.location.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            onPressed: () {
              // Action pour les points de fidélité
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  child: FlutterCarousel(
                    items:
                        widget.location.imageUrls.map((imageString) {
                          return Builder(
                            builder: (context) {
                              try {
                                // Remove any data URL prefix if present
                                String cleanBase64 = imageString;
                                if (imageString.contains(',')) {
                                  cleanBase64 = imageString.split(',').last;
                                }

                                // Remove any whitespace
                                cleanBase64 = cleanBase64.trim();

                                final Uint8List bytes = base64Decode(
                                  cleanBase64,
                                );

                                return Image.memory(
                                  bytes,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Carousel image error: $error');
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                );
                              } catch (e) {
                                print('Carousel base64 error: $e');
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error),
                                );
                              }
                            },
                          );
                        }).toList(),
                    options: CarouselOptions(
                      height: 300,
                      aspectRatio: 16 / 9,
                      viewportFraction: 1.0,
                      initialPage: 0,
                      enableInfiniteScroll: true,
                      reverse: false,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 3),
                      autoPlayAnimationDuration: const Duration(
                        milliseconds: 800,
                      ),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enlargeCenterPage: false,
                      onPageChanged: (index, reason) {
                        setState(() => _currentImageIndex = index);
                      },
                      scrollDirection: Axis.horizontal,
                    ),
                  ),
                ),
                // Left arrow for previous image
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentImageIndex =
                            _currentImageIndex > 0
                                ? _currentImageIndex - 1
                                : widget.location.imageUrls.length - 1;
                      });
                      // Access the carousel controller and animate to the new page
                      // This would require adding a carousel controller
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Right arrow for next image
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentImageIndex =
                            (_currentImageIndex + 1) %
                            widget.location.imageUrls.length;
                      });
                      // Access the carousel controller and animate to the new page
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Image counter indicator
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${widget.location.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Add this widget below the carousel:
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.location.imageUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentImageIndex = index;
                      });
                      // You would need a carousel controller to jump to this page
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _currentImageIndex == index
                                  ? primaryColor
                                  : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _buildThumbnailImage(
                          widget.location.imageUrls[index],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.location.imageUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _currentImageIndex == index
                                    ? primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildThumbnailImage(widget.location.imageUrls[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location name and type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.location.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.location.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 20, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.location.rating}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Price and availability
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price per night',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.location.pricePerNight.toStringAsFixed(0)} DH',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                widget.location.isAvailable
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.location.isAvailable
                                ? 'Available'
                                : 'Not Available',
                            style: TextStyle(
                              color:
                                  widget.location.isAvailable
                                      ? Colors.green[700]
                                      : Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.location.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Amenities
                  const Text(
                    'Amenities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        widget.location.amenities.map((amenity) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              amenity,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Contact information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildContactRow(
                          Icons.phone,
                          widget.location.phoneNumber,
                          _callLocation,
                        ),
                        const SizedBox(height: 12),
                        _buildContactRow(
                          Icons.location_on,
                          widget.location.address,
                          _openInMaps,
                        ),
                        if (widget.location.website.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildContactRow(
                            Icons.language,
                            widget.location.website,
                            _openWebsite,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Section Adresse
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adresse',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.location.address,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Section Contact
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personne à contacter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.location.phoneNumber,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: secondaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Future<void> _openInMaps() async {
    final latitude = widget.location.location.latitude;
    final longitude = widget.location.location.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }

  Future<void> _callLocation() async {
    final url = Uri.parse('tel:${widget.location.phoneNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not make call')));
      }
    }
  }

  Future<void> _openWebsite() async {
    if (widget.location.website.isEmpty) return;

    final url = Uri.parse(widget.location.website);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open website')));
      }
    }
  }

  Widget _buildThumbnailImage(String imageString) {
    try {
      String cleanBase64 = imageString;
      if (imageString.contains(',')) {
        cleanBase64 = imageString.split(',').last;
      }
      cleanBase64 = cleanBase64.trim();

      final Uint8List bytes = base64Decode(cleanBase64);

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 20),
          );
        },
      );
    } catch (e) {
      print('Error displaying thumbnail: $e');
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 20),
      );
    }
  }

  // Add this function to the _LocationDetailScreenState class

  Future<void> _editLocationImages(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    // Show options dialog
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.add_photo_alternate, color: primaryColor),
                title: const Text('Add more images'),
                onTap: () async {
                  Navigator.pop(context);

                  try {
                    final List<XFile> images = await picker.pickMultiImage();
                    if (images.isNotEmpty) {
                      List<String> newImages = [];

                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Processing images...'),
                              ],
                            ),
                          );
                        },
                      );

                      // Process images
                      for (var image in images) {
                        final bytes = await image.readAsBytes();
                        final base64Image = base64Encode(bytes);
                        newImages.add(base64Image);
                      }

                      // Close loading dialog
                      if (mounted) Navigator.of(context).pop();

                      // Update location with new images
                      final updatedImageList = [
                        ...widget.location.imageUrls,
                        ...newImages,
                      ];
                      await FirebaseFirestore.instance
                          .collection('locations')
                          .doc(widget.location.id)
                          .update({'imageUrls': updatedImageList});

                      // Refresh page (you may need to implement a proper refresh mechanism)
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Images added successfully'),
                          ),
                        );
                        // Refresh the screen or navigate back and forth
                        final refreshedLocation =
                            await FirebaseFirestore.instance
                                .collection('locations')
                                .doc(widget.location.id)
                                .get();

                        if (mounted && refreshedLocation.exists) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => LocationDetailScreen(
                                    location: Location.fromMap(
                                      refreshedLocation.data()!,
                                      refreshedLocation.id,
                                    ),
                                  ),
                            ),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    print('Error adding images: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding images: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove images'),
                onTap: () {
                  Navigator.pop(context);
                  _showImageRemovalDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImageRemovalDialog(BuildContext context) {
    // Track which images are selected for removal
    List<int> selectedIndices = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select images to remove'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300, // Add a fixed height to avoid overflow
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                  ),
                  itemCount: widget.location.imageUrls.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedIndices.contains(index);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildThumbnailImage(widget.location.imageUrls[index]),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.remove_circle,
                              color: isSelected ? Colors.green : Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                if (isSelected) {
                                  selectedIndices.remove(index);
                                } else {
                                  selectedIndices.add(index);
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed:
                      selectedIndices.isEmpty
                          ? null
                          : () async {
                            try {
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (context) => const AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 16),
                                          Text('Removing images...'),
                                        ],
                                      ),
                                    ),
                              );

                              // Create new list without the selected images
                              List<String> updatedImages = [];
                              for (
                                int i = 0;
                                i < widget.location.imageUrls.length;
                                i++
                              ) {
                                if (!selectedIndices.contains(i)) {
                                  updatedImages.add(
                                    widget.location.imageUrls[i],
                                  );
                                }
                              }

                              // Update in Firestore
                              await FirebaseFirestore.instance
                                  .collection('locations')
                                  .doc(widget.location.id)
                                  .update({'imageUrls': updatedImages});

                              // Close loading dialog and image removal dialog
                              if (mounted) Navigator.of(context).pop();
                              if (mounted) Navigator.of(context).pop();

                              // Show success message
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Images removed successfully',
                                    ),
                                  ),
                                );

                                // Refresh the screen with updated location data
                                final refreshedLocation =
                                    await FirebaseFirestore.instance
                                        .collection('locations')
                                        .doc(widget.location.id)
                                        .get();

                                if (mounted && refreshedLocation.exists) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => LocationDetailScreen(
                                            location: Location.fromMap(
                                              refreshedLocation.data()!,
                                              refreshedLocation.id,
                                            ),
                                          ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              // Close loading dialog if an error occurs
                              if (mounted) Navigator.of(context).pop();

                              print('Error removing images: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error removing images: $e'),
                                  ),
                                );
                              }
                            }
                          },
                  child: const Text(
                    'Remove Selected',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}