import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/pengaduan.dart';

class FirebaseService {
  final _db = FirebaseDatabase.instance.ref('pengaduan');
  final _auth = FirebaseAuth.instance;
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref('users');

  /// 🟢 Tambah pengaduan baru, otomatis ambil data user login
  Future<void> tambahPengaduan(Pengaduan pengaduan) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User belum login');

    // Ambil profil user
    final userProfileSnap = await _userRef.child(user.uid).get();
    if (!userProfileSnap.exists) {
      throw Exception('Profil pengguna tidak ditemukan');
    }

    final userProfile = Map<String, dynamic>.from(userProfileSnap.value as Map);

    // Format alamat lengkap
    final alamatLengkap =
        '${userProfile['alamat']['jalan']}, ${userProfile['alamat']['kelurahan']}, ${userProfile['alamat']['kecamatan']}, Kediri, Indonesia';

    // Buat instance baru pengaduan dengan data user
    final newPengaduan = Pengaduan(
      userId: user.uid,
      nama: userProfile['nama'] ?? user.displayName ?? 'Tanpa Nama',
      alamat: alamatLengkap,
      noTelp: userProfile['noTelp'] ?? user.phoneNumber ?? '-',
      isiPengaduan: pengaduan.isiPengaduan,
      gambarUrl: pengaduan.gambarUrl,
      videoUrl: pengaduan.videoUrl,
      lokasi: pengaduan.lokasi,
      status: pengaduan.status ?? 'proses',
      visibility: pengaduan.visibility,
      createdAt: DateTime.now(),
    );

    await _db.push().set(newPengaduan.toMap());
  }

  
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _userRef.child(user.uid).get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  Stream<List<Pengaduan>> getPengaduanUser() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _db.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.entries
          .map((e) => Pengaduan.fromMap(Map<String, dynamic>.from(e.value), e.key))
          .where((p) => p.userId == userId)
          .toList();
    });
  }

  Future<void> hapusPengaduan(String id) async {
    await _db.child(id).remove();
  }
}
