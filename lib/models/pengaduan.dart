class Pengaduan {
  String? id;
  String userId; // 🔑 untuk identifikasi pemilik
  String nama;
  String alamat;
  String noTelp;
  String isiPengaduan;
  String? gambarUrl;

  Pengaduan({
    this.id,
    required this.userId,
    required this.nama,
    required this.alamat,
    required this.noTelp,
    required this.isiPengaduan,
    this.gambarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nama': nama,
      'alamat': alamat,
      'noTelp': noTelp,
      'isiPengaduan': isiPengaduan,
      'gambarUrl': gambarUrl,
    };
  }

  factory Pengaduan.fromMap(Map<dynamic, dynamic> map, String id) {
    return Pengaduan(
      id: id,
      userId: map['userId'] ?? '',
      nama: map['nama'] ?? '',
      alamat: map['alamat'] ?? '',
      noTelp: map['noTelp'] ?? '',
      isiPengaduan: map['isiPengaduan'] ?? '',
      gambarUrl: map['gambarUrl'],
    );
  }
}
