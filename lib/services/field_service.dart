import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/field_model.dart';

class FieldService {
  final CollectionReference _fieldsCollection = FirebaseFirestore.instance
      .collection('fields');

  // Método para adicionar novos campos
  Future<void> addField({
    required String nome,
    required double preco,
    required String descricao,
  }) async {
    DocumentReference docRef = _fieldsCollection.doc();

    FieldModel field = FieldModel(
      id: docRef.id,
      nome: nome,
      precoPorHora: preco,
      descricao: descricao,
    );

    await docRef.set(field.toMap());
  }

  // Busca os campos em tempo real para exibir na tela do cliente
  Stream<List<FieldModel>> getFields() {
    return _fieldsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FieldModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
