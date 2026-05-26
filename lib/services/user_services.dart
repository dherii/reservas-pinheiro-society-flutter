import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --------------------------------------------------------
  // MÉTODO DO ADMIN: Pega o usuário logado via FirebaseAuth
  // --------------------------------------------------------
  Future<UserModel?> getUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      return null;
    } catch (e) {
      debugPrint("Erro ao buscar usuário logado: $e");
      return null;
    }
  }

  // --------------------------------------------------------
  // MÉTODO DA WEB (CLIENTE): Guest Checkout via WhatsApp
  // --------------------------------------------------------
  Future<UserModel> getOrCreateGuestUser(String nome, String telefone) async {
    try {
      // 1. Tenta encontrar um cliente que já tenha esse telefone cadastrado
      final querySnapshot = await _firestore
          .collection('users')
          .where('telefone', isEqualTo: telefone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // 2. Cliente antigo! Retorna os dados dele.
        final doc = querySnapshot.docs.first;
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        // 3. Cliente novo! Cria um registro no banco sem e-mail/senha.
        final docRef = _firestore.collection('users').doc();

        final novoUsuario = UserModel(
          id: docRef.id,
          nome: nome,
          telefone: telefone,
          isAdmin: false, // Cliente web nunca é admin
        );

        await docRef.set(novoUsuario.toMap());
        return novoUsuario;
      }
    } catch (e) {
      debugPrint("Erro ao buscar ou criar usuário convidado: $e");
      // O throw propaga o erro para a tela avisar o usuário (ex: no SnackBar)
      throw Exception(
        "Não foi possível processar seus dados. Tente novamente.",
      );
    }
  }
}
