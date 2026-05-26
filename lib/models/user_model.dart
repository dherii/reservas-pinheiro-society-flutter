class UserModel {
  final String id;
  final String nome;
  final String? email; // Alterado para opcional (pode ser nulo)
  final String telefone;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.nome,
    this.email, // Retirado o 'required'
    required this.telefone,
    this.isAdmin = false,
  });

  UserModel copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nome': nome,
      // Só salva o email no Firebase se ele não for nulo
      if (email != null) 'email': email,
      'telefone': telefone,
      'isAdmin': isAdmin,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      nome: map['nome'] ?? '',
      email: map['email'], // Pode vir nulo do Firebase sem problemas
      telefone: map['telefone'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nome: $nome, email: $email, telefone: $telefone, isAdmin: $isAdmin)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.nome == nome &&
        other.email == email &&
        other.telefone == telefone &&
        other.isAdmin == isAdmin;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nome.hashCode ^
        email.hashCode ^
        telefone.hashCode ^
        isAdmin.hashCode;
  }
}
