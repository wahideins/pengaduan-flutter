class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String jenisKelamin;
  final String noTelp;
  final DateTime tglLahir;
  final String jalan;
  final String kelurahan;
  final String kecamatan;
  final String NIK;
  final String NOKK; 
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.jenisKelamin,
    required this.noTelp,
    required this.tglLahir,
    required this.jalan,
    required this.kelurahan,
    required this.kecamatan,
    required this.NIK,
    required this.NOKK,
    required this.createdAt,
  });

  /// Mengonversi data menjadi Map untuk dikirim ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'jenisKelamin': jenisKelamin,
      'noTelp': noTelp,
      'tglLahir': tglLahir.toIso8601String(),
      'alamat': {
        'jalan': jalan,
        'kelurahan': kelurahan,
        'kecamatan': kecamatan,
      },
      'NIK': NIK,
      'NOKK': NOKK,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Membuat UserModel dari data Firestore/Realtime DB
  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      jenisKelamin: map['jenisKelamin'] ?? '',
      noTelp: map['noTelp'] ?? '',
      tglLahir: DateTime.tryParse(map['tglLahir'] ?? '') ?? DateTime.now(),
      jalan: map['alamat']?['jalan'] ?? '',
      kelurahan: map['alamat']?['kelurahan'] ?? '',
      kecamatan: map['alamat']?['kecamatan'] ?? '',
      NIK: map['NIK'] ?? '',
      NOKK: map['NOKK'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  UserModel copyWith({String? uid}) {
    return UserModel(
      uid: uid ?? this.uid,
      nama: nama,
      email: email,
      jenisKelamin: jenisKelamin,
      noTelp: noTelp,
      tglLahir: tglLahir,
      jalan: jalan,
      kelurahan: kelurahan,
      kecamatan: kecamatan,
      NIK: NIK,
      NOKK: NOKK,
      createdAt: createdAt,
    );
  }
}
