import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = fbAuth.FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Akun Saya')),
      body: user == null
          ? const Center(child: Text('Anda belum login.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const Text(
                    'Informasi Akun',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(user.email ?? '-'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Password'),
                    subtitle: const Text('•••••••• (disembunyikan)'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('UID'),
                    subtitle: Text(user.uid),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Kembali'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
