import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class StorageService {
  final _supabase = Supabase.instance.client;

  Future<String?> uploadProfileImage(XFile file, String uid) async {
    try {
      final ext = file.path.contains('.') ? '.${file.path.split('.').last}' : '';
      final String fileName = 'profile_$uid$ext';
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
      if (kDebugMode) debugPrint("Error uploading image: $e");
      return null;
    }
  }
}
