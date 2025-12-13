import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> registerUser(UserModel user, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );

    final uid = credential.user!.uid;
    await _db.child('users/$uid').set(user.copyWith(uid: uid).toMap());
    await credential.user!.sendEmailVerification();
    await _auth.signOut();
  }

  Future<UserModel?> getUserData(String uid) async {
    final snapshot = await _db.child('users/$uid').get();
    if (snapshot.exists) {
      return UserModel.fromMap(snapshot.value as Map);
    }
    return null;
  }

  Future<void> loginUser(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async => await _auth.signOut();
}
