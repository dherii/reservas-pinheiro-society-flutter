import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking_model.dart';
import '../../models/field_model.dart';
import '../../services/booking_service.dart';
import '../../services/user_services.dart';
// NOVO: importe o serviço de configurações quando criá-lo
// import '../../services/arena_settings_service.dart';

class ClientBookingScreen extends StatefulWidget {
  final FieldModel field;

  const ClientBookingScreen({super.key, required this.field});

  @override
  State<ClientBookingScreen> createState() => _ClientBookingScreenState();
}

class _ClientBookingScreenState extends State<ClientBookingScreen> {
  final BookingService _bookingService = BookingService();
  final UserServices _userServices = UserServices();
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();

  DateTime _dataSelecionada = DateTime.now();

  // Seleção múltipla de horários
  List<DateTime> _horariosSelecionados = [];

  bool _isLoading = false;
  List<TimeOfDay> _horariosOcupados = [];

  // Etapa atual: 0 = data/hora  |  1 = dados pessoais  |  2 = resumo
  int _etapaAtual = 0;

  @override
  void initState() {
    super.initState();
    _carregarHorariosOcupados();
  }

  Future<void> _carregarHorariosOcupados() async {
    setState(() => _horariosSelecionados = []);
    final ocupados = await _bookingService.getOccupiedSlots(
      widget.field.id,
      _dataSelecionada,
    );
    if (mounted) setState(() => _horariosOcupados = ocupados);
  }

  Future<void> _finalizarReserva() async {
    if (!_formKey.currentState!.validate()) return;
    if (_horariosSelecionados.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final cliente = await _userServices.getOrCreateGuestUser(
        _nomeController.text.trim(),
        _telefoneController.text.trim(),
      );

      // Cria uma BookingModel para cada horário selecionado
      final reservas = _horariosSelecionados.map((dataInicio) {
        final dataFim = dataInicio.add(
          Duration(
            minutes:
                widget.field.duracaoSlotMinutos + widget.field.intervaloMinutos,
          ),
        );
        return BookingModel(
          id: '',
          campoId: widget.field.id,
          campoNome: widget.field.nome,
          usuarioId: cliente.id,
          usuarioNome: cliente.nome,
          dataHorarioInicio: dataInicio,
          dataHorarioFim: dataFim,
          status: 'pendente',
          valorTotal: widget.field.precoPorHora,
        );
      }).toList();

      await _bookingService.createMultipleBookings(reservas);
      _abrirWhatsApp(reservas.first);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao reservar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _abrirWhatsApp(BookingModel reserva) async {
    const telefoneAdmin = "5588900000000";
    final diaFormatado =
        "${reserva.dataHorarioInicio.day.toString().padLeft(2, '0')}/${reserva.dataHorarioInicio.month.toString().padLeft(2, '0')}";
    final horaFormatada =
        "${reserva.dataHorarioInicio.hour.toString().padLeft(2, '0')}:${reserva.dataHorarioInicio.minute.toString().padLeft(2, '0')}";

    final mensagem =
        "Olá! Acabei de fazer uma pré-reserva pelo site.\n\n"
        "⚽ *Campo:* ${reserva.campoNome}\n"
        "📅 *Data:* $diaFormatado às $horaFormatada\n"
        "👤 *Nome:* ${reserva.usuarioNome}\n"
        "📱 *Meu WhatsApp:* ${_telefoneController.text}\n\n"
        "Aguardo a confirmação!";

    final url = Uri.parse(
      "https://wa.me/$telefoneAdmin?text=${Uri.encodeComponent(mensagem)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    }
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────────

  String get _dataFormatada =>
      "${_dataSelecionada.day.toString().padLeft(2, '0')}/${_dataSelecionada.month.toString().padLeft(2, '0')}/${_dataSelecionada.year}";

  String get _horarioFormatado {
    if (_horariosSelecionados.isEmpty) return '–';
    final strs = _horariosSelecionados
        .map(
          (dt) =>
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
        )
        .toList();
    strs.sort();
    return strs.join(', ');
  }

  double get _valorTotal =>
      widget.field.precoPorHora * _horariosSelecionados.length;

  bool get _etapa0Completa => _horariosSelecionados.isNotEmpty;
  bool get _etapa1Completa =>
      _nomeController.text.trim().isNotEmpty &&
      _telefoneController.text.trim().length >= 10;

  // ── BUILD ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: Text(
          widget.field.nome,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              // ── STEPPER VISUAL ────────────────────────────────────────────
              _StepIndicator(etapaAtual: _etapaAtual),

              // ── CONTEÚDO DA ETAPA ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: _buildEtapaAtual(),
                    ),
                  ),
                ),
              ),

              // ── BARRA DE NAVEGAÇÃO ────────────────────────────────────────
              _BottomNavBar(
                etapaAtual: _etapaAtual,
                etapa0Completa: _etapa0Completa,
                etapa1Completa: _etapa1Completa,
                isLoading: _isLoading,
                onVoltar: _etapaAtual > 0
                    ? () => setState(() => _etapaAtual--)
                    : null,
                onAvancar: () {
                  if (_etapaAtual == 0 && _etapa0Completa) {
                    setState(() => _etapaAtual = 1);
                  } else if (_etapaAtual == 1 &&
                      _formKey.currentState!.validate()) {
                    setState(() => _etapaAtual = 2);
                  } else if (_etapaAtual == 2) {
                    _finalizarReserva();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEtapaAtual() {
    switch (_etapaAtual) {
      case 0:
        return _buildEtapa0(key: const ValueKey(0));
      case 1:
        return _buildEtapa1(key: const ValueKey(1));
      case 2:
        return _buildEtapa2(key: const ValueKey(2));
      default:
        return const SizedBox();
    }
  }

  // ── ETAPA 0: DATA E HORÁRIO ───────────────────────────────────────────────────
  Widget _buildEtapa0({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Escolha a data'),
        const SizedBox(height: 12),

        // Seletor de data
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _dataSelecionada,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF2E7D32),
                  ),
                ),
                child: child!,
              ),
            );
            if (d != null && d != _dataSelecionada) {
              setState(() => _dataSelecionada = d);
              _carregarHorariosOcupados();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _dataFormatada,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Alterar',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        const _SectionTitle(title: 'Escolha o horário'),
        const SizedBox(height: 12),

        const SizedBox(height: 24),
        const _SectionTitle(title: 'Escolha o(s) horário(s)'),
        const SizedBox(height: 4),
        const Text(
          'Você pode selecionar mais de um horário.',
          style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(height: 12),

        // Grid de horários — dinâmico baseado nas configs do campo
        Builder(
          builder: (context) {
            final horariosDisponiveis = _bookingService.getDynamicSlots(
              widget.field,
              _dataSelecionada,
            );

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: horariosDisponiveis.map((slotDt) {
                final slotTime = TimeOfDay.fromDateTime(slotDt);
                final isOcupado = _horariosOcupados.any(
                  (o) => o.hour == slotTime.hour && o.minute == slotTime.minute,
                );
                final isSelected = _horariosSelecionados.any(
                  (s) => s.hour == slotDt.hour && s.minute == slotDt.minute,
                );
                final hora =
                    '${slotDt.hour.toString().padLeft(2, '0')}:${slotDt.minute.toString().padLeft(2, '0')}';

                return _TimeChip(
                  hora: hora,
                  isOcupado: isOcupado,
                  isSelected: isSelected,
                  onTap: isOcupado
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _horariosSelecionados.removeWhere(
                                (s) =>
                                    s.hour == slotDt.hour &&
                                    s.minute == slotDt.minute,
                              );
                            } else {
                              _horariosSelecionados.add(slotDt);
                            }
                          });
                        },
                );
              }).toList(),
            );
          },
        ),

        if (!_etapa0Completa) ...[
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Selecione ao menos um horário para continuar',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2E7D32),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_horariosSelecionados.length} horário(s) selecionado(s)  ·  R\$ ${_valorTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── ETAPA 1: DADOS PESSOAIS ───────────────────────────────────────────────────
  Widget _buildEtapa1({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Seus dados'),
        const SizedBox(height: 6),
        const Text(
          'Sem cadastro. Só precisamos do seu nome e WhatsApp.',
          style: TextStyle(color: Color(0xFF757575), fontSize: 13),
        ),
        const SizedBox(height: 20),

        _buildField(
          controller: _nomeController,
          label: 'Como você se chama?',
          icon: Icons.person_outline,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),

        _buildField(
          controller: _telefoneController,
          label: 'WhatsApp com DDD',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
          validator: (v) =>
              v == null || v.length < 10 ? 'WhatsApp inválido' : null,
        ),

        const SizedBox(height: 24),

        // Mini-resumo do que foi escolhido
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2E7D32),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.field.nome}  ·  $_dataFormatada  ·  $_horarioFormatado',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── ETAPA 2: RESUMO + PAGAMENTO ───────────────────────────────────────────────
  Widget _buildEtapa2({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Confirme sua reserva'),
        const SizedBox(height: 16),

        // Card de resumo
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Cabeçalho verde
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_soccer, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      widget.field.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Detalhes
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ResumoRow(
                      icon: Icons.calendar_today,
                      label: 'Data',
                      value: _dataFormatada,
                    ),
                    const Divider(height: 20),
                    _ResumoRow(
                      icon: Icons.access_time,
                      label: _horariosSelecionados.length == 1
                          ? 'Horário'
                          : 'Horários',
                      value: _horarioFormatado,
                    ),
                    const Divider(height: 20),
                    _ResumoRow(
                      icon: Icons.person_outline,
                      label: 'Nome',
                      value: _nomeController.text,
                    ),
                    const Divider(height: 20),
                    _ResumoRow(
                      icon: Icons.phone_outlined,
                      label: 'WhatsApp',
                      value: _telefoneController.text,
                    ),
                    const Divider(height: 20),
                    _ResumoRow(
                      icon: Icons.attach_money,
                      label: _horariosSelecionados.length == 1
                          ? 'Valor'
                          : 'Valor total (${_horariosSelecionados.length}x)',
                      value: 'R\$ ${_valorTotal.toStringAsFixed(2)}',
                      valueStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── SEÇÃO DE PAGAMENTO ────────────────────────────────────────────
        // NOTA: Aqui você irá buscar as configs do admin via ArenaSettingsService.
        // Por enquanto está estático. Quando integrar, substitua pelos dados reais.
        const _SectionTitle(title: 'Forma de pagamento'),
        const SizedBox(height: 10),
        const _PaymentInfoCard(
          // Estes valores virão do ArenaSettingsService no futuro
          aceitaPix: true,
          aceitaLocal: true,
          pixTipo: 'integral', // 'integral' ou 'metade'
          chavePix: '(88) 9 0000-0000', // Placeholder
        ),

        const SizedBox(height: 16),

        // Aviso de confirmação via WhatsApp
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFF9A825), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ao confirmar, você será redirecionado ao WhatsApp do admin para finalizar o pagamento.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        floatingLabelStyle: const TextStyle(color: Color(0xFF2E7D32)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator:
          validator ??
          (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
    );
  }
}

// ── COMPONENTES REUTILIZÁVEIS ─────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int etapaAtual;

  const _StepIndicator({required this.etapaAtual});

  @override
  Widget build(BuildContext context) {
    const steps = ['Data & Hora', 'Seus dados', 'Confirmar'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Linha conectora
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < etapaAtual
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE0E0E0),
              ),
            );
          }

          final idx = i ~/ 2;
          final isActive = idx == etapaAtual;
          final isDone = idx < etapaAtual;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isActive
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE0E0E0),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[idx],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF9E9E9E),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1B1B1B),
        letterSpacing: -0.3,
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String hora;
  final bool isOcupado;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TimeChip({
    required this.hora,
    required this.isOcupado,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOcupado
              ? const Color(0xFFF5F5F5)
              : isSelected
              ? const Color(0xFF2E7D32)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOcupado
                ? const Color(0xFFE0E0E0)
                : isSelected
                ? const Color(0xFF2E7D32)
                : const Color(0xFFBDBDBD),
          ),
        ),
        child: Text(
          isOcupado ? '$hora  ✕' : hora,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isOcupado
                ? const Color(0xFFBDBDBD)
                : isSelected
                ? Colors.white
                : const Color(0xFF1B1B1B),
            decoration: isOcupado ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}

class _ResumoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _ResumoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
        ),
        const Spacer(),
        Text(
          value,
          style:
              valueStyle ??
              const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B1B1B),
              ),
        ),
      ],
    );
  }
}

/// Card de pagamento — parâmetros virão do ArenaSettingsService futuramente
class _PaymentInfoCard extends StatelessWidget {
  final bool aceitaPix;
  final bool aceitaLocal;
  final String pixTipo; // 'integral' ou 'metade'
  final String chavePix;

  const _PaymentInfoCard({
    required this.aceitaPix,
    required this.aceitaLocal,
    required this.pixTipo,
    required this.chavePix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          if (aceitaPix)
            _PaymentOption(
              icon: Icons.pix,
              iconColor: const Color(0xFF00BFA5),
              title: 'Pix',
              subtitle: pixTipo == 'metade'
                  ? 'Pague 50% agora para confirmar a reserva'
                  : 'Pague o valor integral para confirmar',
              extra: chavePix.isNotEmpty
                  ? Row(
                      children: [
                        const Text(
                          'Chave: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                        Text(
                          chavePix,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B1B1B),
                          ),
                        ),
                      ],
                    )
                  : null,
              showDivider: aceitaLocal,
            ),
          if (aceitaLocal)
            _PaymentOption(
              icon: Icons.payments_outlined,
              iconColor: const Color(0xFF2E7D32),
              title: 'Pagamento local',
              subtitle: 'Pague no momento do agendamento',
              showDivider: false,
            ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? extra;
  final bool showDivider;

  const _PaymentOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.extra,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                    if (extra != null) ...[const SizedBox(height: 4), extra!],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int etapaAtual;
  final bool etapa0Completa;
  final bool etapa1Completa;
  final bool isLoading;
  final VoidCallback? onVoltar;
  final VoidCallback onAvancar;

  const _BottomNavBar({
    required this.etapaAtual,
    required this.etapa0Completa,
    required this.etapa1Completa,
    required this.isLoading,
    required this.onVoltar,
    required this.onAvancar,
  });

  bool get _podeAvancar {
    if (etapaAtual == 0) return etapa0Completa;
    if (etapaAtual == 1) return etapa1Completa;
    return true;
  }

  String get _labelAvancar {
    if (etapaAtual == 2) return 'Confirmar e chamar no WhatsApp';
    return 'Continuar';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          if (onVoltar != null) ...[
            OutlinedButton(
              onPressed: onVoltar,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFBDBDBD)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Voltar',
                style: TextStyle(color: Color(0xFF757575)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: (_podeAvancar && !isLoading) ? onAvancar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                disabledBackgroundColor: const Color(0xFFBDBDBD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _labelAvancar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
