import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking_model.dart';
import '../../models/field_model.dart';
import '../../services/booking_service.dart';
import '../../services/user_services.dart';

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

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();

  DateTime _dataSelecionada = DateTime.now();
  TimeOfDay? _horarioSelecionado;

  bool _isLoading = false;
  List<TimeOfDay> _horariosOcupados = [];

  @override
  void initState() {
    super.initState();
    _carregarHorariosOcupados();
  }

  // Faz a consulta no banco sempre que o usuário muda a data
  Future<void> _carregarHorariosOcupados() async {
    setState(() => _horarioSelecionado = null); // Reseta a escolha anterior
    final ocupados = await _bookingService.getOccupiedSlots(
      widget.field.id,
      _dataSelecionada,
    );

    if (mounted) {
      setState(() {
        _horariosOcupados = ocupados;
      });
    }
  }

  Future<void> _finalizarReserva() async {
    if (!_formKey.currentState!.validate()) return;
    if (_horarioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um horário.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Busca ou Cria o cliente no banco
      final cliente = await _userServices.getOrCreateGuestUser(
        _nomeController.text.trim(),
        _telefoneController.text.trim(),
      );

      // 2. Calcula as datas
      final dataInicio = DateTime(
        _dataSelecionada.year,
        _dataSelecionada.month,
        _dataSelecionada.day,
        _horarioSelecionado!.hour,
        _horarioSelecionado!.minute,
      );
      final dataFim = dataInicio.add(
        Duration(hours: 1, minutes: widget.field.intervaloMinutos),
      );

      // 3. Cria a reserva atrelada ao ID desse cliente
      final novaReserva = BookingModel(
        id: '',
        campoId: widget.field.id,
        campoNome: widget.field.nome,
        usuarioId: cliente.id, // <--- A MÁGICA ACONTECE AQUI!
        usuarioNome: cliente.nome,
        dataHorarioInicio: dataInicio,
        dataHorarioFim: dataFim,
        status: 'pendente',
        valorTotal: widget.field.precoPorHora,
      );

      await _bookingService.createBooking(novaReserva);
      _abrirWhatsApp(novaReserva);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao reservar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _abrirWhatsApp(BookingModel reserva) async {
    // DDD e número real do administrador da arena
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
        "Aguardo a chave Pix para confirmar!";

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

  @override
  Widget build(BuildContext context) {
    // Busca os horários que você determinou no service
    final horariosDisponiveis = _bookingService.getFixedSlots();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.field.nome),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- SEÇÃO 1: DATA E HORA ---
                  const Text(
                    '1. Escolha a Data e Horário',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Seletor de Data
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    leading: const Icon(
                      Icons.calendar_today,
                      color: Colors.green,
                    ),
                    title: Text(
                      "Data: ${_dataSelecionada.day.toString().padLeft(2, '0')}/${_dataSelecionada.month.toString().padLeft(2, '0')}/${_dataSelecionada.year}",
                    ),
                    trailing: const Text(
                      "Alterar",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final dataEscolhida = await showDatePicker(
                        context: context,
                        initialDate: _dataSelecionada,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (dataEscolhida != null &&
                          dataEscolhida != _dataSelecionada) {
                        setState(() => _dataSelecionada = dataEscolhida);
                        _carregarHorariosOcupados(); // Recarrega do banco se mudar o dia
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Grid Inteligente de Horários
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: horariosDisponiveis.map((horario) {
                      final isOcupado = _horariosOcupados.contains(horario);
                      final isSelected = _horarioSelecionado == horario;

                      final horaFormatada =
                          "${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}";

                      return ChoiceChip(
                        label: Text(
                          isOcupado
                              ? "$horaFormatada (Ocupado)"
                              : horaFormatada,
                        ),
                        selected: isSelected,
                        selectedColor: Colors.green,
                        disabledColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: isOcupado
                              ? Colors.grey
                              : (isSelected ? Colors.white : Colors.black87),
                          decoration: isOcupado
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        onSelected: isOcupado
                            ? null
                            : (selected) {
                                setState(
                                  () => _horarioSelecionado = selected
                                      ? horario
                                      : null,
                                );
                              },
                      );
                    }).toList(),
                  ),
                  const Divider(height: 48),

                  // --- SEÇÃO 2: DADOS DO CLIENTE ---
                  const Text(
                    '2. Seus Dados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Como você se chama?',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Informe seu nome' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Seu WhatsApp (com DDD)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (val) => val == null || val.length < 10
                        ? 'Informe um WhatsApp válido'
                        : null,
                  ),

                  const SizedBox(height: 32),

                  // --- BOTÃO FINAL ---
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _finalizarReserva,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Reservar e Chamar no WhatsApp',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
