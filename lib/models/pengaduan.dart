enum PengaduanVisibility {
  publik,
  privat,
}

class Pengaduan {
  final String? id;
  final String userId;
  final String nama;
  final String alamat;
  final String noTelp;
  final String isiPengaduan;
  final String? gambarUrl;
  final String? videoUrl;
  final String? lokasi;
  final DateTime createdAt;
  final String? status; // proses, selesai, dll
  final PengaduanVisibility visibility; 

  Pengaduan({
    this.id,
    required this.userId,
    required this.nama,
    required this.alamat,
    required this.noTelp,
    required this.isiPengaduan,
    this.gambarUrl,
    this.videoUrl,
    this.lokasi,
    required this.createdAt,
    this.status,
    required this.visibility,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nama': nama,
      'alamat': alamat,
      'noTelp': noTelp,
      'isiPengaduan': isiPengaduan,
      'gambarUrl': gambarUrl,
      'videoUrl': videoUrl,
      'lokasi': lokasi,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'visibility': visibility.name, // simpan sebagai string
    };
  }

  factory Pengaduan.fromMap(Map<String, dynamic> map, String id) {
    return Pengaduan(
      id: id,
      userId: map['userId'] ?? '',
      nama: map['nama'] ?? '',
      alamat: map['alamat'] ?? '',
      noTelp: map['noTelp'] ?? '',
      isiPengaduan: map['isiPengaduan'] ?? '',
      gambarUrl: map['gambarUrl'],
      videoUrl: map['videoUrl'],
      lokasi: map['lokasi'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'proses',
      visibility: map['visibility'] == 'privat'
          ? PengaduanVisibility.privat
          : PengaduanVisibility.publik, // default publik
    );
  }
}
