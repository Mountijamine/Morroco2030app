import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_application_1/location/location_model.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;
  bool _showBookingButton = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Change app bar appearance based on scroll position
    if (_scrollController.offset > 250 && !_showAppBarTitle) {
      setState(() => _showAppBarTitle = true);
    } else if (_scrollController.offset <= 250 && _showAppBarTitle) {
      setState(() => _showAppBarTitle = false);
    }

    // Show/hide booking button based on scroll position
    if (_scrollController.offset > 1000 && _showBookingButton) {
      setState(() => _showBookingButton = false);
    } else if (_scrollController.offset <= 1000 && !_showBookingButton) {
      setState(() => _showBookingButton = true);
    }
  }

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
        backgroundColor: _showAppBarTitle ? Colors.white : Colors.transparent,
        elevation: _showAppBarTitle ? 1 : 0,
        title:
            _showAppBarTitle
                ? Text(
                  widget.location.name,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : const SizedBox.shrink(),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                _showAppBarTitle ? Colors.white : Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: _showAppBarTitle ? Colors.black : Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  _showAppBarTitle
                      ? Colors.white
                      : Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.share,
                color: _showAppBarTitle ? Colors.black : Colors.white,
              ),
              onPressed: () {
                // Share functionality
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  _showAppBarTitle
                      ? Colors.white
                      : Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.favorite_border,
                color: _showAppBarTitle ? Colors.black : Colors.white,
              ),
              onPressed: () {
                // Favorite functionality
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _showBookingButton
              ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                width: double.infinity,
                child: FloatingActionButton.extended(
                  backgroundColor: secondaryColor,
                  onPressed: () {
                    // Show booking dialog
                    _showBookingDialog(context);
                  },
                  label: Text(
                    'Book Now · ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(widget.location.pricePerNight)} DH/night',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  icon: const Icon(Icons.calendar_today),
                ),
              )
              : null,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery - Airbnb Style
            _buildImageGallery(),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Host Section
                  _buildTitleSection(),

                  const Divider(height: 40),

                  // Property Types Section (NEW)
                  _buildPropertyTypesSection(),

                  const Divider(height: 40),

                  // Description
                  _buildDescriptionSection(),

                  const Divider(height: 40),

                  // Amenities Section
                  _buildAmenitiesSection(),

                  const Divider(height: 40),

                  // Location on Map
                  _buildLocationSection(),

                  const Divider(height: 40),

                  // Host Profile Section
                  _buildHostSection(),

                  const Divider(height: 40),

                  // Availability Calendar (Optional)
                  _buildAvailabilitySection(),

                  // Extra space at bottom to account for floating button
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Image Gallery - Full width Airbnb style with photo grid view button
  Widget _buildImageGallery() {
    return Stack(
      children: [
        // Main Image
        Container(
          height: 300,
          width: double.infinity,
          child: PageView.builder(
            itemCount: widget.location.imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return _buildFullScreenImage(widget.location.imageUrls[index]);
            },
          ),
        ),

        // Image counter indicator
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${widget.location.imageUrls.length}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Pagination dots
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.location.imageUrls.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentImageIndex == index
                          ? primaryColor
                          : Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ),

        // Navigation arrows
        if (widget.location.imageUrls.length > 1) ...[
          // Left arrow
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap:
                    _currentImageIndex > 0
                        ? () => setState(() => _currentImageIndex--)
                        : null,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

          // Right arrow
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap:
                    _currentImageIndex < widget.location.imageUrls.length - 1
                        ? () => setState(() => _currentImageIndex++)
                        : null,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFullScreenImage(String imageString) {
    try {
      String cleanBase64 = imageString;
      if (imageString.contains(',')) {
        cleanBase64 = imageString.split(',').last;
      }
      cleanBase64 = cleanBase64.trim();

      final Uint8List bytes = base64Decode(cleanBase64);

      return Stack(
        fit: StackFit.expand,
        children: [
          // Placeholder
          Container(color: Colors.grey[200]),

          // Actual image
          Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame != null ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: child,
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('Image error: $error');
              return Container(
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.grey[400],
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Unable to load image',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    } catch (e) {
      print('Base64 error: $e');
      return Container(
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 40),
            SizedBox(height: 8),
            Text(
              'Invalid image format',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
  }

  // Title Section (Airbnb style with breadcrumb location and title)
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location breadcrumb
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              'City, Casablanca',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Main property name
        Text(
          widget.location.name,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Stars row with price on the right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Stars on the left
            Row(
              children: List.generate(
                5, // Number of stars
                (index) => Icon(Icons.star, color: Colors.amber, size: 20),
              ),
            ),

            // Price on the right
            Text(
              '${widget.location.pricePerNight.toInt()} DH / nuit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Description Section
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About this place',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          widget.location.description,
          style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey[800]),
        ),
      ],
    );
  }

  // Display property type images with tap functionality
  Widget _buildPropertyTypesSection() {
    // Sample property images - in production, get these from your backend
    final propertyImages = [
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YXBhcnRtZW50fGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1579033462043-0f11a7862f7d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cmlhZHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8aG90ZWx8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1613977257363-707ba9348227?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8dmlsbGF8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cmVzb3J0fGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1564501049412-61c2a3083791?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTB8fGhvdGVsfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YWlycG9ydCUyMGhvdGVsfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1561501878-aabd62634e1d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8bHV4dXJ5JTIwaG90ZWx8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property images',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80, // Reduced height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: propertyImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _showPropertyImage(context, propertyImages[index]);
                },
                child: Container(
                  width: 80, // Smaller width
                  margin: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: propertyImages[index],
                          fit: BoxFit.cover,
                          height: 60, // Smaller height
                          width: 60, // Smaller width
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                        ),
                        // Add a semi-transparent overlay to indicate it's clickable
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Method to show a single property image in full screen with navigation
  void _showPropertyImage(BuildContext context, String imageUrl) {
    // Find the index of the current image
    final propertyImages = [
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YXBhcnRtZW50fGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1579033462043-0f11a7862f7d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cmlhZHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8aG90ZWx8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1613977257363-707ba9348227?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8dmlsbGF8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cmVzb3J0fGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1564501049412-61c2a3083791?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTB8fGhvdGVsfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YWlycG9ydCUyMGhvdGVsfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
      'https://images.unsplash.com/photo-1561501878-aabd62634e1d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8bHV4dXJ5JTIwaG90ZWx8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
    ];

    int currentIndex = propertyImages.indexOf(imageUrl);

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog.fullscreen(
              child: Stack(
                children: [
                  // Image
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: CachedNetworkImage(
                          imageUrl: propertyImages[currentIndex],
                          fit: BoxFit.contain,
                          placeholder:
                              (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ),

                  // Close button
                  Positioned(
                    top: 40,
                    left: 16,
                    child: IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Image counter
                  Positioned(
                    top: 40,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${currentIndex + 1}/${propertyImages.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Navigation arrows
                  // Left arrow
                  if (currentIndex > 0)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              currentIndex--;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Right arrow
                  if (currentIndex < propertyImages.length - 1)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              currentIndex++;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Amenities Section with Icons
  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What this place offers',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Ajoutez d'autres widgets ici si nécessaire
      ],
    );
  }

  // Location Section with Map
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where you\'ll be',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.location_on, color: secondaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.location.address,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Map Preview - Consider using a real map here
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: Stack(
            children: [
              // This is a placeholder - use GoogleMap widget for a real map
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Map view', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _openInMaps,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Exact location provided after booking',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  // Host Section
  Widget _buildHostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Host image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Icon(Icons.person, size: 40, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            // Host info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hosted by Local Host',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Member since ${DateFormat('MMMM yyyy').format(DateTime.now().subtract(const Duration(days: 365)))}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Host stats - Fixing overflow issue
        Wrap(
          spacing: 24, // Space between items
          runSpacing: 16, // Space between rows when wrapping
          children: [
            _buildHostStat(Icons.star, '4.92', 'Rating'),
            _buildHostStat(Icons.verified, '39', 'Reviews'),
            _buildHostStat(Icons.verified_user, 'Identity', 'Verified'),
          ],
        ),
        const SizedBox(height: 20),
        // Contact Host Button
        OutlinedButton(
          onPressed: _callLocation,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            side: const BorderSide(color: Colors.black87),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Contact host'),
        ),
      ],
    );
  }

  // Host stat helper
  Widget _buildHostStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Availability Section
  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Availability',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    widget.location.isAvailable
                        ? Colors.green[50]
                        : Colors.red[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      widget.location.isAvailable ? Colors.green : Colors.red,
                ),
              ),
              child: Text(
                widget.location.isAvailable ? 'Available' : 'Not Available',
                style: TextStyle(
                  color:
                      widget.location.isAvailable ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Price information
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.attach_money, color: secondaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            '${widget.location.pricePerNight.toStringAsFixed(0)} DH',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('night', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Minimum stay: 1 night',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cleaning fee: 150 DH',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBookingDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Book Your Stay',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the header
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Booking Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: _buildThumbnailImage(
                                    widget.location.imageUrls.first,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.location.type,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.location.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${widget.location.rating} · Great location',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
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

                        const SizedBox(height: 24),

                        // Date selection
                        const Text(
                          'Your trip',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dates
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CHECK-IN',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Add date',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CHECKOUT',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Add date',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'GUESTS',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          '1 guest',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Price breakdown
                        const Text(
                          'Price details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.location.pricePerNight} DH x 1 night',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              '${widget.location.pricePerNight} DH',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Cleaning fee',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text('150 DH', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Service fee', style: TextStyle(fontSize: 16)),
                            Text('100 DH', style: TextStyle(fontSize: 16)),
                          ],
                        ),

                        const Divider(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.location.pricePerNight + 150 + 100} DH',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Book button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Show booking confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Booking request sent!'),
                            backgroundColor: secondaryColor,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
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

  // Your existing methods
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

  void _showAllPhotos(BuildContext context) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder:
          (context) => Dialog.fullscreen(
            child: Stack(
              children: [
                // Photos gallery
                PageView.builder(
                  controller: PageController(initialPage: _currentImageIndex),
                  itemCount: widget.location.imageUrls.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 3.0,
                            child: _buildFullScreenImage(
                              widget.location.imageUrls[index],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Close button
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Image counter indicator
                Positioned(
                  top: 40,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${widget.location.imageUrls.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Navigation arrows
                if (widget.location.imageUrls.length > 1) ...[
                  // Left arrow
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap:
                            _currentImageIndex > 0
                                ? () => setState(() => _currentImageIndex--)
                                : null,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right arrow
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap:
                            _currentImageIndex <
                                    widget.location.imageUrls.length - 1
                                ? () => setState(() => _currentImageIndex++)
                                : null,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }

  Widget _buildActionButton(IconData icon, String text) {
    return InkWell(
      onTap: () {
        // Action functionality
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.black),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              decoration: TextDecoration.underline,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
