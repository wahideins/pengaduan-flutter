import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/pengaduan.dart';
import 'supabase_service.dart';

class FirebaseService {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('pengaduan');
  final SupabaseService supabase = SupabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// CREATE
  Future<void> tambahPengaduan({
    required String nama,
    required String alamat,
    required String noTelp,
    required String isiPengaduan,
    File? imageFile,
  }) async {
    final id = const Uuid().v4();
    final userId = _auth.currentUser?.uid ?? 'anonymous';

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await supabase.uploadImage(imageFile);
    }

    final p = Pengaduan(
      id: id,
      userId: userId,
      nama: nama,
      alamat: alamat,
      noTelp: noTelp,
      isiPengaduan: isiPengaduan,
      gambarUrl: imageUrl,
    );

    await _dbRef.child(id).set(p.toMap());
  }

  /// READ -> hanya milik user saat ini
  Stream<List<Pengaduan>> getPengaduanStream() {
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    return _dbRef.onValue.map((event) {
      final snapshot = event.snapshot;
      final val = snapshot.value;
      if (val == null) return <Pengaduan>[];
      final Map<String, dynamic> map = Map<String, dynamic>.from(val as Map);
      final list = <Pengaduan>[];
      map.forEach((key, value) {
        final m = Map<String, dynamic>.from(value);
        if (m['userId'] == userId) {
          list.add(Pengaduan.fromMap(m, key));
        }
      });
      return list.reversed.toList();
    });
  }

  /// UPDATE
  Future<void> updatePengaduan({
    required String id,
    required String nama,
    required String alamat,
    required String noTelp,
    required String isiPengaduan,
    File? newImageFile,
  }) async {
    final snap = await _dbRef.child(id).get();
    String? oldUrl;
    if (snap.exists && snap.value != null) {
      final m = Map<String, dynamic>.from(snap.value as Map);
      oldUrl = (m['gambarUrl'] != null && m['gambarUrl'] != '') ? m['gambarUrl'] : null;
    }

    String? newUrl = oldUrl;
    if (newImageFile != null) {
      newUrl = await supabase.uploadImage(newImageFile);
      if (oldUrl != null && oldUrl.isNotEmpty) {
        await supabase.deleteImageByUrl(oldUrl);
      }
    }

    final updated = {
      'nama': nama,
      'alamat': alamat,
      'noTelp': noTelp,
      'isiPengaduan': isiPengaduan,
      'gambarUrl': newUrl,
    };

    await _dbRef.child(id).update(updated);
  }

  /// DELETE
  Future<void> hapusPengaduan(String id) async {
    final snap = await _dbRef.child(id).get();
    if (snap.exists && snap.value != null) {
      final m = Map<String, dynamic>.from(snap.value as Map);
      final gambarUrl = (m['gambarUrl'] != null && m['gambarUrl'] != '') ? m['gambarUrl'] : null;
      if (gambarUrl != null) {
        await supabase.deleteImageByUrl(gambarUrl);
      }
    }
    await _dbRef.child(id).remove();
  }
}
