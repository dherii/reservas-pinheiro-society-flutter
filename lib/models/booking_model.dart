class BookingModel {
  final String id;
  final String campoId;
  final String campoNome;
  final String usuarioId;
  final String usuarioNome;
  final DateTime dataHorarioInicio;
  final DateTime dataHorarioFim;
  final String status;
  final double valorTotal;

  BookingModel({
    required this.id,
    required this.campoId,
    required this.campoNome,
    required this.usuarioId,
    required this.usuarioNome,
    required this.dataHorarioInicio,
    required this.dataHorarioFim,
    required this.status,
    required this.valorTotal,
  });

  BookingModel copyWith({
    String? id,
    String? campoId,
    String? campoNome,
    String? usuarioId,
    String? usuarioNome,
    DateTime? dataHorarioInicio,
    DateTime? dataHorarioFim,
    String? status,
    double? valorTotal,
  }) {
    return BookingModel(
      id: id ?? this.id,
      campoId: campoId ?? this.campoId,
      campoNome: campoNome ?? this.campoNome,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNome: usuarioNome ?? this.usuarioNome,
      dataHorarioInicio: dataHorarioInicio ?? this.dataHorarioInicio,
      dataHorarioFim: dataHorarioFim ?? this.dataHorarioFim,
      status: status ?? this.status,
      valorTotal: valorTotal ?? this.valorTotal,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'campoId': campoId,
      'campoNome': campoNome,
      'usuarioId': usuarioId,
      'usuarioNome': usuarioNome,
      'dataHorarioInicio': dataHorarioInicio.millisecondsSinceEpoch,
      'dataHorarioFim': dataHorarioFim.millisecondsSinceEpoch,
      'status': status,
      'valorTotal': valorTotal,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BookingModel(
      id: documentId,
      campoId: map['campoId'] as String,
      campoNome: map['campoNome'] as String,
      usuarioId: map['usuarioId'] as String,
      usuarioNome: map['usuarioNome'] as String,
      dataHorarioInicio: DateTime.fromMillisecondsSinceEpoch(
        map['dataHorarioInicio'] as int,
      ),
      dataHorarioFim: DateTime.fromMillisecondsSinceEpoch(
        map['dataHorarioFim'] as int,
      ),
      status: map['status'] as String,
      valorTotal: (map['valorTotal'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'BookingModel(id: $id, campoId: $campoId, campoNome: $campoNome, usuarioId: $usuarioId, usuarioNome: $usuarioNome, dataHorarioInicio: $dataHorarioInicio, dataHorarioFim: $dataHorarioFim, status: $status, valorTotal: $valorTotal)';
  }

  @override
  bool operator ==(covariant BookingModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.campoId == campoId &&
        other.campoNome == campoNome &&
        other.usuarioId == usuarioId &&
        other.usuarioNome == usuarioNome &&
        other.dataHorarioInicio == dataHorarioInicio &&
        other.dataHorarioFim == dataHorarioFim &&
        other.status == status &&
        other.valorTotal == valorTotal;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        campoId.hashCode ^
        campoNome.hashCode ^
        usuarioId.hashCode ^
        usuarioNome.hashCode ^
        dataHorarioInicio.hashCode ^
        dataHorarioFim.hashCode ^
        status.hashCode ^
        valorTotal.hashCode;
  }
}
