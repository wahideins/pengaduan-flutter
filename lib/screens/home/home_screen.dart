import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'dashboard_page.dart';
import 'pengaduan_page.dart';
import 'about_page.dart';
import '../form_screen.dart';
import '../account_screen.dart';
import '../../services/auth_services.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final auth = AuthService();
  final inAppMessaging = FirebaseInAppMessaging.instance;
  final analytics = FirebaseAnalytics.instance; 

  final List<Widget> _pages = const [
    DashboardScreen(),
    PengaduanPage(),
    AboutPage(),
  ];

  @override
  void initState() {
    super.initState();
    _getInstallationId();
    _triggerInAppMessage();
  }

  Future<void> _getInstallationId() async {
    final installations = FirebaseInstallations.instance;
    final fid = await installations.getId();
    debugPrint('Firebase Installation ID: $fid');
  }


  Future<void> _triggerInAppMessage() async {
    await inAppMessaging.setMessagesSuppressed(false);

    await analytics.logEvent(name: 'home_screen_opened');

    debugPrint('Event home_screen_opened dikirim ke Firebase Analytics');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaduan Masyarakat'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'akun') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              } else if (value == 'logout') {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'akun', child: Text('Akun')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),

      body: _pages[_selectedIndex],

      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FormPengaduanScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Pengaduan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Biodata',
          ),
        ],
      ),
    );
  }
}
