import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_services.dart';
import 'dart:typed_data';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();

  // Controllers
  final _nama = TextEditingController();
  final _alamatJalan = TextEditingController();
  final _kelDesa = TextEditingController();
  final _noTelp = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  // NEW controllers
  final _nik = TextEditingController();
  final _noKk = TextEditingController();

  String? _selectedKecamatan;
  String? _jenisKelamin;
  DateTime? _tglLahir;
  bool _setuju = false;
  bool _konfirmasi = false;
  bool _loading = false;
  int _currentStep = 0;

  final List<String> kelurahanMojoroto = [
    'Bandar Lor', 'Bandar Kidul', 'Campurejo', 'Mojoroto',
    'Tosaren', 'Tempurejo', 'Pojok',
  ];
  final List<String> kecamatanList = ['Mojoroto', 'Kota', 'Pesantren'];

  static const String _demoAesKey = '0123456789abcdef0123456789abcdef';

  Future<void> _pilihTanggal(BuildContext context) async {
    final tgl = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 1, 1),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (tgl != null) setState(() => _tglLahir = tgl);
  }

  encrypt.IV _generateIV() {
    final rnd = Random.secure();
    final ivBytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return encrypt.IV(Uint8List.fromList(ivBytes));
  }

  // Encrypt plain text -> returns "base64(iv):base64(ciphertext)"
  String _encryptField(String plain) {
    final key = encrypt.Key.fromUtf8(_demoAesKey);
    final iv = _generateIV();
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plain, iv: iv);
    final ivB64 = base64UrlEncode(iv.bytes);
    final ctB64 = base64UrlEncode(encrypted.bytes);
    return '$ivB64:$ctB64';
  }


  String _decryptField(String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return '';
    final iv = encrypt.IV(base64Url.decode(parts[0]));
    final cipherBytes = base64Url.decode(parts[1]);
    final key = encrypt.Key.fromUtf8(_demoAesKey);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypt.Encrypted(Uint8List.fromList(cipherBytes));
    final plain = encrypter.decrypt(encrypted, iv: iv);
    return plain;
  }

  Future<void> _register() async {
    if (!_setuju || !_konfirmasi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap centang semua persetujuan.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Validasi minimal
      if (_nik.text.isEmpty || _noKk.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NIK dan NO KK harus diisi.')),
        );
        setState(() => _loading = false);
        return;
      }

      // Enkripsi NIK dan NO KK sebelum disimpan / dikirim ke Firebase
      final encryptedNik = _encryptField(_nik.text.trim());
      final encryptedNoKk = _encryptField(_noKk.text.trim());

      final user = UserModel(
        uid: '',
        nama: _nama.text.trim(),
        email: _email.text.trim(),
        jenisKelamin: _jenisKelamin ?? '',
        noTelp: _noTelp.text.trim(),
        tglLahir: _tglLahir!,
        jalan: _alamatJalan.text.trim(),
        kelurahan: _kelDesa.text.trim(),
        kecamatan: _selectedKecamatan ?? '',
        // NEW: simpan versi terenkripsi
        NIK: encryptedNik,
        NOKK: encryptedNoKk,
        createdAt: DateTime.now(),
      );

      await _authService.registerUser(user, _pass.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Silakan verifikasi email Anda.'),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildStep1() {
    return Column(
      children: [
        TextField(controller: _nama, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
        // NEW fields: NIK & NO KK
        const SizedBox(height: 8),
        TextField(
          controller: _nik,
          decoration: const InputDecoration(labelText: 'NIK'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noKk,
          decoration: const InputDecoration(labelText: 'NO KK'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        TextField(controller: _alamatJalan, decoration: const InputDecoration(labelText: 'Alamat Jalan')),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (value) => value.text.isEmpty
              ? const Iterable<String>.empty()
              : kelurahanMojoroto.where((kel) => kel.toLowerCase().contains(value.text.toLowerCase())),
          onSelected: (val) => _kelDesa.text = val,
          fieldViewBuilder: (context, controller, focusNode, onSubmit) {
            controller.text = _kelDesa.text;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(labelText: 'Kel/Desa'),
            );
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedKecamatan,
          hint: const Text('Pilih Kecamatan'),
          items: kecamatanList
              .map((kec) => DropdownMenuItem(value: kec, child: Text(kec)))
              .toList(),
          onChanged: (val) => setState(() => _selectedKecamatan = val),
        ),
        const SizedBox(height: 8),
        const Text('Jenis Kelamin'),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Laki-laki'),
                value: 'Laki-laki',
                groupValue: _jenisKelamin,
                onChanged: (val) => setState(() => _jenisKelamin = val),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Perempuan'),
                value: 'Perempuan',
                groupValue: _jenisKelamin,
                onChanged: (val) => setState(() => _jenisKelamin = val),
              ),
            ),
          ],
        ),
        TextField(
          controller: _noTelp,
          decoration: const InputDecoration(labelText: 'No. Telepon'),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _tglLahir == null
                    ? 'Tanggal Lahir: Belum dipilih'
                    : 'Tanggal Lahir: ${_tglLahir!.day}/${_tglLahir!.month}/${_tglLahir!.year}',
              ),
            ),
            TextButton(onPressed: () => _pilihTanggal(context), child: const Text('Pilih')),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () {
              if (_nama.text.isEmpty ||
                  _alamatJalan.text.isEmpty ||
                  _kelDesa.text.isEmpty ||
                  _selectedKecamatan == null ||
                  _jenisKelamin == null ||
                  _noTelp.text.isEmpty ||
                  _tglLahir == null ||
                  _nik.text.isEmpty ||
                  _noKk.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lengkapi semua biodata.')),
                );
              } else {
                setState(() => _currentStep = 1);
              }
            },
            child: const Text('Lanjut'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
        CheckboxListTile(
          value: _setuju,
          onChanged: (v) => setState(() => _setuju = v!),
          title: const Text('Setuju dengan syarat & ketentuan.'),
        ),
        CheckboxListTile(
          value: _konfirmasi,
          onChanged: (v) => setState(() => _konfirmasi = v!),
          title: const Text('Biodata saya benar.'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(onPressed: () => setState(() => _currentStep = 0), child: const Text('Kembali')),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _register, child: const Text('Daftar')),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_currentStep == 0 ? 'Biodata' : 'Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
      ),
    );
  }
}
