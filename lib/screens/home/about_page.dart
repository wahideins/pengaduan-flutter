import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:encrypt/encrypt.dart' as encrypt;

import '../../../models/user.dart';
import '../../services/firebase_service.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  bool _showSensitiveData = false;

  /// 🔑 DEMO KEY (samakan dengan yang dipakai saat encrypt)
  static const String _demoAesKey = '0123456789abcdef0123456789abcdef';

  String _decryptField(String stored) {
    try {
      final parts = stored.split(':');
      if (parts.length != 2) return '';
      final iv = encrypt.IV(base64Url.decode(parts[0]));
      final cipherBytes = base64Url.decode(parts[1]);
      final key = encrypt.Key.fromUtf8(_demoAesKey);
      final encrypter =
          encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final encrypted =
          encrypt.Encrypted(Uint8List.fromList(cipherBytes));
      final plain = encrypter.decrypt(encrypted, iv: iv);
      return plain;
    } catch (e) {
      return 'Gagal decrypt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = fbAuth.FirebaseAuth.instance.currentUser;
    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Akun Saya')),
      body: user == null
          ? const Center(child: Text('Anda belum login.'))
          : FutureBuilder<Map<String, dynamic>?>(
              future: firebaseService.getCurrentUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                      child: Text('Data pengguna tidak ditemukan'));
                }

                final userModel =
                    UserModel.fromMap(snapshot.data!);

                final nik = _showSensitiveData
                    ? _decryptField(userModel.NIK)
                    : userModel.NIK;
                final kk = _showSensitiveData
                    ? _decryptField(userModel.NOKK)
                    : userModel.NOKK;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      /// ================= BIODATA =================
                      const Text(
                        'Biodata Pengguna',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Card(
                        child: Column(
                          children: [
                            _item(Icons.person, 'Nama',
                                userModel.nama),
                            _item(Icons.wc, 'Jenis Kelamin',
                                userModel.jenisKelamin),
                            _item(Icons.phone, 'No. Telepon',
                                userModel.noTelp),
                            _item(
                              Icons.cake,
                              'Tanggal Lahir',
                              _formatDate(
                                  userModel.tglLahir),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// ================= ALAMAT =================
                      Card(
                        child: Column(
                          children: [
                            _item(Icons.home, 'Jalan',
                                userModel.jalan),
                            _item(Icons.location_city,
                                'Kelurahan',
                                userModel.kelurahan),
                            _item(Icons.map, 'Kecamatan',
                                userModel.kecamatan),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// ================= IDENTITAS =================
                      Card(
                        child: Column(
                          children: [
                            _item(Icons.credit_card, 'NIK', nik),
                            _item(Icons.family_restroom,
                                'No. KK', kk),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// ================= BUTTON DECRYPT =================
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showSensitiveData =
                                !_showSensitiveData;
                          });
                        },
                        icon: Icon(_showSensitiveData
                            ? Icons.visibility_off
                            : Icons.visibility),
                        label: Text(_showSensitiveData
                            ? 'Sembunyikan Data Sensitif'
                            : 'Tampilkan Data Sensitif'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _showSensitiveData
                                  ? Colors.red
                                  : Colors.blue,
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }

  /// ================= HELPER =================
  Widget _item(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value.isEmpty ? '-' : value),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }
}
