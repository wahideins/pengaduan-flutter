import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Supabase.initialize(
    url: 'https://uuiwqyicssxqvntlemhi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV1aXdxeWljc3N4cXZudGxlbWhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1NzAwOTEsImV4cCI6MjA3NDE0NjA5MX0.ctZRk15nTXCjtUajTCVfGPpNz4j2o-Jl_jr5l6eCHKA',
  );


  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengaduan Masyarakat',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<fbAuth.User?>(
        stream: fbAuth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}