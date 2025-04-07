import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/location/location_model.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all locations for a city
  Future<List<Location>> getLocationsForCity(City city, {String? type}) async {
    try {
      Query query = _firestore
          .collection('locations')
          .where('cityId', isEqualTo: city.id);
        
      // Only apply type filter if a specific type is selected
      if (type != null && type.isNotEmpty) {
        query = query.where('type', isEqualTo: type);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Location.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching locations: $e');
      throw Exception('Failed to load locations: $e');
    }
  }

  // Add a new location
  Future<void> addLocation(Location location) async {
    try {
      await _firestore.collection('locations').add(location.toFirestore());
    } catch (e) {
      print('Error adding location: $e');
      throw e;
    }
  }

  // Update a location
  Future<void> updateLocation(String locationId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('locations').doc(locationId).update(data);
    } catch (e) {
      print('Error updating location: $e');
      throw e;
    }
  }

  // Delete a location
  Future<void> deleteLocation(String locationId) async {
    try {
      await _firestore.collection('locations').doc(locationId).delete();
    } catch (e) {
      print('Error deleting location: $e');
      throw e;
    }
  }
}