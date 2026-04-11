import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/adherence_log_model.dart';

class AdherenceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _adherenceCollection() {
    return _db.collection('adherence_logs'); 
  }

  // Location helper
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    } 

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Strict log WITHOUT storage upload
  Future<void> logAdherenceStrict({
    required String patientId,
    required String medicineId,
    required String scheduledTime,
    required File photoFile,
  }) async {
    try {
      // 1. Verify photo is captured
      if (!photoFile.existsSync()) {
        throw Exception('Image proof is required');
      }

      // 2. Get Location
      Position? position;
      try {
        position = await _determinePosition();
      } catch (e) {
        print("Location fetch failed: $e");
      }

      // 3. Save to Firestore (metadata only, no upload)
      await _adherenceCollection().add({
        'patientId': patientId,
        'medicineId': medicineId,
        'taken': true,
        'scheduledTime': scheduledTime,
        'timestamp': FieldValue.serverTimestamp(),
        'proofImageUrl': '', // Empty string as per zero-cost requirement
        'location': {
          'latitude': position?.latitude ?? 0.0,
          'longitude': position?.longitude ?? 0.0,
        }
      });
    } catch (e) {
      print("Error logging adherence: $e");
      rethrow;
    }
  }

  // Get recent logs based on patientId
  Stream<List<AdherenceLogModel>> getRecentLogs(String patientId) {
    return _adherenceCollection()
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdherenceLogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
