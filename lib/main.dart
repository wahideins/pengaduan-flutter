import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:camera/camera.dart';

import 'services/auth_prefs.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home/home_screen.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase
  await Firebase.initializeApp();

  // 🔥 Supabase
  await Supabase.initialize(
    url: 'https://uuiwqyicssxqvntlemhi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV1aXdxeWljc3N4cXZudGxlbWhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1NzAwOTEsImV4cCI6MjA3NDE0NjA5MX0.ctZRk15nTXCjtUajTCVfGPpNz4j2o-Jl_jr5l6eCHKA',
  );

  // 📸 Camera (CameraX otomatis di Android)
  cameras = await availableCameras();

  // 🔐 Auth local
  final savedUser = await AuthPrefs.getUser();

  runApp(MyApp(isLoggedIn: savedUser != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pengaduan Masyarakat',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
