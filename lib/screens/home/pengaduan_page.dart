import 'package:flutter/material.dart';
import '../../../models/pengaduan.dart';
import '../../../services/firebase_service.dart';
import '../../../widgets/pengaduan_card.dart';

class PengaduanPage extends StatelessWidget {
  const PengaduanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService service = FirebaseService();

    return StreamBuilder<List<Pengaduan>>(
      stream: service.getPengaduanPublik(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Belum ada pengaduan'));
        }

        final list = snapshot.data!;
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final p = list[index];
            return PengaduanCard(
              pengaduan: p,
              editable: false,
              );
          },
        );
      },
    );
  }
}
