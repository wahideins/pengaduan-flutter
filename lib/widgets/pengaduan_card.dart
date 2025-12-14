import 'package:flutter/material.dart';
import '../models/pengaduan.dart';
import '../screens/detail_screen.dart';
import '../services/firebase_service.dart';
import '../extension/pengaduan_visibility_ext.dart';

class PengaduanCard extends StatelessWidget {
  final Pengaduan pengaduan;
  final bool editable;

  final FirebaseService _service = FirebaseService();

  PengaduanCard({
    super.key,
    required this.pengaduan,
    this.editable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: pengaduan.gambarUrl != null
            ? Image.network(
                pengaduan.gambarUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.report, size: 40, color: Colors.redAccent),

        title: Text(
          pengaduan.isiPengaduan,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pengaduan.createdAt
                  .toLocal()
                  .toString()
                  .split('.')[0],
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              pengaduan.visibility.label,
              style: TextStyle(
                fontSize: 12,
                color: pengaduan.visibility.color,
              ),
            ),
          ],
        ),

        // 🔥 INI KUNCI UTAMA
        trailing: editable
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      // nanti arahkan ke halaman edit
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Hapus Pengaduan'),
                          content: const Text('Yakin ingin menghapus?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );

                      if (ok == true && pengaduan.id != null) {
                        await _service.hapusPengaduan(pengaduan.id!);
                      }
                    },
                  ),
                ],
              )
            : null,

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DetailPengaduanScreen(pengaduan: pengaduan),
            ),
          );
        },
      ),
    );
  }
}
