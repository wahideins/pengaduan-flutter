import 'package:flutter/material.dart';
import '../models/pengaduan.dart';
import '../services/firebase_service.dart';
import 'form_screen.dart';

class DetailScreen extends StatelessWidget {
  final Pengaduan pengaduan;
  final FirebaseService _service = FirebaseService();

  DetailScreen({super.key, required this.pengaduan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pengaduan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FormScreen(pengaduan: pengaduan)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Hapus'),
                  content: const Text('Yakin ingin menghapus pengaduan ini?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),

                  ],
                ),
              );
              if (ok == true) {
                await _service.hapusPengaduan(pengaduan.id!);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Nama: ${pengaduan.nama}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Alamat: ${pengaduan.alamat}'),
            const SizedBox(height: 8),
            Text('No Telp: ${pengaduan.noTelp}'),
            const SizedBox(height: 12),
            const Text('Isi Pengaduan:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(pengaduan.isiPengaduan),
            const SizedBox(height: 16),
            if (pengaduan.gambarUrl != null)
              Image.network(pengaduan.gambarUrl!, height: 220, fit: BoxFit.cover)
            else
              const Text('Tidak ada gambar'),
          ],
        ),
      ),
    );
  }
}
