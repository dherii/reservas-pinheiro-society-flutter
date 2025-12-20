class FieldModel {
  final String id;
  final String nome;
  final double precoPorHora;
  final String imagemUrl;
  final String descricao;
  FieldModel({
    required this.id,
    required this.nome,
    required this.precoPorHora,
    required this.imagemUrl,
    required this.descricao,
  });

  FieldModel copyWith({
    String? id,
    String? nome,
    double? precoPorHora,
    String? imagemUrl,
    String? descricao,
  }) {
    return FieldModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      precoPorHora: precoPorHora ?? this.precoPorHora,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      descricao: descricao ?? this.descricao,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nome': nome,
      'precoPorHora': precoPorHora,
      'imagemUrl': imagemUrl,
      'descricao': descricao,
    };
  }

  factory FieldModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FieldModel(
      id: documentId,
      nome: map['nome'] ?? '',
      precoPorHora: (map['precoPorHora'] as num?)?.toDouble() ?? 0.0,
      imagemUrl: map['imagemUrl'] ?? '',
      descricao: map['descricao'] ?? '',
    );
  }

  @override
  String toString() {
    return 'FieldModel(id: $id, nome: $nome, precoPorHora: $precoPorHora, imagemUrl: $imagemUrl, descricao: $descricao)';
  }

  @override
  bool operator ==(covariant FieldModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.nome == nome &&
        other.precoPorHora == precoPorHora &&
        other.imagemUrl == imagemUrl &&
        other.descricao == descricao;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nome.hashCode ^
        precoPorHora.hashCode ^
        imagemUrl.hashCode ^
        descricao.hashCode;
  }
}
