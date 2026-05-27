import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/arena_settings_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _service = ArenaSettingsService();
  final _formKey = GlobalKey<FormState>();

  // Controllers de texto
  final _nomeArenaController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _chavePixController = TextEditingController();

  // Estado local (carregado do Firestore)
  int _horarioAbertura = 8;
  int _horarioFechamento = 22;
  List<int> _diasFuncionamento = [1, 2, 3, 4, 5, 6, 7];
  int _duracaoSlot = 60;
  int _intervaloSlot = 0;
  bool _aceitaPix = true;
  bool _aceitaLocal = true;
  String _pixTipo = 'integral';

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarSettings();
  }

  Future<void> _carregarSettings() async {
    final s = await _service.getSettings();
    setState(() {
      _nomeArenaController.text = s.nomeArena;
      _telefoneController.text = s.telefoneWhatsApp;
      _descricaoController.text = s.descricao;
      _chavePixController.text = s.chavePix;
      _horarioAbertura = s.horarioAberturaHora;
      _horarioFechamento = s.horarioFechamentoHora;
      _diasFuncionamento = List.from(s.diasFuncionamento);
      _duracaoSlot = s.duracaoSlotMinutos;
      _intervaloSlot = s.intervaloEntreSlotMinutos;
      _aceitaPix = s.aceitaPix;
      _aceitaLocal = s.aceitaPagamentoLocal;
      _pixTipo = s.pixTipo;
      _isLoading = false;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final settings = ArenaSettings(
      nomeArena: _nomeArenaController.text.trim(),
      telefoneWhatsApp: _telefoneController.text.trim(),
      descricao: _descricaoController.text.trim(),
      horarioAberturaHora: _horarioAbertura,
      horarioFechamentoHora: _horarioFechamento,
      diasFuncionamento: _diasFuncionamento,
      duracaoSlotMinutos: _duracaoSlot,
      intervaloEntreSlotMinutos: _intervaloSlot,
      aceitaPix: _aceitaPix,
      aceitaPagamentoLocal: _aceitaLocal,
      pixTipo: _pixTipo,
      chavePix: _chavePixController.text.trim(),
    );

    await _service.saveSettings(settings);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações salvas ✓'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nomeArenaController.dispose();
    _telefoneController.dispose();
    _descricaoController.dispose();
    _chavePixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _salvar,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Salvar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 1. INFORMAÇÕES DA ARENA ──────────────────────────────────
            _SettingsSection(
              icon: Icons.stadium,
              title: 'Informações da Arena',
              children: [
                _SettingsTextField(
                  controller: _nomeArenaController,
                  label: 'Nome da Arena',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _SettingsTextField(
                  controller: _telefoneController,
                  label: 'WhatsApp do Admin (com DDI)',
                  icon: Icons.phone_outlined,
                  hint: 'ex: 5588900000000',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _SettingsTextField(
                  controller: _descricaoController,
                  label: 'Descrição curta',
                  icon: Icons.notes,
                  maxLines: 2,
                  required: false,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 2. HORÁRIO DE FUNCIONAMENTO ──────────────────────────────
            _SettingsSection(
              icon: Icons.schedule,
              title: 'Dias de Funcionamento',
              children: [
                const SizedBox(height: 8),
                _WeekdaySelector(
                  selected: _diasFuncionamento,
                  onChanged: (dias) =>
                      setState(() => _diasFuncionamento = dias),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 3. MEIOS DE PAGAMENTO ────────────────────────────────────
            _SettingsSection(
              icon: Icons.payments_outlined,
              title: 'Meios de Pagamento',
              children: [
                // Toggle Pix
                _ToggleTile(
                  icon: Icons.pix,
                  iconColor: const Color(0xFF00BFA5),
                  title: 'Aceitar Pix',
                  value: _aceitaPix,
                  onChanged: (v) => setState(() => _aceitaPix = v),
                ),

                // Opções do Pix (só aparecem se Pix estiver ativo)
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _aceitaPix
                      ? Column(
                          children: [
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Cobrança via Pix',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _RadioOption(
                                    value: 'integral',
                                    groupValue: _pixTipo,
                                    label: 'Valor integral',
                                    subtitle:
                                        'Cliente paga 100% para confirmar',
                                    onChanged: (v) =>
                                        setState(() => _pixTipo = v!),
                                  ),
                                  _RadioOption(
                                    value: 'metade',
                                    groupValue: _pixTipo,
                                    label: '50% de sinal',
                                    subtitle:
                                        'Cliente paga metade para confirmar',
                                    onChanged: (v) =>
                                        setState(() => _pixTipo = v!),
                                  ),
                                  const SizedBox(height: 8),
                                  _SettingsTextField(
                                    controller: _chavePixController,
                                    label: 'Chave Pix',
                                    icon: Icons.key,
                                    hint: 'Celular, CPF, e-mail ou aleatória',
                                    required: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                const Divider(height: 20),

                // Toggle Pagamento local
                _ToggleTile(
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFF2E7D32),
                  title: 'Pagamento local',
                  subtitle: 'Cliente paga no momento do agendamento',
                  value: _aceitaLocal,
                  onChanged: (v) => setState(() => _aceitaLocal = v),
                ),

                // Aviso se nenhum método estiver ativo
                if (!_aceitaPix && !_aceitaLocal) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFCC02)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Color(0xFFF57C00),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Habilite pelo menos um meio de pagamento.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 32),

            // Botão salvar no rodapé
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvar,
                icon: const Icon(Icons.save_outlined, color: Colors.white),
                label: Text(
                  _isSaving ? 'Salvando...' : 'Salvar configurações',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── COMPONENTES INTERNOS ──────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF2E7D32), size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;

  const _SettingsTextField({
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        floatingLabelStyle: const TextStyle(color: Color(0xFF2E7D32)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null
          : null,
    );
  }
}

class _HourDropdown extends StatelessWidget {
  final String label;
  final int value;
  final void Function(int) onChanged;

  const _HourDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: List.generate(24, (i) {
            return DropdownMenuItem(
              value: i,
              child: Text('${i.toString().padLeft(2, '0')}:00'),
            );
          }),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ],
    );
  }
}

class _WeekdaySelector extends StatelessWidget {
  final List<int> selected;
  final void Function(List<int>) onChanged;

  const _WeekdaySelector({required this.selected, required this.onChanged});

  static const _labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
  static const _fullLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1;
        final isSelected = selected.contains(day);

        return Tooltip(
          message: _fullLabels[i],
          child: GestureDetector(
            onTap: () {
              final newList = List<int>.from(selected);
              if (isSelected) {
                if (newList.length > 1) newList.remove(day);
              } else {
                newList.add(day);
              }
              onChanged(newList);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFF5F5F5),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE0E0E0),
                ),
              ),
              child: Center(
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> items;
  final void Function(T) onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1B1B1B)),
          ),
        ),
        DropdownButton<T>(
          value: value,
          underline: const SizedBox(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2E7D32),
        ),
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String label;
  final String subtitle;
  final void Function(String?) onChanged;

  const _RadioOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: const Color(0xFF2E7D32),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
