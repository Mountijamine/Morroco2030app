import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/restaurant/restaurant_model.dart';
import 'package:flutter_application_1/restaurant/restaurant_service.dart';
import 'package:flutter_application_1/restaurant/restaurant_detail.dart';
import 'package:flutter_application_1/restaurant/add_restaurant_screen.dart';
import 'package:flutter_application_1/restaurant/menu_item_model.dart';
import 'package:flutter_application_1/restaurant/menu_service.dart';
import 'package:flutter_application_1/restaurant/add_menu_item_screen.dart';
import 'package:flutter_application_1/restaurant/menu_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CityDetailScreen extends StatefulWidget {
  final City city;

  const CityDetailScreen({Key? key, required this.city}) : super(key: key);

  @override
  State<CityDetailScreen> createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends State<CityDetailScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  int fidelityPoints = 0;
  String selectedCategory = 'Tendance'; // Default selected category
  bool isLoading = false;
  late AnimationController _animationController;
  final RestaurantService _restaurantService = RestaurantService();
  List<Restaurant> _restaurants = [];
  String _selectedRestaurantType = 'All';
  List<String> _restaurantTypes = [
    'All',
    'Restaurant',
    'Café',
    'Fast Food',
    'Bakery',
  ];
  List<Restaurant> _filteredRestaurants = [];

  // Main app color
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);

  @override
  void initState() {
    super.initState();
    _loadUserPoints();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Initialize with restaurants if that's the default category
    if (selectedCategory == 'Restau & café') {
      _loadRestaurants();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPoints() async {
    if (user == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();

      if (userDoc.exists) {
        setState(() {
          fidelityPoints = userDoc.data()!['fidelityPoints'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading user points: $e');
    }
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      isLoading = true;
    });

    try {
      final restaurants = await _restaurantService.getRestaurantsForCity(
        widget.city,
      );

      setState(() {
        _restaurants = restaurants;
        _filterRestaurantsByType(); // Apply filter
        isLoading = false;
      });

      // Start animation after data is loaded
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      print('Error loading restaurants: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterRestaurantsByType() {
    if (_selectedRestaurantType == 'All') {
      _filteredRestaurants = List.from(_restaurants);
    } else {
      _filteredRestaurants =
          _restaurants
              .where((restaurant) => restaurant.type == _selectedRestaurantType)
              .toList();
    }
  }

  Future<void> _toggleFavorite() async {
    // Get current user
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to favorite cities'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final cityRef = FirebaseFirestore.instance
          .collection('cities')
          .doc(widget.city.id);

      // Check if city is already favorited
      bool isFavorited = widget.city.favoritedBy.contains(user.uid);

      if (isFavorited) {
        // Remove from favorites
        await cityRef.update({
          'favoritedBy': FieldValue.arrayRemove([user.uid]),
        });

        setState(() {
          widget.city.favoritedBy.remove(user.uid);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${widget.city.name} from favorites'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Add to favorites
        await cityRef.update({
          'favoritedBy': FieldValue.arrayUnion([user.uid]),
        });

        setState(() {
          widget.city.favoritedBy.add(user.uid);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${widget.city.name} to favorites'),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating favorites: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openCityInMaps() async {
    try {
      final latitude = widget.city.location.latitude;
      final longitude = widget.city.location.longitude;

      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open maps: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the standard AppBar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0,
        title: Text(
          widget.city.name,
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
          // Add location icon to open maps
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            onPressed: _openCityInMaps,
          ),
          // Add favorite icon
          IconButton(
            icon: Icon(
              widget.city.favoritedBy.contains(user?.uid)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color:
                  widget.city.favoritedBy.contains(user?.uid)
                      ? Colors.red
                      : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
          // Keep points icon
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            onPressed: () {
              // Show fidelity points system
            },
          ),
        ],
        // Add a gradient background to the AppBar for better readability
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      // Add FloatingActionButton when restaurants category is selected
      floatingActionButton:
          selectedCategory == 'Restau & café'
              ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AddRestaurantScreen(city: widget.city),
                    ),
                  );
                  // Refresh restaurant list if a new restaurant was added
                  if (result == true) {
                    _loadRestaurants();
                  }
                },
                backgroundColor: secondaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
      body: Container(
        color: Colors.white, // Set overall background to white
        child: Column(
          children: [
            // City Image Header with Fidelity Points
            Stack(
              children: [
                // City Image as Background (extend it to include the AppBar height)
                Container(
                  height:
                      180 +
                      MediaQuery.of(
                        context,
                      ).padding.top, // Add status bar height
                  width: double.infinity,
                  child:
                      widget.city.imageBase64 != null &&
                              widget.city.imageBase64!.isNotEmpty
                          ? Image.memory(
                            base64Decode(widget.city.imageBase64!),
                            fit: BoxFit.cover,
                          )
                          : CachedNetworkImage(
                            imageUrl: widget.city.imageUrl,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  color: Colors.grey[800],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: Colors.grey[800],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.white70,
                                  ),
                                ),
                          ),
                ),

                // Dark gradient overlay to ensure text readability
                Container(
                  height: 180 + MediaQuery.of(context).padding.top,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(
                          0.0,
                        ), // Transparent at top to not interfere with AppBar gradient
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Fidelity Points Card - positioned to account for AppBar height
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: secondaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.diamond_outlined,
                                color: secondaryColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Number of points',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(DateTime.now()),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Points display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$fidelityPoints,00',
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white, // Keep consistent white background
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                // Optional border at the bottom for subtle separation
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModernCategoryButton(
                    'Tendance',
                    Icons.trending_up,
                    primaryColor,
                  ),
                  _buildModernCategoryButton(
                    'Location',
                    Icons.home,
                    primaryColor,
                  ),
                  _buildModernCategoryButton(
                    'Restau & café',
                    Icons.restaurant_menu,
                    primaryColor,
                  ),
                  _buildModernCategoryButton(
                    'Hawta',
                    Icons.place,
                    primaryColor,
                  ),
                ],
              ),
            ),

            // Content based on selected category - WITH WHITE BACKGROUND
            Expanded(
              child:
                  isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                      : Container(
                        color:
                            Colors.white, // Make ALL content background white
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title for selected category with icon and count
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 4.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Left side: Category icon and title
                                    Row(
                                      children: [
                                        Icon(
                                          _getCategoryIcon(selectedCategory),
                                          color: secondaryColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          selectedCategory,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: secondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Right side: Item count
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        selectedCategory == 'Restau & café'
                                            ? '${_filteredRestaurants.length} items'
                                            : '4 items', // Placeholder count for other categories
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Subtle divider
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Dynamic content based on selected category
                              _buildCategoryContent(),
                            ],
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCategoryButton(
    String category,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedCategory == category;

    return InkWell(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });

        // Load restaurants when that category is selected
        if (category == 'Restau & café') {
          _loadRestaurants();
        } else {
          // Reset animation for other categories
          _animationController.reset();
          _animationController.forward();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? secondaryColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                      : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : secondaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? secondaryColor : Colors.black87,
            ),
          ),
          // Indicator dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(top: 4),
            width: isSelected ? 8 : 0,
            height: 8,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPlaceholderItems() {
    return Column(
      children: List.generate(
        4,
        (index) => AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.5, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.2,
                    0.6 + index * 0.1,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      index * 0.2,
                      0.6 + index * 0.1,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Icon(
                      _getCategoryIcon(selectedCategory),
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedCategory} Place ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 16, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${4.0 + index * 0.2}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sample ${selectedCategory.toLowerCase()} location in ${widget.city.name}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '2.${index + 1} km from center',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(index + 1) * 100 + 300} DH',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
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
        ),
      ),
    );
  }

  Widget _buildCategoryContent() {
    if (selectedCategory == 'Restau & café') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white, // Match the white background
              borderRadius: BorderRadius.circular(10),
              // Optional subtle border to separate from content
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _restaurantTypes.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final type = _restaurantTypes[index];
                  final isSelected = _selectedRestaurantType == type;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedRestaurantType = type;
                        _filterRestaurantsByType();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? secondaryColor : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? secondaryColor : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRestaurantTypeIcon(type),
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isSelected ? Colors.white : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // REDUCED this spacing from 16 to 8 pixels
          const SizedBox(height: 8),

          // Show empty state or restaurant list
          _filteredRestaurants.isEmpty && !isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedRestaurantType == 'All'
                          ? 'No restaurants found in ${widget.city.name}'
                          : 'No $_selectedRestaurantType establishments found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    AddRestaurantScreen(city: widget.city),
                          ),
                        );
                        if (result == true) {
                          _loadRestaurants();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add restaurant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children:
                    _filteredRestaurants
                        .map((restaurant) => _buildRestaurantItem(restaurant))
                        .toList(),
              ),
        ],
      );
    } else {
      // Return placeholder items for other categories
      return _buildModernPlaceholderItems();
    }
  }

  Widget _buildRestaurantItem(Restaurant restaurant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => RestaurantDetailScreen(restaurant: restaurant),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.5, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.2, 0.8, curve: Curves.easeOut),
                ),
              ),
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant image slider
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child:
                        restaurant.imageUrls.isNotEmpty
                            ? SizedBox(
                              height: 140,
                              child: PageView.builder(
                                itemCount: restaurant.imageUrls.length,
                                itemBuilder: (context, index) {
                                  return _buildRestaurantImageItem(
                                    restaurant.imageUrls[index],
                                  );
                                },
                              ),
                            )
                            : Container(
                              height: 140,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "No images available",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                  ),

                  // Map location button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      onTap: () async {
                        final latitude = restaurant.location.latitude;
                        final longitude = restaurant.location.longitude;

                        final url = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
                        );

                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions,
                          size: 20,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Restaurant details content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 16, color: primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                '${restaurant.rating}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      restaurant.cuisine,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurant.address,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.menu_book, color: secondaryColor),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => MenuDetailScreen(
                                      restaurant: restaurant,
                                    ),
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantImageItem(String imageSource) {
    if (imageSource.startsWith('data:image')) {
      String base64String = imageSource.split(',')[1];
      try {
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
      try {
        return Image.memory(
          base64Decode(imageSource),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding raw base64 image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else {
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder:
            (context, url) =>
                Center(child: CircularProgressIndicator(color: primaryColor)),
        errorWidget: (context, url, error) => _buildImageErrorPlaceholder(),
      );
    }
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text(
              "Image unavailable",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tendance':
        return Icons.trending_up;
      case 'Location':
        return Icons.home;
      case 'Restau & café':
        return Icons.restaurant_menu;
      case 'Hawta':
        return Icons.place;
      default:
        return Icons.category;
    }
  }

  IconData _getRestaurantTypeIcon(String type) {
    switch (type) {
      case 'Restaurant':
        return Icons.restaurant;
      case 'Café':
        return Icons.coffee;
      case 'Fast Food':
        return Icons.fastfood;
      case 'Bakery':
        return Icons.bakery_dining;
      case 'Bar':
        return Icons.local_bar;
      default:
        return Icons.food_bank; // Default icon for 'All' or unknown types
    }
  }

  Color _getCategoryColor(String category) {
    return secondaryColor; // Using a consistent color scheme
  }
}
