import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;
  final String bucket = 'pengaduan'; // BUCKET name di Supabase Storage

  /// Upload file, return publicUrl (String) atau null jika gagal
  Future<String?> uploadImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      // upload
      await _supabase.storage.from(bucket).upload(fileName, file);

      // ambil public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Supabase upload error: $e');
      return null;
    }
  }

  /// Hapus file dari bucket (mengambil nama file dari public URL)
  Future<bool> deleteImageByUrl(String publicUrl) async {
    try {
      // contoh publicUrl: https://.../storage/v1/object/public/pengaduan-images/123.jpg
      final uri = Uri.parse(publicUrl);
      final segments = uri.pathSegments;
      // filename adalah last segment
      final fileName = segments.isNotEmpty ? segments.last : null;
      if (fileName == null) return false;

      final res = await _supabase.storage.from(bucket).remove([fileName]);
      // res akan kosong jika sukses (no exception)
      return true;
    } catch (e) {
      print('Supabase delete error: $e');
      return false;
    }
  }
}
