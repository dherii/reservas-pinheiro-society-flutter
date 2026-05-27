class FieldModel {
  final String id;
  final String nome;
  final double precoPorHora;
  final String descricao;

  // ── Configurações de horário ──────────────────────────────────────────────
  final int aberturaHora; // ex: 17  → 17:00
  final int aberturaMinuto; // ex: 0   → 17:00
  final int duracaoSlotMinutos; // ex: 60, 65, 70 (50~70, passo 5)
  final int intervaloMinutos; // ex: 0, 5, 10 ... 30 (passo 5)
  final int limiteAgendamentos; // ex: 6 → máximo de slots no dia

  // ── Horários bloqueados (lista de "HH:mm" ex: ["19:00","20:10"]) ──────────
  final List<String> horariosBloqueados;

  FieldModel({
    required this.id,
    required this.nome,
    required this.precoPorHora,
    required this.descricao,
    this.aberturaHora = 17,
    this.aberturaMinuto = 0,
    this.duracaoSlotMinutos = 60,
    this.intervaloMinutos = 0,
    this.limiteAgendamentos = 6,
    this.horariosBloqueados = const [],
  });

  /// Gera a lista de TimeOfDay disponíveis com base nas configs do campo.
  /// Respeita: abertura, duração, intervalo e limite de agendamentos.
  List<DateTime> getSlotsForDate(DateTime date) {
    final slots = <DateTime>[];
    DateTime current = DateTime(
      date.year,
      date.month,
      date.day,
      aberturaHora,
      aberturaMinuto,
    );

    for (int i = 0; i < limiteAgendamentos; i++) {
      slots.add(current);
      current = current.add(
        Duration(minutes: duracaoSlotMinutos + intervaloMinutos),
      );
    }

    return slots;
  }

  FieldModel copyWith({
    String? id,
    String? nome,
    double? precoPorHora,
    String? descricao,
    int? aberturaHora,
    int? aberturaMinuto,
    int? duracaoSlotMinutos,
    int? intervaloMinutos,
    int? limiteAgendamentos,
    List<String>? horariosBloqueados,
  }) {
    return FieldModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      precoPorHora: precoPorHora ?? this.precoPorHora,
      descricao: descricao ?? this.descricao,
      aberturaHora: aberturaHora ?? this.aberturaHora,
      aberturaMinuto: aberturaMinuto ?? this.aberturaMinuto,
      duracaoSlotMinutos: duracaoSlotMinutos ?? this.duracaoSlotMinutos,
      intervaloMinutos: intervaloMinutos ?? this.intervaloMinutos,
      limiteAgendamentos: limiteAgendamentos ?? this.limiteAgendamentos,
      horariosBloqueados: horariosBloqueados ?? this.horariosBloqueados,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'precoPorHora': precoPorHora,
      'descricao': descricao,
      'aberturaHora': aberturaHora,
      'aberturaMinuto': aberturaMinuto,
      'duracaoSlotMinutos': duracaoSlotMinutos,
      'intervaloMinutos': intervaloMinutos,
      'limiteAgendamentos': limiteAgendamentos,
      'horariosBloqueados': horariosBloqueados,
    };
  }

  factory FieldModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FieldModel(
      id: documentId,
      nome: map['nome'] ?? '',
      precoPorHora: (map['precoPorHora'] as num?)?.toDouble() ?? 0.0,
      descricao: map['descricao'] ?? '',
      aberturaHora: (map['aberturaHora'] as num?)?.toInt() ?? 17,
      aberturaMinuto: (map['aberturaMinuto'] as num?)?.toInt() ?? 0,
      duracaoSlotMinutos: (map['duracaoSlotMinutos'] as num?)?.toInt() ?? 60,
      intervaloMinutos: (map['intervaloMinutos'] as num?)?.toInt() ?? 0,
      limiteAgendamentos: (map['limiteAgendamentos'] as num?)?.toInt() ?? 6,
      horariosBloqueados:
          (map['horariosBloqueados'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  @override
  String toString() =>
      'FieldModel(id: $id, nome: $nome, abertura: $aberturaHora:$aberturaMinuto, '
      'duracao: ${duracaoSlotMinutos}min, intervalo: ${intervaloMinutos}min, '
      'limite: $limiteAgendamentos)';

  @override
  bool operator ==(covariant FieldModel other) =>
      identical(this, other) || other.id == id;

  @override
  int get hashCode => id.hashCode;
}
