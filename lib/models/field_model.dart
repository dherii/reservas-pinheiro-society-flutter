class FieldModel {
  final String id;
  final String nome;
  final double precoPorHora;
  final String descricao;
  FieldModel({
    required this.id,
    required this.nome,
    required this.precoPorHora,
    required this.descricao,
  });

  FieldModel copyWith({
    String? id,
    String? nome,
    double? precoPorHora,
    String? descricao,
  }) {
    return FieldModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      precoPorHora: precoPorHora ?? this.precoPorHora,
      descricao: descricao ?? this.descricao,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nome': nome,
      'precoPorHora': precoPorHora,
      'descricao': descricao,
    };
  }

  factory FieldModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FieldModel(
      id: documentId,
      nome: map['nome'] ?? '',
      precoPorHora: (map['precoPorHora'] as num?)?.toDouble() ?? 0.0,
      descricao: map['descricao'] ?? '',
    );
  }

  @override
  String toString() {
    return 'FieldModel(id: $id, nome: $nome, precoPorHora: $precoPorHora, descricao: $descricao)';
  }

  @override
  bool operator ==(covariant FieldModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.nome == nome &&
        other.precoPorHora == precoPorHora &&
        other.descricao == descricao;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nome.hashCode ^
        precoPorHora.hashCode ^
        descricao.hashCode;
  }
}
