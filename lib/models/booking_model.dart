import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String campoId;
  final String campoNome;

  // Pode ser nulo se for uma reserva manual feita pelo Admin
  final String? usuarioId;
  final String usuarioNome;

  final DateTime dataHorarioInicio;
  final DateTime dataHorarioFim;

  // 'confirmado', 'pendente', 'cancelado', 'concluido'
  final String status;
  final double valorTotal;

  // --- Cmpos de Pagamento ---
  final String
  metodoPagamento; // ex: 'pix', 'dinheiro', 'cartao', 'nao_informado'
  final String statusPagamento; // ex: 'pendente', 'sinal_pago', 'pago_total'
  final double valorPago;

  BookingModel({
    required this.id,
    required this.campoId,
    required this.campoNome,
    this.usuarioId,
    required this.usuarioNome,
    required this.dataHorarioInicio,
    required this.dataHorarioFim,
    required this.status,
    required this.valorTotal,
    this.metodoPagamento = 'nao_informado', // Valores padrão
    this.statusPagamento = 'pendente', // Valores padrão
    this.valorPago = 0.0, // Valores padrão
  });

  // --- CopyWith (editar reservas) ---
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
    String? metodoPagamento,
    String? statusPagamento,
    double? valorPago,
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
      metodoPagamento: metodoPagamento ?? this.metodoPagamento,
      statusPagamento: statusPagamento ?? this.statusPagamento,
      valorPago: valorPago ?? this.valorPago,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'campoId': campoId,
      'campoNome': campoNome,
      'usuarioId': usuarioId,
      'usuarioNome': usuarioNome,
      'dataHorarioInicio': Timestamp.fromDate(dataHorarioInicio),
      'dataHorarioFim': Timestamp.fromDate(dataHorarioFim),
      'status': status,
      'valorTotal': valorTotal,
      'metodoPagamento': metodoPagamento,
      'statusPagamento': statusPagamento,
      'valorPago': valorPago,
    };
  }

  // --- Para ler do Firebase ---
  factory BookingModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BookingModel(
      id: documentId,
      campoId: map['campoId'] ?? '',
      campoNome: map['campoNome'] ?? '',
      usuarioId: map['usuarioId'], // Pode vir nulo
      usuarioNome: map['usuarioNome'] ?? 'Cliente Desconhecido',

      dataHorarioInicio: (map['dataHorarioInicio'] as Timestamp).toDate(),
      dataHorarioFim: (map['dataHorarioFim'] as Timestamp).toDate(),

      status: map['status'] ?? 'pendente',
      valorTotal: (map['valorTotal'] as num?)?.toDouble() ?? 0.0,

      // Tratamento seguro para os novos campos
      metodoPagamento: map['metodoPagamento'] ?? 'nao_informado',
      statusPagamento: map['statusPagamento'] ?? 'pendente',
      valorPago: (map['valorPago'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'BookingModel(id: $id, campo: $campoNome, cliente: $usuarioNome, status: $status, pagto: $statusPagamento)';
  }

  @override
  bool operator ==(covariant BookingModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.campoId == campoId &&
        other.usuarioId == usuarioId &&
        other.dataHorarioInicio == dataHorarioInicio &&
        other.status == status &&
        other.statusPagamento == statusPagamento;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        campoId.hashCode ^
        usuarioId.hashCode ^
        dataHorarioInicio.hashCode ^
        status.hashCode ^
        statusPagamento.hashCode;
  }
}
