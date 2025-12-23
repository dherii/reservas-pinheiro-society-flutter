import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/field_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'add_field_modal.dart';

class AdminHomeScreen extends StatelessWidget {
  final UserModel user;

  const AdminHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('fields').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.sports_soccer, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Nenhum campo cadastrado."),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final field = FieldModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    radius: 25,
                    child: const Icon(Icons.stadium, color: Colors.green),
                  ),
                  title: Text(
                    field.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(field.descricao),
                      const SizedBox(height: 4),
                      Text(
                        "R\$ ${field.precoPorHora.toStringAsFixed(2)} / hora",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Botão de Deletar
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection('fields')
                          .doc(field.id)
                          .delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Campo removido!")),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      // BOTÃO FLUTUANTE DE ADICIONAR (+)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // AQUI ESTAVA O ERRO: Trocamos o Navigator.push pelo showModalBottomSheet
          showModalBottomSheet(
            context: context,
            isScrollControlled:
                true, // Importante: Permite o modal subir com o teclado
            backgroundColor: Colors
                .transparent, // Importante: Deixa o fundo transparente para as bordas redondas funcionarem
            builder: (context) => const AddFieldModal(),
          );
        },
      ),
    );
  }
}
