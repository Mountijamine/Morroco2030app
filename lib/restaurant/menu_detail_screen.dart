import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/restaurant/menu_item_model.dart';
import 'package:flutter_application_1/restaurant/menu_service.dart';
import 'package:flutter_application_1/restaurant/restaurant_model.dart';

class MenuDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const MenuDetailScreen({Key? key, required this.restaurant})
    : super(key: key);

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  final MenuService _menuService = MenuService();
  bool _isLoading = true;
  List<MenuItem> _menuItems = [];
  Map<String, List<MenuItem>> _categorizedItems = {};

  // Colors matching your app theme
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    setState(() => _isLoading = true);

    try {
      // Simulate database call with sample data for now
      // In a real implementation, uncomment the line below
      // final menuItems = await _menuService.getMenuForRestaurant(widget.restaurant.id);

      // Sample menu items for demonstration
      final List<MenuItem> menuItems = [
        MenuItem(
          id: '1',
          name: 'Moroccan Couscous',
          price: 120.00,
          description: 'Traditional couscous with vegetables and lamb',
          imageUrl: 'https://i.imgur.com/4vgFwOj.jpg',
          category: 'Main Dishes',
          restaurantId: widget.restaurant.id,
          restaurantName: widget.restaurant.name,
          cityId: widget.restaurant.cityId,
        ),
        MenuItem(
          id: '2',
          name: 'Tagine of Lamb',
          price: 140.00,
          description: 'Slow-cooked lamb with prunes and almonds',
          imageUrl: 'https://i.imgur.com/dh3Zve7.jpg',
          category: 'Main Dishes',
          restaurantId: widget.restaurant.id,
          restaurantName: widget.restaurant.name,
          cityId: widget.restaurant.cityId,
        ),
        MenuItem(
          id: '3',
          name: 'Mint Tea',
          price: 25.00,
          description: 'Sweet mint tea served in traditional glass',
          imageUrl: 'https://i.imgur.com/3DDCSbI.jpg',
          category: 'Drinks',
          restaurantId: widget.restaurant.id,
          restaurantName: widget.restaurant.name,
          cityId: widget.restaurant.cityId,
        ),
        MenuItem(
          id: '4',
          name: 'Moroccan Salad',
          price: 45.00,
          description: 'Fresh vegetables with olive oil and herbs',
          imageUrl: 'https://i.imgur.com/92aNYKo.jpg',
          category: 'Starters',
          restaurantId: widget.restaurant.id,
          restaurantName: widget.restaurant.name,
          cityId: widget.restaurant.cityId,
        ),
        MenuItem(
          id: '5',
          name: 'Pastilla',
          price: 85.00,
          description: 'Sweet and savory pie with chicken and almonds',
          imageUrl: 'https://i.imgur.com/TWLXs5D.jpg',
          category: 'Starters',
          restaurantId: widget.restaurant.id,
          restaurantName: widget.restaurant.name,
          cityId: widget.restaurant.cityId,
        ),
      ];

      // Group items by category
      final Map<String, List<MenuItem>> categorized = {};
      for (var item in menuItems) {
        if (!categorized.containsKey(item.category)) {
          categorized[item.category] = [];
        }
        categorized[item.category]!.add(item);
      }

      setState(() {
        _menuItems = menuItems;
        _categorizedItems = categorized;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading menu items: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Menu - ${widget.restaurant.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              // Filter/sort options could go here
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _menuItems.isEmpty
              ? _buildEmptyState()
              : _buildMenuList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No menu items available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for updates',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _loadMenuItems();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu header with restaurant info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.restaurant.name} Menu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_menuItems.length} items available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Display categories and items
          ..._categorizedItems.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Display items in category
                ...entry.value.map((item) => _buildMenuItem(item)).toList(),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item image
          if (item.imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _buildImageWidget(item.imageUrl),
                ),
              ),
            ),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '₪${item.price.toStringAsFixed(item.price.truncateToDouble() == item.price ? 0 : 2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                  ),
                ],

                if (!item.isAvailable) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Currently unavailable',
                      style: TextStyle(fontSize: 12, color: Colors.red[800]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageSource) {
    if (imageSource.startsWith('data:image') ||
        RegExp(
          r'^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$',
        ).hasMatch(imageSource)) {
      // This is likely a base64 image
      String base64String = imageSource;
      if (imageSource.contains(',')) {
        base64String = imageSource.split(',')[1];
      }

      try {
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading base64 image: $error');
            return _buildImageErrorWidget();
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildImageErrorWidget();
      }
    } else {
      // This is a URL
      return Image.network(
        imageSource,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: primaryColor,
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
      );
    }
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.restaurant_menu, size: 40, color: Colors.grey[400]),
    );
  }
}
