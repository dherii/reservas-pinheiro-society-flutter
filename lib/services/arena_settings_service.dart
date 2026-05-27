import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo das configurações da arena.
/// Salvo num único documento: /settings/arena
class ArenaSettings {
  // ── Informações gerais ─────────────────────────────────────────────────────
  final String nomeArena;
  final String telefoneWhatsApp; // com DDI, ex: "5588900000000"
  final String descricao;

  // ── Horário de funcionamento ────────────────────────────────────────────────
  final int horarioAberturaHora; // ex: 8  (08:00)
  final int horarioFechamentoHora; // ex: 22 (22:00)
  final List<int> diasFuncionamento; // 1=Seg ... 7=Dom (DateTime.weekday)

  // ── Agendamentos ───────────────────────────────────────────────────────────
  final int duracaoSlotMinutos; // duração de cada slot (ex: 60)
  final int
  intervaloEntreSlotMinutos; // intervalo após cada reserva (ex: 0, 15, 30)

  // ── Pagamento ──────────────────────────────────────────────────────────────
  final bool aceitaPix;
  final bool aceitaPagamentoLocal;
  final String pixTipo; // 'integral' | 'metade'
  final String chavePix;

  const ArenaSettings({
    this.nomeArena = 'Pinheiro Society Arena',
    this.telefoneWhatsApp = '5588900000000',
    this.descricao = 'Reserve seu campo de forma rápida e sem cadastro.',
    this.horarioAberturaHora = 8,
    this.horarioFechamentoHora = 22,
    this.diasFuncionamento = const [1, 2, 3, 4, 5, 6, 7],
    this.duracaoSlotMinutos = 60,
    this.intervaloEntreSlotMinutos = 0,
    this.aceitaPix = true,
    this.aceitaPagamentoLocal = true,
    this.pixTipo = 'integral',
    this.chavePix = '',
  });

  ArenaSettings copyWith({
    String? nomeArena,
    String? telefoneWhatsApp,
    String? descricao,
    int? horarioAberturaHora,
    int? horarioFechamentoHora,
    List<int>? diasFuncionamento,
    int? duracaoSlotMinutos,
    int? intervaloEntreSlotMinutos,
    bool? aceitaPix,
    bool? aceitaPagamentoLocal,
    String? pixTipo,
    String? chavePix,
  }) {
    return ArenaSettings(
      nomeArena: nomeArena ?? this.nomeArena,
      telefoneWhatsApp: telefoneWhatsApp ?? this.telefoneWhatsApp,
      descricao: descricao ?? this.descricao,
      horarioAberturaHora: horarioAberturaHora ?? this.horarioAberturaHora,
      horarioFechamentoHora:
          horarioFechamentoHora ?? this.horarioFechamentoHora,
      diasFuncionamento: diasFuncionamento ?? this.diasFuncionamento,
      duracaoSlotMinutos: duracaoSlotMinutos ?? this.duracaoSlotMinutos,
      intervaloEntreSlotMinutos:
          intervaloEntreSlotMinutos ?? this.intervaloEntreSlotMinutos,
      aceitaPix: aceitaPix ?? this.aceitaPix,
      aceitaPagamentoLocal: aceitaPagamentoLocal ?? this.aceitaPagamentoLocal,
      pixTipo: pixTipo ?? this.pixTipo,
      chavePix: chavePix ?? this.chavePix,
    );
  }

  Map<String, dynamic> toMap() => {
    'nomeArena': nomeArena,
    'telefoneWhatsApp': telefoneWhatsApp,
    'descricao': descricao,
    'horarioAberturaHora': horarioAberturaHora,
    'horarioFechamentoHora': horarioFechamentoHora,
    'diasFuncionamento': diasFuncionamento,
    'duracaoSlotMinutos': duracaoSlotMinutos,
    'intervaloEntreSlotMinutos': intervaloEntreSlotMinutos,
    'aceitaPix': aceitaPix,
    'aceitaPagamentoLocal': aceitaPagamentoLocal,
    'pixTipo': pixTipo,
    'chavePix': chavePix,
  };

  factory ArenaSettings.fromMap(Map<String, dynamic> map) => ArenaSettings(
    nomeArena: map['nomeArena'] ?? 'Pinheiro Society Arena',
    telefoneWhatsApp: map['telefoneWhatsApp'] ?? '5588900000000',
    descricao: map['descricao'] ?? '',
    horarioAberturaHora: (map['horarioAberturaHora'] as num?)?.toInt() ?? 8,
    horarioFechamentoHora:
        (map['horarioFechamentoHora'] as num?)?.toInt() ?? 22,
    diasFuncionamento:
        (map['diasFuncionamento'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        [1, 2, 3, 4, 5, 6, 7],
    duracaoSlotMinutos: (map['duracaoSlotMinutos'] as num?)?.toInt() ?? 60,
    intervaloEntreSlotMinutos:
        (map['intervaloEntreSlotMinutos'] as num?)?.toInt() ?? 0,
    aceitaPix: map['aceitaPix'] ?? true,
    aceitaPagamentoLocal: map['aceitaPagamentoLocal'] ?? true,
    pixTipo: map['pixTipo'] ?? 'integral',
    chavePix: map['chavePix'] ?? '',
  );
}

// ── SERVIÇO ───────────────────────────────────────────────────────────────────

class ArenaSettingsService {
  final _doc = FirebaseFirestore.instance.collection('settings').doc('arena');

  /// Stream em tempo real (útil para o admin ver mudanças instantaneamente)
  Stream<ArenaSettings> watchSettings() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return const ArenaSettings();
      return ArenaSettings.fromMap(snap.data()!);
    });
  }

  /// Leitura única (útil para a interface web do cliente)
  Future<ArenaSettings> getSettings() async {
    final snap = await _doc.get();
    if (!snap.exists || snap.data() == null) return const ArenaSettings();
    return ArenaSettings.fromMap(snap.data()!);
  }

  /// Salva as configurações (merge = true para não apagar campos extras)
  Future<void> saveSettings(ArenaSettings settings) async {
    await _doc.set(settings.toMap(), SetOptions(merge: true));
  }
}
