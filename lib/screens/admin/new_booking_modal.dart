import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../models/field_model.dart';
import '../../services/booking_service.dart';
import 'components/booking_widgets.dart'; // <--- Importe o arquivo novo

class NewBookingModal extends StatefulWidget {
  final BookingModel? bookingToEdit;

  const NewBookingModal({super.key, this.bookingToEdit});

  @override
  State<NewBookingModal> createState() => _NewBookingModalState();
}

class _NewBookingModalState extends State<NewBookingModal> {
  final _bookingService = BookingService();
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();

  FieldModel? _selectedField;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTimeSlot;

  bool _isLoading = false;
  bool _isLoadingAvailability = false;
  List<TimeOfDay> _occupiedSlots = [];

  late final List<TimeOfDay> _fixedSlots;

  String get _formattedDate =>
      DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate);
  bool get _isEditing => widget.bookingToEdit != null;

  @override
  void initState() {
    super.initState();

    // Busca a regra de negócio no Service
    _fixedSlots = _bookingService.getFixedSlots();

    if (_isEditing) {
      final b = widget.bookingToEdit!;
      _clientNameController.text = b.usuarioNome;
      _selectedDate = b.dataHorarioInicio;
      _selectedTimeSlot = TimeOfDay.fromDateTime(b.dataHorarioInicio);

      // Reconstrói o objeto FieldModel básico para o Dropdown reconhecer
      _selectedField = FieldModel(
        id: b.campoId,
        nome: b.campoNome,
        precoPorHora: b.valorTotal,
        descricao: '',
      );

      _checkAvailability();
    }
  }

  Future<void> _checkAvailability() async {
    if (_selectedField == null) return;

    setState(() {
      _isLoadingAvailability = true;
      _occupiedSlots.clear();
      if (!_isEditing) _selectedTimeSlot = null;
    });

    final busySlots = await _bookingService.getOccupiedSlots(
      _selectedField!.id,
      _selectedDate,
    );

    if (mounted) {
      setState(() {
        _occupiedSlots = busySlots;
        _isLoadingAvailability = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _checkAvailability();
    }
  }

  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate() ||
        _selectedField == null ||
        _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Preencha todos os dados!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validação final de concorrência
    bool isStillOccupied = _occupiedSlots.any((occupied) {
      if (_isEditing) {
        final b = widget.bookingToEdit!;
        final myOriginalTime = TimeOfDay.fromDateTime(b.dataHorarioInicio);

        // Regra de Ouro: Só ignoro o conflito se for o MESMO horário E na MESMA quadra original
        bool isSameTime =
            occupied.hour == myOriginalTime.hour &&
            occupied.minute == myOriginalTime.minute;
        bool isSameField =
            _selectedField!.id ==
            b.campoId; // Verifica se estou na mesma quadra

        if (isSameTime && isSameField) {
          return false; // É a minha própria reserva no lugar original, pode passar.
        }
      }

      // Validação padrão
      return occupied.hour == _selectedTimeSlot!.hour &&
          occupied.minute == _selectedTimeSlot!.minute;
    });

    if (isStillOccupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Este horário está ocupado nesta quadra!",
          ), // Mensagem mais clara
          backgroundColor: Colors.red,
        ),
      );
      _checkAvailability(); // Atualiza a lista para mostrar o vermelho visualmente
      return;
    }

    setState(() => _isLoading = true);

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTimeSlot!.hour,
      _selectedTimeSlot!.minute,
    );
    final endDateTime = startDateTime.add(const Duration(hours: 1));

    final bookingData = BookingModel(
      id: _isEditing ? widget.bookingToEdit!.id : '',
      campoId: _selectedField!.id,
      campoNome: _selectedField!.nome,
      usuarioId: null,
      usuarioNome: _clientNameController.text,
      dataHorarioInicio: startDateTime,
      dataHorarioFim: endDateTime,
      status: 'confirmado',
      valorTotal: _selectedField!.precoPorHora,
    );

    if (_isEditing) {
      await _bookingService.updateBooking(bookingData);
    } else {
      await _bookingService.createBooking(bookingData);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? "Atualizado!" : "Criado!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Reserva?"),
        content: const Text("Essa ação não pode ser desfeita."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Não"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Sim, Excluir",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await _bookingService.cancelBooking(widget.bookingToEdit!.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reserva excluída."),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardSpace),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Text(
                    _isEditing ? "Editar Reserva" : "Novo Agendamento",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. SELETOR DE QUADRA (Extraído)
                  BookingFieldSelector(
                    selectedField: _selectedField,
                    onChanged: (val) async {
                      // Transforme em async
                      setState(() => _selectedField = val);

                      // 1. Busca a disponibilidade da NOVA quadra
                      await _checkAvailability();

                      // 2. Verifica se o horário que estava selecionado agora ficou inválido
                      if (_selectedTimeSlot != null) {
                        // Verifica se o horário atual colide com os ocupados da nova quadra
                        bool nowBusy = _occupiedSlots.any(
                          (oc) =>
                              oc.hour == _selectedTimeSlot!.hour &&
                              oc.minute == _selectedTimeSlot!.minute,
                        );

                        // Lógica para não limpar se for a minha própria reserva (se voltei pra quadra original)
                        bool isMyOriginal = false;
                        if (_isEditing) {
                          final b = widget.bookingToEdit!;
                          final orig = TimeOfDay.fromDateTime(
                            b.dataHorarioInicio,
                          );
                          if (b.campoId == val.id &&
                              orig.hour == _selectedTimeSlot!.hour) {
                            isMyOriginal = true;
                          }
                        }

                        // Se estiver ocupado E não for meu original: Limpa e Avisa
                        if (nowBusy && !isMyOriginal) {
                          setState(() => _selectedTimeSlot = null);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Horário não disponível nesta quadra. Selecione outro.",
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. NOME
                  TextFormField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(
                      labelText: "Nome do Cliente",
                      prefixIcon: Icon(Icons.person, color: Colors.green),
                    ),
                    validator: (v) => v!.isEmpty ? 'Digite o nome' : null,
                  ),
                  const SizedBox(height: 24),

                  // 3. SELETOR DE DATA (Extraído)
                  BookingDateSelector(
                    formattedDate: _formattedDate,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 24),

                  // 4. GRID DE HORÁRIOS (Extraído e mais inteligente)
                  Row(
                    children: [
                      const Text(
                        "Horários:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      if (_isLoadingAvailability)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_selectedField == null)
                    const Center(
                      child: Text(
                        "Selecione uma quadra...",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    BookingTimeGrid(
                      fixedSlots: _fixedSlots,
                      occupiedSlots: _occupiedSlots,
                      selectedSlot: _selectedTimeSlot,
                      isEditing: _isEditing,
                      originalDate: _isEditing
                          ? widget.bookingToEdit!.dataHorarioInicio
                          : null,
                      onSelected: (slot) =>
                          setState(() => _selectedTimeSlot = slot),
                    ),

                  const SizedBox(height: 32),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _selectedTimeSlot == null)
                          ? null
                          : _saveBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isEditing
                                  ? "SALVAR ALTERAÇÕES"
                                  : "CONFIRMAR RESERVA",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _deleteBooking,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        "Cancelar esta Reserva",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
