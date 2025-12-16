import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> uploadFile(File file, String folder) async {
    try {
      if (!file.existsSync()) {
        print('❌ File tidak ditemukan');
        return null;
      }

      final Uint8List bytes = await file.readAsBytes();
      final ext = p.extension(file.path).toLowerCase();

      final fileName =
          '$folder/${DateTime.now().millisecondsSinceEpoch}$ext';

      final contentType = _getContentType(ext);

      await _client.storage.from('pengaduan').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final publicUrl =
          _client.storage.from('pengaduan').getPublicUrl(fileName);

      print('✅ Upload sukses: $publicUrl');
      return publicUrl;
    } catch (e, s) {
      print('❌ Upload error: $e');
      print(s);
      return null;
    }
  }

  String _getContentType(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}
