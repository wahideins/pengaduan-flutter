import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:image_picker/image_picker.dart';

import '../models/pengaduan.dart';
import '../services/firebase_service.dart';
import '../services/supabase_service.dart';
import './home/camera_x_screen.dart';
import 'map_picker.dart';

enum MediaSource { camera, gallery }

class FormPengaduanScreen extends StatefulWidget {
  final File? initialImage;
  final File? initialVideo;

  const FormPengaduanScreen({
    super.key,
    this.initialImage,
    this.initialVideo,
  });

  @override
  State<FormPengaduanScreen> createState() => _FormPengaduanScreenState();
}

class _FormPengaduanScreenState extends State<FormPengaduanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _isiController = TextEditingController();
  final _lokasiController = TextEditingController();

  final _firebaseService = FirebaseService();
  final _supabaseService = SupabaseService();
  final _picker = ImagePicker();

  File? _gambarFile;
  File? _videoFile;
  bool _loading = false;

  PengaduanVisibility _visibility = PengaduanVisibility.publik;
  Map<String, dynamic>? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    _gambarFile = widget.initialImage;
    _videoFile = widget.initialVideo;
  }

  Future<void> _loadUserInfo() async {
    final info = await _firebaseService.getCurrentUserProfile();
    if (mounted) setState(() => _userInfo = info);
  }

  /// ================= MEDIA HANDLER =================
  void _handleMediaSelection(MediaSource source, bool isVideo) {
    if (source == MediaSource.camera) {
      _openCamera(isVideo: isVideo);
    } else {
      _pickFromGallery(isVideo: isVideo);
    }
  }

  /// ================= CAMERA X =================
  Future<void> _openCamera({required bool isVideo}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraXScreen(enableVideo: isVideo),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (result['type'] == 'image') {
          _gambarFile = result['file'];
        } else if (result['type'] == 'video') {
          _videoFile = result['file'];
        }
      });
    }
  }

  /// ================= GALLERY =================
Future<void> _pickFromGallery({required bool isVideo}) async {
  XFile? picked;

  if (isVideo) {
    picked = await _picker.pickVideo(
      source: ImageSource.gallery,
    );
  } else {
    picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }

  if (picked != null && mounted) {
    setState(() {
      if (isVideo) {
        _videoFile = File(picked!.path);
      } else {
        _gambarFile = File(picked!.path);
      }
    });
  }
}


  /// ================= LOKASI =================
  Future<String> _getAddress(double lat, double lng) async {
    final placemarks = await geo.placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      return '${p.street}, ${p.subLocality}, ${p.locality}, Kediri, Indonesia';
    }
    return 'Alamat tidak ditemukan';
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    final pos = await Geolocator.getCurrentPosition();
    final alamat = await _getAddress(pos.latitude, pos.longitude);
    setState(() => _lokasiController.text = alamat);
  }

  void _showLocationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('Gunakan Lokasi Saat Ini'),
            onTap: () async {
              Navigator.pop(context);
              await _getCurrentLocation();
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Pilih di Peta'),
            onTap: () async {
              Navigator.pop(context);
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

  /// ================= SUBMIT =================
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

    final pengaduan = Pengaduan(
      userId: user.uid,
      nama: _userInfo?['nama'] ?? 'Tanpa Nama',
      alamat: _lokasiController.text,
      noTelp: _userInfo?['noTelp'] ?? '-',
      isiPengaduan: _isiController.text.trim(),
      gambarUrl: gambarUrl,
      videoUrl: videoUrl,
      lokasi: _lokasiController.text,
      createdAt: DateTime.now(),
      visibility: _visibility,
    );

    await _firebaseService.tambahPengaduan(pengaduan);

    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaduan berhasil dikirim')),
      );
      Navigator.pop(context);
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
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
                    /// ISI
                    TextFormField(
                      controller: _isiController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Isi Pengaduan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),

                    const SizedBox(height: 12),

                    /// LOKASI
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

                    /// MEDIA BUTTON
                    Row(
                      children: [
                        PopupMenuButton<MediaSource>(
                          onSelected: (v) =>
                              _handleMediaSelection(v, false),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: MediaSource.camera,
                              child: ListTile(
                                leading: Icon(Icons.camera),
                                title: Text('Kamera'),
                              ),
                            ),
                            PopupMenuItem(
                              value: MediaSource.gallery,
                              child: ListTile(
                                leading: Icon(Icons.photo_library),
                                title: Text('Galeri'),
                              ),
                            ),
                          ],
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.image),
                            label: const Text('Foto'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        PopupMenuButton<MediaSource>(
                          onSelected: (v) =>
                              _handleMediaSelection(v, true),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: MediaSource.camera,
                              child: ListTile(
                                leading: Icon(Icons.videocam),
                                title: Text('Kamera'),
                              ),
                            ),
                            PopupMenuItem(
                              value: MediaSource.gallery,
                              child: ListTile(
                                leading: Icon(Icons.video_library),
                                title: Text('Galeri'),
                              ),
                            ),
                          ],
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.videocam),
                            label: const Text('Video'),
                          ),
                        ),
                      ],
                    ),

                    if (_gambarFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Image.file(_gambarFile!, height: 120),
                      ),

                    if (_videoFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Video: ${_videoFile!.path.split('/').last}',
                        ),
                      ),

                    const SizedBox(height: 20),

                    /// SUBMIT
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
