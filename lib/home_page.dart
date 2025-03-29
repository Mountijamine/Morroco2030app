import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/authentification/login_page.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter_application_1/profile/profileview.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final user = FirebaseAuth.instance.currentUser;
  final int fidelityPoints = 10;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(LoginPage.route());
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.yellow.shade700,
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
            onPressed: signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
    ),
      body: Column(
        children: [
          // Fidelity Points Header
          Container(
            color: Colors.yellow.shade700,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                        color: Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nombre de points',
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
                      color: Colors.orange,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Villes 🌍',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                FilterChip(
                  label: const Text('All'),
                  selected: true,
                  onSelected: (bool value) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Casablanca'),
                  selected: false,
                  onSelected: (bool value) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Tanger'),
                  selected: false,
                  onSelected: (bool value) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Marrakech'),
                  selected: false,
                  onSelected: (bool value) {},
                ),
              ],
            ),
          ),
          // City Cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCityCard(
                  imageUrl:
                      'https://example.com/casablanca.jpg', // Replace with actual image URL
                  cityName: 'Casablanca',
                  distance: '300km',
                ),
                const SizedBox(height: 16),
                _buildCityCard(
                  imageUrl:
                      'https://example.com/tanger.jpg', // Replace with actual image URL
                  cityName: 'Tanger',
                  distance: '250km',
                ),
                const SizedBox(height: 16),
                _buildCityCard(
                  imageUrl:
                      'https://example.com/marrakech.jpg', // Replace with actual image URL
                  cityName: 'Marrakech',
                  distance: '400km',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityCard({
    required String imageUrl,
    required String cityName,
    required String distance,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cityName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      distance,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const Icon(Icons.favorite_border, color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }
}