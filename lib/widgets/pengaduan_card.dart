import 'package:flutter/material.dart';
import '../models/pengaduan.dart';
import '../screens/detail_screen.dart';
import '../services/firebase_service.dart';

class PengaduanCard extends StatelessWidget {
  final Pengaduan pengaduan;
  final bool editable;
  final String? role;

  final FirebaseService _service = FirebaseService();

  PengaduanCard({
    super.key,
    required this.pengaduan,
    this.editable = false,
    this.role,
  });

  /// ================= STATUS HELPER =================
  Color _statusColor(String? status) {
    switch (status ?? 'menunggu') {
      case 'diproses':
        return Colors.orange;
      case 'selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status ?? 'menunggu') {
      case 'diproses':
        return 'Diproses';
      case 'selesai':
        return 'Selesai';
      default:
        return 'Menunggu';
    }
  }

  /// ================= EDIT STATUS =================
  Future<void> _editStatus(BuildContext context) async {
    String selectedStatus = pengaduan.status ?? 'menunggu';

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Status Pengaduan'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Menunggu'),
                  value: 'menunggu',
                  groupValue: selectedStatus,
                  onChanged: (v) =>
                      v != null ? setState(() => selectedStatus = v) : null,
                ),
                RadioListTile<String>(
                  title: const Text('Diproses'),
                  value: 'diproses',
                  groupValue: selectedStatus,
                  onChanged: (v) =>
                      v != null ? setState(() => selectedStatus = v) : null,
                ),
                RadioListTile<String>(
                  title: const Text('Selesai'),
                  value: 'selesai',
                  groupValue: selectedStatus,
                  onChanged: (v) =>
                      v != null ? setState(() => selectedStatus = v) : null,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selectedStatus),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && pengaduan.id != null) {
      await _service.updateStatusPengaduan(
        pengaduan.id!,
        result,
      );
    }
  }

  /// ================= HAPUS =================
  Future<void> _deletePengaduan(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengaduan'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus pengaduan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && pengaduan.id != null) {
      await _service.hapusPengaduan(pengaduan.id!);
    }
  }

  /// ================= UI =================
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
            : const Icon(Icons.report,
                size: 40, color: Colors.redAccent),

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
              _statusLabel(pengaduan.status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _statusColor(pengaduan.status),
              ),
            ),
          ],
        ),

        /// ================= ACTION BUTTON =================
        trailing: editable
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (role == 'kelurahan')
                    IconButton(
                      icon:
                          const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editStatus(context),
                    ),
                  IconButton(
                    icon:
                        const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deletePengaduan(context),
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
