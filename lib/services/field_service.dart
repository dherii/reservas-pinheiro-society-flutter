import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/field_model.dart';

class FieldService {
  final CollectionReference _fieldsCollection = FirebaseFirestore.instance
      .collection('fields');

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
}
