import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get usuarioAtual => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<String?> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'E-mail não encontrado.';
        case 'wrong-password':
          return 'Senha incorreta.';
        case 'invalid-email':
          return 'E-mail inválido';
        case 'user-disabled':
          return 'Usuário inexistente';
        default:
          return e.message;
      }
    } catch (e) {
      return 'Erro desconhecido: $e';
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}
