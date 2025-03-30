import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/authentification/login_page.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/city/add_city.dart';
import 'package:flutter_application_1/profile/profileview.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/utils/url_utils.dart';
import 'dart:math';
import 'package:flutter/services.dart'; 

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final user = FirebaseAuth.instance.currentUser;
   int fidelityPoints = 0; 
  String userReferralCode = '';
  
  // City filtering
  List<City> _cities = [];
  List<City> _filteredCities = [];
  String _selectedFilter = 'All';
  String _selectedTypeFilter = 'All';
  bool _isLoading = true;
  GeoPoint? _userLocation;
  bool _isLoadingUserLocation = true;
  @override
  void initState() {
    super.initState();
      _loadUserLocation();
    _loadCities();
     _loadUserPoints(); 
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
          // Get fidelity points with fallback to 0
          fidelityPoints = userDoc.data()!['fidelityPoints'] ?? 0;
          // Get referral code with fallback
          userReferralCode = userDoc.data()!['referralCode'] ?? user!.uid.substring(0, 8);
        });
      }
    } catch (e) {
      print('Error loading user points: $e');
    }
  }
  
Future<void> _loadUserLocation() async {
    setState(() {
      _isLoadingUserLocation = true;
    });
    
    try {
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        
        if (userDoc.exists && userDoc.data()!.containsKey('location')) {
          setState(() {
            _userLocation = userDoc.data()!['location'] as GeoPoint;
          });
        }
      }
    } catch (e) {
      print('Error loading user location: $e');
    } finally {
      setState(() {
        _isLoadingUserLocation = false;
      });
    }
  }
    double _calculateDistance(GeoPoint point1, GeoPoint point2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    
    // Convert to radians
    final lat1 = point1.latitude * (pi / 180);
    final lon1 = point1.longitude * (pi / 180);
    final lat2 = point2.latitude * (pi / 180);
    final lon2 = point2.longitude * (pi / 180);
    
    // Haversine formula
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    
    final a = sin(dLat/2) * sin(dLat/2) + 
              cos(lat1) * cos(lat2) * 
              sin(dLon/2) * sin(dLon/2);
    final c = 2 * atan2(sqrt(a), sqrt(1-a));
    final distance = earthRadius * c;
    
    return distance;
  }
  Future<void> _loadCities() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final citiesRef = FirebaseFirestore.instance.collection('cities');
      final snapshot = await citiesRef.get();
      
      _cities = snapshot.docs.map((doc) => City.fromFirestore(doc)).toList();
      _filterCities(_selectedFilter, typeFilter: _selectedTypeFilter);
    } catch (e) {
      print('Error loading cities: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load cities: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCities(String filter, {String? typeFilter}) {
    setState(() {
      _selectedFilter = filter;
      if (typeFilter != null) _selectedTypeFilter = typeFilter;
      
      _filteredCities = _cities.where((city) {
        bool matchesName = _selectedFilter == 'All' || city.name == _selectedFilter;
        bool matchesType = _selectedTypeFilter == 'All' || city.type == _selectedTypeFilter;
        return matchesName && matchesType;
      }).toList();
    });
  }

  Future<void> _toggleFavorite(City city) async {
    if (user == null) return;
    
    try {
      final cityRef = FirebaseFirestore.instance.collection('cities').doc(city.id);
      
      if (city.favoritedBy.contains(user!.uid)) {
        // Remove from favorites
        await cityRef.update({
          'favoritedBy': FieldValue.arrayRemove([user!.uid])
        });
      } else {
        // Add to favorites
        await cityRef.update({
          'favoritedBy': FieldValue.arrayUnion([user!.uid])
        });
      }
      
      // Refresh cities
      _loadCities();
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite status')),
      );
    }
  }

  Future<void> _openGoogleMaps(GeoPoint location) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ));
    }
  }

  // Get all unique city names for filter
  List<String> get _uniqueCityNames {
    final Set<String> names = {'All'};
    for (var city in _cities) {
      names.add(city.name);
    }
    return names.toList();
  }

  // Get all unique city types for filter
  List<String> get _uniqueTypes {
    final Set<String> types = {'All'};
    for (var city in _cities) {
      types.add(city.type);
    }
    return types.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFDCB00), // Morocco yellow
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfileView()),
                );
              },
              icon: const Icon(Icons.person, color: Colors.white),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddCityScreen()),
                ).then((_) => _loadCities());
              },
              icon: const Icon(Icons.add_location_alt, color: Colors.white),
            ),
            IconButton(
        onPressed: _showFidelityPointsSystem,
        icon: const Icon(Icons.card_giftcard, color: Colors.white),
      ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Fidelity Points Header
          Container(
            color: const Color(0xFFFDCB00),
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
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
                      // Icon on the left
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFF065d67),
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Number of points',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(DateTime.now()), // Today's date
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Points on the right
                  Text(
                    '$fidelityPoints,00',
                    style: const TextStyle(
                      color: Color(0xFF065d67),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter Sections
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Villes 🌍',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // City Name Filters
                _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _uniqueCityNames.map((cityName) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cityName),
                            selected: _selectedFilter == cityName,
                            selectedColor: const Color(0xFF065d67).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF065d67),
                            onSelected: (bool selected) {
                              if (selected) {
                                _filterCities(cityName);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                
                // City Type Filters
                const SizedBox(height: 12),
                const Text(
                  'Type de Ville',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _uniqueTypes.map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type),
                            selected: _selectedTypeFilter == type,
                            selectedColor: const Color(0xFFFDCB00).withOpacity(0.7),
                            checkmarkColor: const Color(0xFF065d67),
                            onSelected: (bool selected) {
                              if (selected) {
                                _filterCities(_selectedFilter, typeFilter: type);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // City Cards
          Expanded(
            child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredCities.isEmpty
              ? const Center(child: Text('No cities found'))
              : RefreshIndicator(
                  onRefresh: _loadCities,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCityCard(city),
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF065d67),
        onPressed: _loadCities,
        child: const Icon(Icons.refresh),
      ),
    );
  }
 void _showFidelityPointsSystem() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.card_giftcard,
                    color: Color(0xFF065d67),
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Système de Points Fidélité',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065d67),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous avez actuellement $fidelityPoints points',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // How to earn points
                  const ListTile(
                    leading: Icon(Icons.add_circle, color: Color(0xFFFDCB00)),
                    title: Text('Comment gagner des points'),
                    subtitle: Text('Ajoutez des villes, partagez l\'application ou parrainez des amis'),
                  ),
                  
                  // Benefits
                  const ListTile(
                    leading: Icon(Icons.stars, color: Color(0xFFFDCB00)),
                    title: Text('Avantages'),
                    subtitle: Text('Débloquez des réductions sur des activités comme ski, karting et plus'),
                  ),
                  
                  // Redeem points
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      // Navigate to redemption page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La page d\'échange de points sera disponible bientôt!')),
                      );
                    },
                    child: const ListTile(
                      leading: Icon(Icons.redeem, color: Color(0xFFFDCB00)),
                      title: Text('Échanger des points'),
                      subtitle: Text('Ski, Karting, Plages VIP et plus'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),
                  
                  const Divider(height: 32),
                  
                  // Referral section
                  const ListTile(
                    leading: Icon(Icons.share, color: Color(0xFFFDCB00)),
                    title: Text('Parrainez vos amis'),
                    subtitle: Text('Vous recevez 25 points quand un ami s\'inscrit avec votre code'),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Referral code display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          userReferralCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Color(0xFF065d67)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: userReferralCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copié dans le presse-papier')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Share button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Share referral code
                      final shareMessage = 'Rejoignez-moi sur CityGuide! Utilisez mon code $userReferralCode pour obtenir 25 points. https://cityguide.app/download';
                      
                      // Show a snackbar for now (would use share plugin in real app)
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Partage du code: $userReferralCode')),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Partager mon code'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF065d67),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Keep logout for user convenience
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      signOut();
                    },
                    child: const Text(
                      'Déconnexion',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

Widget _buildCityCard(City city) {
  bool isFavorited = city.favoritedBy.contains(user?.uid);
  
  // Calculate distance if user location is available
  String distanceText = '';
  if (_userLocation != null) {
    double distance = _calculateDistance(_userLocation!, city.location);
    if (distance < 1) {
      // If less than 1 km, show in meters
      distanceText = '${(distance * 1000).toStringAsFixed(0)} m';
    } else {
      // Otherwise show in kilometers
      distanceText = '${distance.toStringAsFixed(1)} km';
    }
  }
  
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    elevation: 4,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // City image
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: city.imageBase64 != null && city.imageBase64!.isNotEmpty
                  // If Base64 image is available, use it
                  ? Image.memory(
                      base64Decode(city.imageBase64!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    )
                  // Otherwise use the URL (for backward compatibility)
                  : CachedNetworkImage(
                      imageUrl: city.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
            ),
            // Type indicator
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  city.type,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Map location button
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.map, color: Color(0xFF065d67)),
                  onPressed: () => _openGoogleMaps(city.location),
                ),
              ),
            ),
          ],
        ),
        
        // City details
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    city.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: isFavorited ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(city),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                city.description,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${city.favoritedBy.length} favoris',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  
                  // Add distance indicator if available
                  if (distanceText.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      distanceText,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}