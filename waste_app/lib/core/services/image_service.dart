import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from the gallery
  Future<XFile?> pickImage() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  /// Pick an image from the camera
  Future<XFile?> pickImageFromCamera() async {
    return await _picker.pickImage(source: ImageSource.camera);
  }

  /// Compress and convert image to Base64 string
  /// Ensures the result is under 1MB
  Future<String?> compressAndConvert(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize if width > 800px to save space
      if (image.width > 800) {
        image = img.copyResize(image, width: 800);
      }

      // Encode to JPG with 70% quality
      List<int> compressedBytes = img.encodeJpg(image, quality: 70);

      // If still > 1MB, try 50% quality
      if (compressedBytes.length > 1024 * 1024) {
        compressedBytes = img.encodeJpg(image, quality: 50);
      }

      // Final check
      if (compressedBytes.length > 1024 * 1024) {
        throw Exception("Document size exceeds 1MB limit even after compression. Please upload a smaller file.");
      }

      return base64Encode(compressedBytes);
    } catch (e) {
      throw Exception("Failed to process image: $e");
    }
  }

  /// Helper to pick from camera and convert in one step
  Future<String?> pickFromCameraAndConvert() async {
    final file = await pickImageFromCamera();
    if (file == null) return null;
    return await compressAndConvert(file);
  }

  /// Helper to pick from gallery and convert in one step
  Future<String?> pickFromGalleryAndConvert() async {
    final file = await pickImage();
    if (file == null) return null;
    return await compressAndConvert(file);
  }
}
