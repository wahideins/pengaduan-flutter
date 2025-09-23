import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import '../services/firebase_service.dart';
import '../models/pengaduan.dart';
import 'form_screen.dart';
import '../widgets/pengaduan_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _service = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaduan Masyarakat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => fbAuth.FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: StreamBuilder<List<Pengaduan>>(
        stream: _service.getPengaduanStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData) return const Center(child: Text('Belum ada pengaduan'));
          final list = snapshot.data!;
          if (list.isEmpty) return const Center(child: Text('Belum ada pengaduan'));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final p = list[index];
              return PengaduanCard(pengaduan: p);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
