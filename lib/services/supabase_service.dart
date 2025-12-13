import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> uploadFile(File file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final path = '$folder/$fileName';

      await _client.storage.from('pengaduan').upload(path, file);
      final url = _client.storage.from('pengaduan').getPublicUrl(path);
      return url;
    } catch (e) {
      print('Error upload: $e');
      return null;
    }
  }
}
