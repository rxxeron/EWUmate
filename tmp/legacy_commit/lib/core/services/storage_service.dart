import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final _supabase = Supabase.instance.client;

  Future<String?> uploadProfileImage(XFile file, String uid) async {
    try {
      final String fileName = 'profile_$uid${path.extension(file.path)}';
      final bytes = await file.readAsBytes();

      // Ensure you have a bucket named 'profile-images' with public access
      await _supabase.storage.from('profile_images').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl =
          _supabase.storage.from('profile_images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }
}
