import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/field_model.dart';
import '../../services/field_service.dart';

class FieldManagementScreen extends StatelessWidget {
  const FieldManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text(
          'Gerenciar Campos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('fields').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── INFO ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF2E7D32),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Toque em um campo para editar. Os horários são gerados automaticamente com base nas configurações de cada campo.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── LISTA DE CAMPOS ────────────────────────────────────────
              ...docs.map((doc) {
                final field = FieldModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
                return _FieldListCard(
                  field: field,
                  onTap: () => _abrirEdicao(context, field),
                );
              }),

              // ── BOTÃO ADICIONAR ────────────────────────────────────────
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _abrirEdicao(context, null),
                icon: const Icon(Icons.add, color: Color(0xFF2E7D32)),
                label: const Text(
                  'Adicionar novo campo',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _abrirEdicao(BuildContext context, FieldModel? field) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FieldEditModal(field: field),
    );
  }
}

// ── CARD DA LISTA ─────────────────────────────────────────────────────────────
class _FieldListCard extends StatelessWidget {
  final FieldModel field;
  final VoidCallback onTap;

  const _FieldListCard({required this.field, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Preview dos slots gerados
    final slots = field.getSlotsForDate(DateTime.now());
    final primeiroSlot = slots.isNotEmpty
        ? '${slots.first.hour.toString().padLeft(2, '0')}:${slots.first.minute.toString().padLeft(2, '0')}'
        : '--';
    final ultimoSlot = slots.isNotEmpty
        ? '${slots.last.hour.toString().padLeft(2, '0')}:${slots.last.minute.toString().padLeft(2, '0')}'
        : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.nome,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B1B1B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _MiniTag(
                            label:
                                'R\$ ${field.precoPorHora.toStringAsFixed(0)}/h',
                            color: const Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 6),
                          _MiniTag(
                            label: '$primeiroSlot – $ultimoSlot',
                            color: const Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 6),
                          _MiniTag(
                            label: '${slots.length} slots',
                            color: const Color(0xFF6D4C41),
                          ),
                        ],
                      ),
                      if (field.horariosBloqueados.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${field.horariosBloqueados.length} horário(s) bloqueado(s)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF9E9E9E),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── MODAL DE EDIÇÃO / CRIAÇÃO ─────────────────────────────────────────────────
class _FieldEditModal extends StatefulWidget {
  final FieldModel? field;

  const _FieldEditModal({this.field});

  @override
  State<_FieldEditModal> createState() => _FieldEditModalState();
}

class _FieldEditModalState extends State<_FieldEditModal>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fieldService = FieldService();

  late TabController _tabController;

  // Aba 1 — Informações
  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  final _descricaoController = TextEditingController();

  // Aba 2 — Horários
  int _aberturaHora = 17;
  int _aberturaMinuto = 0;
  int _duracaoSlot = 60;
  int _intervaloSlot = 0;
  int _limiteAgendamentos = 6;

  // Horários bloqueados
  List<String> _horariosBloqueados = [];

  bool _isLoading = false;
  bool get _isEditing => widget.field != null;

  // Opções disponíveis
  static const _duracoes = [50, 55, 60, 65, 70];
  static const _intervalos = [0, 5, 10, 15, 20, 25, 30];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (_isEditing) {
      final f = widget.field!;
      _nomeController.text = f.nome;
      _precoController.text = f.precoPorHora.toStringAsFixed(2);
      _descricaoController.text = f.descricao;
      _aberturaHora = f.aberturaHora;
      _aberturaMinuto = f.aberturaMinuto;
      _duracaoSlot = f.duracaoSlotMinutos;
      _intervaloSlot = f.intervaloMinutos;
      _limiteAgendamentos = f.limiteAgendamentos;
      _horariosBloqueados = List.from(f.horariosBloqueados);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeController.dispose();
    _precoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  // Gera preview dos slots com base nas configs atuais
  List<String> get _slotsPreview {
    final tempField = FieldModel(
      id: '',
      nome: '',
      precoPorHora: 0,
      descricao: '',
      aberturaHora: _aberturaHora,
      aberturaMinuto: _aberturaMinuto,
      duracaoSlotMinutos: _duracaoSlot,
      intervaloMinutos: _intervaloSlot,
      limiteAgendamentos: _limiteAgendamentos,
    );
    return tempField
        .getSlotsForDate(DateTime.now())
        .map(
          (dt) =>
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
        )
        .toList();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'nome': _nomeController.text.trim(),
      'precoPorHora': double.parse(_precoController.text.replaceAll(',', '.')),
      'descricao': _descricaoController.text.trim(),
      'aberturaHora': _aberturaHora,
      'aberturaMinuto': _aberturaMinuto,
      'duracaoSlotMinutos': _duracaoSlot,
      'intervaloMinutos': _intervaloSlot,
      'limiteAgendamentos': _limiteAgendamentos,
      'horariosBloqueados': _horariosBloqueados,
    };

    try {
      if (_isEditing) {
        await FirebaseFirestore.instance
            .collection('fields')
            .doc(widget.field!.id)
            .update(data);
      } else {
        await FirebaseFirestore.instance.collection('fields').add(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Campo atualizado ✓' : 'Campo criado ✓'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _excluir() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir campo?'),
        content: Text(
          'O campo "${widget.field!.nome}" será removido permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('fields')
          .doc(widget.field!.id)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título + ações
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  _isEditing ? 'Editar Campo' : 'Novo Campo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const Spacer(),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Excluir campo',
                    onPressed: _excluir,
                  ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF757575),
              indicator: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorPadding: const EdgeInsets.all(3),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Informações'),
                Tab(text: 'Horários'),
              ],
            ),
          ),

          // Conteúdo das abas
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── ABA 1: INFORMAÇÕES ──────────────────────────────────
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      keyboardSpace + 20,
                    ),
                    child: Column(
                      children: [
                        _ModalField(
                          controller: _nomeController,
                          label: 'Nome do campo',
                          icon: Icons.stadium_outlined,
                          hint: 'ex: Campo 1, Arena Principal...',
                        ),
                        const SizedBox(height: 14),
                        _ModalField(
                          controller: _precoController,
                          label: 'Preço por hora (R\$)',
                          icon: Icons.attach_money,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ModalField(
                          controller: _descricaoController,
                          label: 'Descrição',
                          icon: Icons.notes,
                          maxLines: 3,
                          required: false,
                        ),
                      ],
                    ),
                  ),

                  // ── ABA 2: HORÁRIOS ─────────────────────────────────────
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      keyboardSpace + 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Horário de abertura
                        const _ModalSectionLabel('Horário de abertura'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _HourMinuteDropdown(
                                label: 'Hora',
                                value: _aberturaHora,
                                items: List.generate(
                                  24,
                                  (i) =>
                                      MapEntry(i, i.toString().padLeft(2, '0')),
                                ),
                                onChanged: (v) =>
                                    setState(() => _aberturaHora = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _HourMinuteDropdown(
                                label: 'Minuto',
                                value: _aberturaMinuto,
                                items: [0, 10, 15, 20, 30, 45]
                                    .map(
                                      (m) => MapEntry(
                                        m,
                                        m.toString().padLeft(2, '0'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _aberturaMinuto = v),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Duração do slot
                        const _ModalSectionLabel('Duração de cada agendamento'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _duracoes.map((min) {
                            final label = min < 60
                                ? '${min}min'
                                : min == 60
                                ? '1h'
                                : '1h${min - 60}min';
                            return _SelectChip(
                              label: label,
                              isSelected: _duracaoSlot == min,
                              onTap: () => setState(() => _duracaoSlot = min),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Intervalo
                        const _ModalSectionLabel('Intervalo entre reservas'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _intervalos.map((min) {
                            return _SelectChip(
                              label: min == 0 ? 'Sem intervalo' : '${min}min',
                              isSelected: _intervaloSlot == min,
                              onTap: () => setState(() => _intervaloSlot = min),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Limite de agendamentos
                        Row(
                          children: [
                            const Expanded(
                              child: _ModalSectionLabel(
                                'Máximo de agendamentos/dia',
                              ),
                            ),
                            Row(
                              children: [
                                _CounterButton(
                                  icon: Icons.remove,
                                  onTap: _limiteAgendamentos > 1
                                      ? () => setState(
                                          () => _limiteAgendamentos--,
                                        )
                                      : null,
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '$_limiteAgendamentos',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                _CounterButton(
                                  icon: Icons.add,
                                  onTap: _limiteAgendamentos < 20
                                      ? () => setState(
                                          () => _limiteAgendamentos++,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── PREVIEW DOS SLOTS ─────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8F5E9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.preview,
                                    size: 14,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Prévia dos horários gerados',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _slotsPreview.map((slot) {
                                  final isBloqueado = _horariosBloqueados
                                      .contains(slot);
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isBloqueado) {
                                          _horariosBloqueados.remove(slot);
                                        } else {
                                          _horariosBloqueados.add(slot);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isBloqueado
                                            ? const Color(0xFFFFEBEE)
                                            : const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isBloqueado
                                              ? const Color(0xFFEF9A9A)
                                              : const Color(0xFFA5D6A7),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isBloqueado
                                                ? Icons.block
                                                : Icons.check,
                                            size: 12,
                                            color: isBloqueado
                                                ? const Color(0xFFD32F2F)
                                                : const Color(0xFF2E7D32),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            slot,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isBloqueado
                                                  ? const Color(0xFFD32F2F)
                                                  : const Color(0xFF2E7D32),
                                              decoration: isBloqueado
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Toque em um horário para bloquear/desbloquear.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── BOTÃO SALVAR ──────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + keyboardSpace),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Salvar alterações' : 'Criar campo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── COMPONENTES INTERNOS DO MODAL ─────────────────────────────────────────────

class _ModalSectionLabel extends StatelessWidget {
  final String text;
  const _ModalSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1B1B1B),
      ),
    );
  }
}

class _ModalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;

  const _ModalField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        floatingLabelStyle: const TextStyle(color: Color(0xFF2E7D32)),
      ),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null
          : null,
    );
  }
}

class _HourMinuteDropdown extends StatelessWidget {
  final String label;
  final int value;
  final List<MapEntry<int, String>> items;
  final void Function(int) onChanged;

  const _HourMinuteDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ],
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2E7D32)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF757575),
          ),
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? const Color(0xFF2E7D32)
              : const Color(0xFFBDBDBD),
        ),
      ),
    );
  }
}
