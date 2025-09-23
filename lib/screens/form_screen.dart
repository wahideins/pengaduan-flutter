import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';
import '../models/pengaduan.dart';

class FormScreen extends StatefulWidget {
  final Pengaduan? pengaduan; // null = create, non-null = edit
  const FormScreen({super.key, this.pengaduan});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirebaseService();

  late TextEditingController _nama;
  late TextEditingController _alamat;
  late TextEditingController _telp;
  late TextEditingController _isi;
  File? _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.pengaduan?.nama ?? '');
    _alamat = TextEditingController(text: widget.pengaduan?.alamat ?? '');
    _telp = TextEditingController(text: widget.pengaduan?.noTelp ?? '');
    _isi = TextEditingController(text: widget.pengaduan?.isiPengaduan ?? '');
  }

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _telp.dispose();
    _isi.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (widget.pengaduan == null) {
        // create
        await _service.tambahPengaduan(
          nama: _nama.text.trim(),
          alamat: _alamat.text.trim(),
          noTelp: _telp.text.trim(),
          isiPengaduan: _isi.text.trim(),
          imageFile: _image,
        );
      } else {
        // update
        await _service.updatePengaduan(
          id: widget.pengaduan!.id!,
          nama: _nama.text.trim(),
          alamat: _alamat.text.trim(),
          noTelp: _telp.text.trim(),
          isiPengaduan: _isi.text.trim(),
          newImageFile: _image,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pengaduan != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Pengaduan' : 'Tambah Pengaduan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nama,
                    decoration: const InputDecoration(labelText: 'Nama'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib' : null,
                  ),
                  TextFormField(
                    controller: _alamat,
                    decoration: const InputDecoration(labelText: 'Alamat'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Alamat wajib' : null,
                  ),
                  TextFormField(
                    controller: _telp,
                    decoration: const InputDecoration(labelText: 'No Telp'),
                    validator: (v) => (v == null || v.isEmpty) ? 'No Telp wajib' : null,
                  ),
                  TextFormField(
                    controller: _isi,
                    decoration: const InputDecoration(labelText: 'Isi Pengaduan'),
                    maxLines: 4,
                    validator: (v) => (v == null || v.isEmpty) ? 'Isi wajib' : null,
                  ),
                  const SizedBox(height: 12),
                  _image != null
                      ? Image.file(_image!, height: 180, fit: BoxFit.cover)
                      : (widget.pengaduan?.gambarUrl != null
                          ? Image.network(widget.pengaduan!.gambarUrl!, height: 180, fit: BoxFit.cover)
                          : const Text('Tidak ada gambar')),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pilih Gambar (opsional)'),
                  ),
                  const SizedBox(height: 16),
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(onPressed: _save, child: Text(isEdit ? 'Update' : 'Simpan')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
