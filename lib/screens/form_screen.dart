import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pengaduan.dart';
import '../services/firebase_service.dart';
import '../services/supabase_service.dart';
import 'map_picker.dart';
import 'package:geocoding/geocoding.dart' as geo;

class FormPengaduanScreen extends StatefulWidget {
  const FormPengaduanScreen({super.key});

  @override
  State<FormPengaduanScreen> createState() => _FormPengaduanScreenState();
}

class _FormPengaduanScreenState extends State<FormPengaduanScreen> {
  PengaduanVisibility _visibility = PengaduanVisibility.publik;
  final _formKey = GlobalKey<FormState>();
  final _isiController = TextEditingController();
  final _lokasiController = TextEditingController();
  File? _gambarFile;
  File? _videoFile;
  bool _loading = false;

  final _firebaseService = FirebaseService();
  final _supabaseService = SupabaseService();
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final info = await _firebaseService.getCurrentUserProfile();
    setState(() {
      _userInfo = info;
    });
  }



Future<String> _getAddressFromLatLng(double lat, double lng) async {
  try {
    final placemarks = await geo.placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final jalan = place.street ?? '';
      final kelurahan = place.subLocality ?? '';
      final kecamatan = place.locality ?? '';
      const kota = 'Kediri';
      const negara = 'Indonesia';

      return '$jalan, $kelurahan, $kecamatan, $kota, $negara';
    }
  } catch (e) {
    debugPrint('Error reverse geocoding: $e');
  }
  return 'Alamat tidak ditemukan';
}


  // ======== PILIH GAMBAR / VIDEO ========
  Future<void> _showSourceDialog({required bool isImage}) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isImage ? 'Pilih Sumber Gambar' : 'Pilih Sumber Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile(isImage, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile(isImage, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(bool isImage, ImageSource source) async {
    final picker = ImagePicker();
    final picked = isImage
        ? await picker.pickImage(source: source, imageQuality: 80)
        : await picker.pickVideo(source: source);

    if (picked != null) {
      setState(() {
        if (isImage) {
          _gambarFile = File(picked.path);
        } else {
          _videoFile = File(picked.path);
        }
      });
    }
  }

  // ======== LOKASI ========
  Future<void> _showLocationOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('Gunakan Lokasi Saat Ini'),
            onTap: () async {
              Navigator.pop(ctx);
              await _getCurrentLocation();
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Pilih di Peta'),
            onTap: () async {
              Navigator.pop(ctx);
              final picked = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapPickerScreen()),
              );
              if (picked != null) {
                setState(() => _lokasiController.text = picked);
              }
            },
          ),
        ],
      ),
    );
  }

Future<void> _getCurrentLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan lokasi tidak aktif')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi ditolak permanen')),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    final alamatLengkap =
        await _getAddressFromLatLng(position.latitude, position.longitude);

    setState(() {
      _lokasiController.text = alamatLengkap;
    });
  } catch (e) {
    debugPrint('Gagal mendapatkan lokasi: $e');
  }
}



  // ======== SUBMIT ========
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser!;
    String? gambarUrl;
    String? videoUrl;

    if (_gambarFile != null) {
      gambarUrl = await _supabaseService.uploadFile(_gambarFile!, 'gambar');
    }
    if (_videoFile != null) {
      videoUrl = await _supabaseService.uploadFile(_videoFile!, 'video');
    }

    final alamatLengkap = _userInfo != null
        ? '${_userInfo!['alamat']['jalan']}, ${_userInfo!['alamat']['kelurahan']}, ${_userInfo!['alamat']['kecamatan']}, Kediri, Indonesia'
        : 'Alamat tidak tersedia';

    final pengaduan = Pengaduan(
      userId: user.uid,
      nama: _userInfo?['nama'] ?? user.displayName ?? 'Tanpa Nama',
      alamat: alamatLengkap,
      noTelp: _userInfo?['noTelp'] ?? user.phoneNumber ?? '-',
      isiPengaduan: _isiController.text.trim(),
      gambarUrl: gambarUrl,
      videoUrl: videoUrl,
      lokasi: _lokasiController.text.trim().isEmpty ? null : _lokasiController.text.trim(),
      createdAt: DateTime.now(),
      visibility: _visibility,
    );

    await _firebaseService.tambahPengaduan(pengaduan);
    setState(() => _loading = false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaduan berhasil dikirim!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Form Pengaduan')),
      body: _userInfo == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi Pengguna',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Nama: ${_userInfo?['nama'] ?? user?.displayName ?? 'Tanpa Nama'}'),
                            Text('No. Telp: ${_userInfo?['noTelp'] ?? user?.phoneNumber ?? '-'}'),
                            Text(
                              'Alamat: ${_userInfo?['alamat']?['jalan'] ?? '-'}, '
                              '${_userInfo?['alamat']?['kelurahan'] ?? '-'}, '
                              '${_userInfo?['alamat']?['kecamatan'] ?? '-'}, Kediri, Indonesia',
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _isiController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Isi Pengaduan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Harus diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    // Lokasi dengan tombol pilih
                    TextFormField(
                      controller: _lokasiController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Lokasi',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.location_on),
                          onPressed: _showLocationOptions,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showSourceDialog(isImage: true),
                          icon: const Icon(Icons.image),
                          label: const Text('Upload Gambar'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _showSourceDialog(isImage: false),
                          icon: const Icon(Icons.videocam),
                          label: const Text('Upload Video'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      'Status Pengaduan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    RadioListTile<PengaduanVisibility>(
                      title: const Text('Publik (dapat dilihat semua pengguna)'),
                      value: PengaduanVisibility.publik,
                      groupValue: _visibility,
                      onChanged: (value) {
                        setState(() {
                          _visibility = value!;
                        });
                      },
                    ),

                    RadioListTile<PengaduanVisibility>(
                      title: const Text('Privat (hanya pelapor & admin)'),
                      value: PengaduanVisibility.privat,
                      groupValue: _visibility,
                      onChanged: (value) {
                        setState(() {
                          _visibility = value!;
                        });
                      },
                    ),

                    if (_gambarFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Image.file(_gambarFile!, height: 120, fit: BoxFit.cover),
                      ),
                    if (_videoFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text('Video: ${_videoFile!.path.split('/').last}'),
                      ),
                    const SizedBox(height: 24),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.send),
                            label: const Text('Kirim Pengaduan'),
                          ),
                  ],
                  
                ),
                
              ),
            ),
    );
  }
}
