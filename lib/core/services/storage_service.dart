import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfileImage(XFile file, String uid) async {
    try {
      final String fileName = 'profile_$uid${path.extension(file.path)}';
      final Reference ref = _storage.ref().child('profile_images/$fileName');

      // Use putData with Metadata for robustness (like ProfileScreen)
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final bytes = await file.readAsBytes();

      final UploadTask uploadTask = ref.putData(bytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // // print("Error uploading image: $e");
      return null;
    }
  }
}
