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
      imageQuality: 80, // compress to reduce upload size
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
}