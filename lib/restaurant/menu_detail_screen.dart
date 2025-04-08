import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/restaurant/menu_item_model.dart';
import 'package:flutter_application_1/restaurant/menu_service.dart';
import 'package:flutter_application_1/restaurant/restaurant_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MenuDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const MenuDetailScreen({Key? key, required this.restaurant})
    : super(key: key);

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen>
    with SingleTickerProviderStateMixin {
  final MenuService _menuService = MenuService();
  bool _isLoading = true;
  List<MenuItem> _menuItems = [];
  Map<String, List<MenuItem>> _categorizedItems = {};
  String _debugMessage = ''; // For debugging

  // Filter state variables
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _priceSort = 'Default';
  bool _onlyAvailable = false;
  bool _onlyBestsellers = false;
  bool _isFilterVisible = false;

  // Animation controller for filter panel
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  // Colors matching your app theme
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);

  @override
  void initState() {
    super.initState();
    _loadMenuItems();

    // Initialize animation controller
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    super.dispose();
  }

  // Toggle filter visibility
  void _toggleFilterVisibility() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
      if (_isFilterVisible) {
        _filterAnimationController.forward();
      } else {
        _filterAnimationController.reverse();
      }
    });
  }

  // Filter menu items based on criteria
  List<MenuItem> _getFilteredMenuItems() {
    List<MenuItem> filteredItems = List.from(_menuItems);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredItems =
          filteredItems
              .where(
                (item) =>
                    item.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    item.description.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filteredItems =
          filteredItems
              .where((item) => item.category == _selectedCategory)
              .toList();
    }

    // Filter by availability
    if (_onlyAvailable) {
      filteredItems = filteredItems.where((item) => item.isAvailable).toList();
    }

    // Filter by bestseller
    if (_onlyBestsellers) {
      filteredItems = filteredItems.where((item) => item.isBestseller).toList();
    }

    // Sort by price
    if (_priceSort == 'Low to High') {
      filteredItems.sort((a, b) => a.price.compareTo(b.price));
    } else if (_priceSort == 'High to Low') {
      filteredItems.sort((a, b) => b.price.compareTo(a.price));
    }

    return filteredItems;
  }

  // Get all unique categories for filter dropdown
  List<String> _getCategories() {
    final Set<String> categories = {'All'};
    for (var item in _menuItems) {
      if (item.category.isNotEmpty) {
        categories.add(item.category);
      }
    }
    return categories.toList();
  }

  // Create filtered and categorized items
  Map<String, List<MenuItem>> _getFilteredCategorizedItems() {
    final filteredItems = _getFilteredMenuItems();

    // If price sorting or searching is active, we'll show items in a flat list
    if (_searchQuery.isNotEmpty || _priceSort != 'Default') {
      return {'Filtered Results': filteredItems};
    }

    // Otherwise group by category
    final Map<String, List<MenuItem>> categorized = {};

    for (var item in filteredItems) {
      final category =
          item.category.isNotEmpty ? item.category : 'Uncategorized';

      if (!categorized.containsKey(category)) {
        categorized[category] = [];
      }

      categorized[category]!.add(item);
    }

    return categorized;
  }

  // Reset all filters
  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _priceSort = 'Default';
      _onlyAvailable = false;
      _onlyBestsellers = false; // Reset bestseller filter
    });
  }

  Future<void> _loadMenuItems() async {
    setState(() {
      _isLoading = true;
      _debugMessage = 'Loading menu items...';
    });

    try {
      // For debugging - print restaurant ID
      print('Loading menu for restaurant ID: ${widget.restaurant.id}');

      List<MenuItem> menuItems = [];

      try {
        // Try to fetch from Firestore first
        menuItems = await _menuService.getMenuForRestaurant(
          widget.restaurant.id,
        );
        print('Loaded ${menuItems.length} items from Firestore');
        _debugMessage = 'Loaded ${menuItems.length} items from Firestore';
      } catch (e) {
        print('Error loading from Firestore: $e');
        _debugMessage = 'Firestore error: $e';
        // Create mock menu items from restaurant.menuItems
        menuItems = _createMockMenuItems();
        print('Created ${menuItems.length} mock items');
      }

      // Debug - check what we received
      if (menuItems.isEmpty) {
        print('WARNING: No menu items found!');
        _debugMessage += '\nNo items found in Firestore.';

        // Fallback to creating items from restaurant.menuItems
        if (widget.restaurant.menuItems.isNotEmpty) {
          menuItems = _createMockMenuItems();
          print(
            'Created ${menuItems.length} mock items from restaurant.menuItems',
          );
          _debugMessage += '\nCreated ${menuItems.length} mock items.';
        }
      }

      // Group items by category (handle empty categories)
      final Map<String, List<MenuItem>> categorized = {};

      for (var item in menuItems) {
        // Use 'Uncategorized' for empty categories
        final category =
            item.category.isNotEmpty ? item.category : 'Uncategorized';

        if (!categorized.containsKey(category)) {
          categorized[category] = [];
        }

        categorized[category]!.add(item);
      }

      setState(() {
        _menuItems = menuItems;
        _categorizedItems = categorized;
        _isLoading = false;
        _debugMessage += '\nProcess complete. Items: ${menuItems.length}';
      });
    } catch (e) {
      print('Error in _loadMenuItems: $e');
      _debugMessage += '\nError: $e';
      // Create backup items if all else fails
      _handleFallbackItems();
    }
  }

  // Create mock menu items from restaurant.menuItems
  List<MenuItem> _createMockMenuItems() {
    List<MenuItem> mockItems = [];
    int index = 0;

    if (widget.restaurant.menuItems.isEmpty) {
      print('WARNING: restaurant.menuItems is empty!');
      return _createDefaultMenuItems(); // Create some default items
    }

    for (var itemName in widget.restaurant.menuItems) {
      // Create different categories for variety
      final categories = [
        'Starters',
        'Main Course',
        'Desserts',
        'Beverages',
        'Specials',
      ];
      final category = categories[index % categories.length];

      mockItems.add(
        MenuItem(
          id: 'mock-${index}',
          name: itemName,
          price: 50.0 + (index * 10), // Varied prices
          description: 'Delicious $itemName prepared with fresh ingredients',
          imageUrl: '', // No image for mock data
          category: category,
          restaurantId: widget.restaurant.id,
          restaurantName: widget.restaurant.name,
          cityId: widget.restaurant.cityId,
        ),
      );

      index++;
    }

    return mockItems;
  }

  // Create some default menu items
  List<MenuItem> _createDefaultMenuItems() {
    return [
      MenuItem(
        id: 'default-1',
        name: 'House Special',
        price: 120.0,
        description: 'Chef\'s special recipe',
        category: 'Specials',
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        cityId: widget.restaurant.cityId,
      ),
      MenuItem(
        id: 'default-2',
        name: 'Fresh Salad',
        price: 45.0,
        description: 'Mixed greens with our special dressing',
        category: 'Starters',
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        cityId: widget.restaurant.cityId,
      ),
      MenuItem(
        id: 'default-3',
        name: 'Grilled Chicken',
        price: 85.0,
        description: 'Served with vegetables and rice',
        category: 'Main Course',
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        cityId: widget.restaurant.cityId,
      ),
      MenuItem(
        id: 'default-4',
        name: 'Chocolate Cake',
        price: 35.0,
        description: 'Rich chocolate cake with vanilla ice cream',
        category: 'Desserts',
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        cityId: widget.restaurant.cityId,
      ),
    ];
  }

  // Fallback when everything fails
  void _handleFallbackItems() {
    print('Using fallback items mechanism');
    List<MenuItem> fallbackItems = _createDefaultMenuItems();

    // Create categories
    final Map<String, List<MenuItem>> categorized = {};
    for (var item in fallbackItems) {
      final category = item.category.isNotEmpty ? item.category : 'Menu';
      if (!categorized.containsKey(category)) {
        categorized[category] = [];
      }
      categorized[category]!.add(item);
    }

    setState(() {
      _menuItems = fallbackItems;
      _categorizedItems = categorized;
      _isLoading = false;
      _debugMessage += '\nUsing fallback items';
    });
  }

  Widget _buildBackgroundImage(String imageUrl) {
    if (imageUrl.startsWith('data:image') ||
        RegExp(
          r'^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$',
        ).hasMatch(imageUrl)) {
      // Handle base64 image
      try {
        String base64String = imageUrl;
        if (imageUrl.contains(',')) {
          base64String = imageUrl.split(',').last;
        }

        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => _buildFallbackBackground(),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildFallbackBackground();
      }
    } else if (imageUrl.startsWith('http')) {
      // Handle network image
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              color: secondaryColor,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        errorWidget: (context, url, error) => _buildFallbackBackground(),
      );
    } else {
      // Try as asset image
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => _buildFallbackBackground(),
      );
    }
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [secondaryColor, primaryColor],
        ),
      ),
    );
  }

  IconData getCategoryIcon(String category) {
    final lowercaseCategory = category.toLowerCase();

    if (lowercaseCategory.contains('starter') ||
        lowercaseCategory.contains('appetizer'))
      return Icons.lunch_dining;
    else if (lowercaseCategory.contains('main') ||
        lowercaseCategory.contains('course'))
      return Icons.dinner_dining;
    else if (lowercaseCategory.contains('dessert'))
      return Icons.icecream;
    else if (lowercaseCategory.contains('beverage') ||
        lowercaseCategory.contains('drink'))
      return Icons.local_drink;
    else if (lowercaseCategory.contains('breakfast'))
      return Icons.free_breakfast;
    else if (lowercaseCategory.contains('special'))
      return Icons.stars;
    else if (lowercaseCategory.contains('salad'))
      return Icons.spa;
    else if (lowercaseCategory.contains('soup'))
      return Icons.soup_kitchen;
    else if (lowercaseCategory.contains('pasta') ||
        lowercaseCategory.contains('noodle'))
      return Icons.ramen_dining;
    else if (lowercaseCategory.contains('pizza'))
      return Icons.local_pizza;
    else if (lowercaseCategory.contains('sandwich'))
      return Icons.breakfast_dining;
    else if (lowercaseCategory.contains('fish') ||
        lowercaseCategory.contains('seafood'))
      return Icons.set_meal;
    else if (lowercaseCategory.contains('vegetarian'))
      return Icons.eco;
    else if (lowercaseCategory.contains('meat'))
      return Icons.restaurant;
    else if (lowercaseCategory == 'all' ||
        lowercaseCategory == 'filtered results')
      return Icons.category;
    else
      return Icons.restaurant_menu;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 200, // Increased height for better image display
              floating: true,
              pinned: true,
              snap: false,
              title: Text(
                widget.restaurant.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(150, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Restaurant image background
                    widget.restaurant.imageUrls.isNotEmpty
                        ? _buildBackgroundImage(
                          widget.restaurant.imageUrls.first,
                        )
                        : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [secondaryColor, primaryColor],
                            ),
                          ),
                        ),

                    // Gradient overlay for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),

                    // Bottom restaurant info
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore our delicious menu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 3.0,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Tags row (cuisine type, etc.)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.restaurant.cuisine,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        widget.restaurant.rating.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: _toggleFilterVisibility,
                  tooltip: 'Filter menu',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadMenuItems,
                  tooltip: 'Refresh menu',
                ),
              ],
            ),
          ];
        },
        body: Stack(
          children: [
            // Main content
            if (_isLoading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Loading menu...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else if (_menuItems.isEmpty)
              _buildEmptyState()
            else
              _buildMenuContent(),

            // Filter panel that slides down
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizeTransition(
                sizeFactor: _filterAnimation,
                child: _buildFilterPanel(),
              ),
            ),

            // Debug message
            if (_debugMessage.isNotEmpty && false) // Set to true for debugging
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black.withOpacity(0.7),
                  child: Text(
                    _debugMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Filter panel UI
  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Filter Menu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
                onPressed: _resetFilters,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search menu...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Filter options in a row
          Row(
            children: [
              // Category dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        items:
                            _getCategories()
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      category,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Price sorting dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _priceSort,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        items: const [
                          DropdownMenuItem(
                            value: 'Default',
                            child: Text(
                              'Default',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Low to High',
                            child: Text(
                              'Low to High',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'High to Low',
                            child: Text(
                              'High to Low',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _priceSort = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Available only toggle
          Row(
            children: [
              Checkbox(
                value: _onlyAvailable,
                activeColor: secondaryColor,
                onChanged: (value) {
                  setState(() {
                    _onlyAvailable = value ?? false;
                  });
                },
              ),
              const Text('Show only available items'),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _onlyBestsellers,
                activeColor: secondaryColor,
                onChanged: (value) {
                  setState(() {
                    _onlyBestsellers = value ?? false;
                  });
                },
              ),
              Row(
                children: [
                  const Text('Show only bestsellers'),
                  const SizedBox(width: 4),
                  Icon(Icons.star, size: 16, color: primaryColor),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Main menu content
  Widget _buildMenuContent() {
    // Get the filtered and possibly categorized items
    final filteredCategorizedItems = _getFilteredCategorizedItems();

    // If no items match the current filters
    if (filteredCategorizedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No items match your filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Restaurant info card
        _buildRestaurantCard(),
        const SizedBox(height: 24),

        // Category cards (Optional - add this)
        if (_getCategories().length > 1) _buildCategoryCards(),

        // Display count of matching items if search/filter is active
        if (_searchQuery.isNotEmpty ||
            _selectedCategory != 'All' ||
            _onlyAvailable)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Found ${_getFilteredMenuItems().length} matching items',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Menu items
        ...filteredCategorizedItems.entries.map(
          (entry) => _buildCategorySection(entry.key, entry.value),
        ),
      ],
    );
  }

  // Restaurant card with animation
  Widget _buildRestaurantCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [secondaryColor, secondaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.restaurant.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_menuItems.length} items on the menu',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Category section with items
  Widget _buildCategorySection(String category, List<MenuItem> items) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern category header with icon
          Container(
            margin: const EdgeInsets.only(bottom: 16, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header with icon and count
                Row(
                  children: [
                    // Icon with gradient background
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            secondaryColor,
                            secondaryColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: secondaryColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        getCategoryIcon(category),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Category name with item count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Optional: Add a toggle to collapse/expand category
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: secondaryColor,
                      ),
                      onPressed: () {
                        // You can implement collapse/expand functionality here
                      },
                      splashRadius: 24,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Modern gradient divider
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        secondaryColor,
                        secondaryColor.withOpacity(0.5),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),

          // Display items in category with staggered animation
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return AnimatedContainer(
              duration: Duration(milliseconds: 200 + (index * 50)),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(0, 0, 0),
              child: _buildMenuItemCard(item),
            );
          }).toList(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Modernized menu item card
  Widget _buildMenuItemCard(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Show item details or add to cart functionality
          },
          child: Stack(
            children: [
              Column(
                children: [
                  // Image with curved top corners - take up more space for emphasis
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      child:
                          item.imageUrl.isNotEmpty
                              ? Hero(
                                tag: 'menu-item-${item.id}',
                                child: _buildImageWidget(item.imageUrl),
                              )
                              : _buildImagePlaceholder(item.name),
                    ),
                  ),

                  // Content section
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and price in a row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${item.price.toStringAsFixed(2)} MAD',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Description
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              height: 1.3,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Footer row with category and availability
                        Row(
                          children: [
                            if (item.category.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),

                            const Spacer(),

                            // Add to cart button
                            Container(
                              decoration: BoxDecoration(
                                color: secondaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    // Add to cart functionality
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_shopping_cart,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Add',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.isBestseller)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Bestseller',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String itemName) {
    // Create a visually pleasing placeholder based on item name
    final colorSeed = itemName.hashCode;
    final colors = [
      Colors.amber[200],
      Colors.lightBlue[200],
      Colors.lightGreen[200],
      Colors.purple[200],
      Colors.orange[200],
      Colors.teal[200],
    ];
    final color = colors[colorSeed % colors.length];

    return Container(
      color: color,
      child: Center(
        child: Text(
          itemName.isNotEmpty ? itemName[0].toUpperCase() : "?",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageSource) {
    if (imageSource.startsWith('data:image') ||
        RegExp(
          r'^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$',
        ).hasMatch(imageSource)) {
      // Handle base64 image
      try {
        String base64String = imageSource;
        if (imageSource.contains(',')) {
          base64String = imageSource.split(',').last;
        }

        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error with base64 image: $error');
            return _buildImageErrorWidget();
          },
        );
      } catch (e) {
        print('Base64 decode error: $e');
        return _buildImageErrorWidget();
      }
    } else if (imageSource.startsWith('http')) {
      // Handle URL image with CachedNetworkImage for better performance
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
        errorWidget: (context, url, error) {
          print('Network image error: $error');
          return _buildImageErrorWidget();
        },
      );
    } else {
      // Try as an asset image
      return Image.asset(
        imageSource,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Asset image error: $error');
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

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(28),
              child: Icon(
                Icons.restaurant_menu,
                size: 70,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No menu items available',
              style: TextStyle(
                fontSize: 22,
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This restaurant hasn\'t added any menu items yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadMenuItems,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Category cards widget
  Widget _buildCategoryCards() {
    final categories = _getCategories();
    // Remove 'All' from display if present
    if (categories.contains('All')) {
      categories.remove('All');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isSelected
                          ? [secondaryColor, secondaryColor.withOpacity(0.8)]
                          : [Colors.white, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.white.withOpacity(0.2)
                              : primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      getCategoryIcon(category),
                      color: isSelected ? Colors.white : secondaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.length > 12
                        ? '${category.substring(0, 10)}...'
                        : category,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
