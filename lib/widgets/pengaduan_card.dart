import 'package:flutter/material.dart';
import '../models/pengaduan.dart';
import '../screens/detail_screen.dart';
import '../services/firebase_service.dart';

class PengaduanCard extends StatelessWidget {
  final Pengaduan pengaduan;
  final FirebaseService _service = FirebaseService();

  PengaduanCard({super.key, required this.pengaduan});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: pengaduan.gambarUrl != null
            ? Image.network(pengaduan.gambarUrl!, width: 60, height: 60, fit: BoxFit.cover)
            : const Icon(Icons.report, size: 40),
        title: Text(pengaduan.nama),
        subtitle: Text(pengaduan.isiPengaduan, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Hapus'),
                content: const Text('Yakin ingin menghapus?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                ],
              ),
            );
            if (ok == true) {
              if (pengaduan.id != null) await _service.hapusPengaduan(pengaduan.id!);
            }
          },
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(pengaduan: pengaduan)));
        },
      ),
    );
  }
}
