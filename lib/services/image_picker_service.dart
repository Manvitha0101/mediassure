// services/image_picker_service.dart
// Provides camera and gallery image picking functionality.
// Uses: image_picker package

import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  // Pick image from camera
  Future<File?> pickFromCamera() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // keep medium quality to reduce Firestore payload size
      maxWidth: 600,     // constrain dimensions to be even more memory safe
      maxHeight: 600,    // 
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // Pick image from gallery
  Future<File?> pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // Retrieve lost data (for Android Activity destruction)
  Future<LostDataResponse> retrieveLostData() async {
    return await _picker.retrieveLostData();
  }
}