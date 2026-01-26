import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../models/field_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'add_field_modal.dart';
import 'new_booking_modal.dart';

class AdminHomeScreen extends StatefulWidget {
  final UserModel user;

  const AdminHomeScreen({super.key, required this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Estado dos Filtros
  DateTime _selectedDate = DateTime.now();
  String? _selectedFieldId; // Se null, mostra "Todos"

  // Helpers de Data
  String get _dateTitle {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selected == today) return "Hoje";
    if (selected == today.add(const Duration(days: 1))) return "Amanhã";
    if (selected == today.subtract(const Duration(days: 1))) return "Ontem";

    return DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate);
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // --- WIDGETS DE UI ---

  // 1. Navegador de Data (< DATA >)
  Widget _buildDateHeader() {
    return Container(
      color: Colors.green,
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => _changeDate(-1),
          ),
          InkWell(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _dateTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  // 2. Lista Horizontal de Quadras (Tabs)
  Widget _buildFieldTabs() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('fields').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final fields = snapshot.data!.docs;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              // Botão "Todos"
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text("Todos"),
                  selected: _selectedFieldId == null,
                  onSelected: (bool selected) {
                    setState(() => _selectedFieldId = null);
                  },
                  selectedColor: Colors.green.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _selectedFieldId == null
                        ? Colors.green
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Botões das Quadras Reais
              ...fields.map((doc) {
                final field = FieldModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
                final isSelected = _selectedFieldId == field.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(field.nome),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(
                        () => _selectedFieldId = selected ? field.id : null,
                      );
                    },
                    selectedColor: Colors.green.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.green : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // 3. Lista de Reservas (Filtrada e com NOVO CARD)
  Widget _buildBookingList() {
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      0,
      0,
    );
    final endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );

    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where(
          'dataHorarioInicio',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'dataHorarioInicio',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
        );

    if (_selectedFieldId != null) {
      query = query.where('campoId', isEqualTo: _selectedFieldId);
    }

    query = query.orderBy('dataHorarioInicio');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text("Erro ao carregar. Verifique sua conexão."),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(
                  "Agenda livre para ${_dateTitle}!",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final booking = BookingModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );

            final timeStr = DateFormat(
              'HH:mm',
            ).format(booking.dataHorarioInicio);
            final endTimeStr = DateFormat(
              'HH:mm',
            ).format(booking.dataHorarioFim);

            // --- AQUI ESTÁ O NOVO DESIGN DO CARD ---
            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Ao clicar, abrimos o Modal em modo de EDIÇÃO
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        NewBookingModal(bookingToEdit: booking),
                  );
                },
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      // 1. Faixa Lateral Verde (Indicador Visual)
                      Container(
                        width: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),

                      // 2. Coluna de Horário
                      Container(
                        width: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "até $endTimeStr",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3. Conteúdo Principal (Infos)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                booking.usuarioNome,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.stadium,
                                    size: 14,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    booking.campoNome,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "R\$ ${booking.valorTotal.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 4. Ícone de Seta (Indicando clique)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Painel de Controle"),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.stadium),
            tooltip: "Gerenciar Quadras",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddFieldModal(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateHeader(), // 1. Navegação de Data
          _buildFieldTabs(), // 2. Abas de Quadras
          Expanded(child: _buildBookingList()), // 3. Lista Filtrada
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.calendar_month, color: Colors.white),
        label: const Text(
          "Nova Reserva",
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const NewBookingModal(),
          );
        },
      ),
    );
  }
}
