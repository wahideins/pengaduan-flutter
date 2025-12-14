import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/pengaduan.dart';
import '../../services/firebase_service.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import '../../widgets/pengaduan_card.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService service = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final inAppMessaging = FirebaseInAppMessaging.instance;
  final analytics = FirebaseAnalytics.instance;
  String? namaUser;
  String? role;


  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadUserName();
    _triggerInAppMessage();
    _logInstallationId();
  }

  Future<void> _loadRole() async {
    final r = await service.getUserRole();
    setState(() {
      role = r;
    });
  }


  Future<void> _triggerInAppMessage() async {
    // Pastikan pesan tidak disuppress
    await inAppMessaging.setMessagesSuppressed(false);

    // Trigger event untuk FIAM
    await analytics.logEvent(
      name: 'dashboard_opened',
    );

    debugPrint('Event dashboard_opened dikirim ke Firebase Analytics');
  }

  Future<void> _logInstallationId() async {
    final id = await FirebaseInstallations.instance.getId();
    debugPrint('Firebase Installation ID: $id');
    }



  Future<void> _loadUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      final profile = await service.getCurrentUserProfile();
      setState(() {
        namaUser = profile?['nama'] ?? user.email ?? 'Pengguna';
      });
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        role == 'kelurahan'
            ? 'Dashboard Admin'
            : 'Selamat Datang${namaUser != null ? ', $namaUser' : ''}',
      ),
    ),
    body: role == null
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<List<Pengaduan>>(
            stream: service.getPengaduanByRole(role!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Belum ada pengaduan.'));
              }

              final list = snapshot.data!;
              final total = list.length;
              final selesai = list
                  .where((e) =>
                      e.lokasi != null && e.lokasi!.isNotEmpty)
                  .length;
              final proses = total - selesai;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role == 'kelurahan'
                          ? 'Daftar Semua Pengaduan'
                          : 'Daftar Pengaduan Anda',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
  child: ListView.builder(
    itemCount: list.length,
    itemBuilder: (context, index) {
      final p = list[index];
      return PengaduanCard(
        pengaduan: p,
        editable: true,
      );
    },
  ),
),
                  ],
                ),
              );
            },
          ),
  );
}
}