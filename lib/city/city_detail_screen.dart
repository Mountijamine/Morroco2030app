import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CityDetailScreen extends StatefulWidget {
  final City city;

  const CityDetailScreen({Key? key, required this.city}) : super(key: key);

  @override
  State<CityDetailScreen> createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends State<CityDetailScreen> with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  int fidelityPoints = 0;
  String selectedCategory = 'Tendance'; // Default selected category
  bool isLoading = false;
  late AnimationController _animationController;
  
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
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPoints() async {
    if (user == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
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
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            onPressed: () {
              // Show fidelity points system
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Fidelity Points Header - KEEPING THE SAME DESIGN
          Container(
            color: primaryColor,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                            DateFormat('dd/MM/yyyy').format(DateTime.now()),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

          // Featured Image - MAKING SMALLER (BANNER STYLE)
          SizedBox(
            height: 150, // Reduced from 200
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.city.imageBase64 != null && widget.city.imageBase64!.isNotEmpty
                    ? Image.memory(
                        base64Decode(widget.city.imageBase64!),
                        fit: BoxFit.cover,
                      )
                    : CachedNetworkImage(
                        imageUrl: widget.city.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                // Simple dark overlay
                Container(
                  color: Colors.black.withOpacity(0.2),
                ),
              ],
            ),
          ),

          // Category filters - SIMPLIFIED DESIGN
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
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

          // Content based on selected category
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title for selected category with icon
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
                        const SizedBox(height: 8),
                        
                        // Subtle divider
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Content will change based on selected category
                        Text(
                          'Showing the best $selectedCategory options in ${widget.city.name}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Modern placeholder items
                        _buildModernPlaceholderItems(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCategoryButton(String category, IconData icon, Color color) {
    final isSelected = selectedCategory == category;

    return InkWell(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
        // Trigger animation
        _animationController.reset();
        _animationController.forward();
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
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ] : null,
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
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index * 0.2,
                  0.6 + index * 0.1,
                  curve: Curves.easeOutCubic,
                ),
              )),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: primaryColor,
                                ),
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
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

  Color _getCategoryColor(String category) {
    return secondaryColor; // Using a consistent color scheme
  }
}