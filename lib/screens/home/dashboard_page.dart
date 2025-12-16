import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';

import '../../models/pengaduan.dart';
import '../../services/firebase_service.dart';
import '../../widgets/pengaduan_card.dart';
import 'camera_x_screen.dart';

import '../form_screen.dart';

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

  double _dragStartX = 0;
  bool _cameraOpened = false;

  static const double _swipeThreshold = 120; // px

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
    if (!mounted) return;
    setState(() => role = r);
  }

  Future<void> _loadUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      final profile = await service.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        namaUser = profile?['nama'] ?? user.email ?? 'Pengguna';
      });
    }
  }

void _openCameraFromDashboard({required bool isVideo}) async {
  if (_cameraOpened) return;
  _cameraOpened = true;

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CameraXScreen(enableVideo: isVideo),
    ),
  );

  _cameraOpened = false;

  if (result == null || !mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FormPengaduanScreen(
        initialImage: result['type'] == 'image' ? result['file'] : null,
        initialVideo: result['type'] == 'video' ? result['file'] : null,
      ),
    ),
  );
}


  Future<void> _triggerInAppMessage() async {
    await inAppMessaging.setMessagesSuppressed(false);
    await analytics.logEvent(name: 'dashboard_opened');
  }

  Future<void> _logInstallationId() async {
    final id = await FirebaseInstallations.instance.getId();
    debugPrint('Firebase Installation ID: $id');
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
          : GestureDetector(
              behavior: HitTestBehavior.translucent,
             onHorizontalDragUpdate: (details) {
              final delta = details.globalPosition.dx - _dragStartX;

              if (delta > _swipeThreshold) {
                // 👉 Swipe kanan → FOTO
                _openCameraFromDashboard(isVideo: false);
              } else if (delta < -_swipeThreshold) {
                // 👈 Swipe kiri → VIDEO
                _openCameraFromDashboard(isVideo: true);
              }
            },

              child: StreamBuilder<List<Pengaduan>>(
                stream: service.getPengaduanByRole(role!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('Belum ada pengaduan.'));
                  }

                  final list = snapshot.data!;

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
                              return PengaduanCard(
                                pengaduan: list[index],
                                editable: true,
                                role: role,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
