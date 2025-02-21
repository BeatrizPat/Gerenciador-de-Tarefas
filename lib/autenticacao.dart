import 'package:firebase_auth/firebase_auth.dart';

class Autenticacao {
  final FirebaseAuth _auth = FirebaseAuth.instance;



  Future<String?> logarUsuarios({required String email, required String senha}) async {
    try {
      if (!email.contains('@')) {
        email = '$email@gmail.com';
      }
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}