import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  final String id;
  final String name;
  final String cityId;
  final String address;
  final double rating;
  final GeoPoint location;
  final List<String> imageUrls;
  final String description;
  final String type; // hotel, apartment, hostel
  final String phoneNumber;
  final String website;
  final double pricePerNight;
  final List<String> amenities;
  final int numberOfRooms;
  final bool isAvailable;

  Location({
    required this.id,
    required this.name,
    required this.cityId,
    required this.address,
    required this.rating,
    required this.location,
    required this.imageUrls,
    required this.description,
    required this.type,
    required this.phoneNumber,
    required this.website,
    required this.pricePerNight,
    required this.amenities,
    required this.numberOfRooms,
    this.isAvailable = true,
  });

  factory Location.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Location(
      id: doc.id,
      name: data['name'] ?? '',
      cityId: data['cityId'] ?? '',
      address: data['address'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      location: data['location'] ?? const GeoPoint(0, 0),
      imageUrls:
          (data['imageUrls'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          [],
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      website: data['website'] ?? '',
      pricePerNight: (data['pricePerNight'] ?? 0.0).toDouble(),
      amenities: List<String>.from(data['amenities'] ?? []),
      numberOfRooms: data['numberOfRooms'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  static Location fromMap(Map<String, dynamic> data, String id) {
    return Location(
      id: id,
      name: data['name'] ?? '',
      cityId: data['cityId'] ?? '',
      address: data['address'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      website: data['website'] ?? '',
      pricePerNight: (data['pricePerNight'] ?? 0.0).toDouble(),
      amenities: List<String>.from(data['amenities'] ?? []),
      numberOfRooms: data['numberOfRooms'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'cityId': cityId,
      'address': address,
      'rating': rating,
      'location': location,
      'imageUrls': imageUrls,
      'description': description,
      'type': type,
      'phoneNumber': phoneNumber,
      'website': website,
      'pricePerNight': pricePerNight,
      'amenities': amenities,
      'numberOfRooms': numberOfRooms,
      'isAvailable': isAvailable,
    };
  }
}
