import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../models/field_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'new_booking_modal.dart';
import 'admin_settings_screen.dart';
import 'field_management_screen.dart'; // <-- NOVA TELA

class AdminHomeScreen extends StatefulWidget {
  final UserModel user;

  const AdminHomeScreen({super.key, required this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedFieldId;

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

  void _changeDate(int days) =>
      setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── DASHBOARD: métricas do mês atual ────────────────────────────────────────
  Widget _buildDashboard() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where(
            'dataHorarioInicio',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where(
            'dataHorarioInicio',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
          )
          .snapshots(),
      builder: (context, snapshot) {
        int totalMes = 0;
        int confirmados = 0;
        double receitaEstimada = 0;

        if (snapshot.hasData) {
          final bookings = snapshot.data!.docs
              .map(
                (d) => BookingModel.fromMap(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ),
              )
              .toList();

          totalMes = bookings.length;
          confirmados = bookings.where((b) => b.status == 'confirmado').length;
          receitaEstimada = bookings
              .where((b) => b.status != 'cancelado')
              .fold(0.0, (sum, b) => sum + b.valorTotal);
        }

        return Container(
          color: const Color(0xFF2E7D32),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  DateFormat("MMMM 'de' yyyy", 'pt_BR').format(now),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                children: [
                  _MetricCard(
                    label: 'Reservas no mês',
                    value: '$totalMes',
                    icon: Icons.calendar_month,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  _MetricCard(
                    label: 'Confirmadas',
                    value: '$confirmados',
                    icon: Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  _MetricCard(
                    label: 'Receita estimada',
                    value: 'R\$\n${receitaEstimada.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── NAVEGAÇÃO DE DATA ────────────────────────────────────────────────────────
  Widget _buildDateHeader() {
    return Container(
      color: const Color(0xFF2E7D32),
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
            borderRadius: BorderRadius.circular(20),
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
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _dateTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
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

  // ── TABS DE QUADRAS ──────────────────────────────────────────────────────────
  Widget _buildFieldTabs() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('fields').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 52);

        final fields = snapshot.data!.docs;

        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _FieldTab(
                label: 'Todos',
                isSelected: _selectedFieldId == null,
                onTap: () => setState(() => _selectedFieldId = null),
              ),
              ...fields.map((doc) {
                final field = FieldModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
                return _FieldTab(
                  label: field.nome,
                  isSelected: _selectedFieldId == field.id,
                  onTap: () => setState(() => _selectedFieldId = field.id),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── LISTA DE RESERVAS ────────────────────────────────────────────────────────
  Widget _buildBookingList() {
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
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
        )
        .orderBy('dataHorarioInicio');

    if (_selectedFieldId != null) {
      query = query.where('campoId', isEqualTo: _selectedFieldId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma reserva para $_dateTitle',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!.docs
            .map(
              (d) =>
                  BookingModel.fromMap(d.data() as Map<String, dynamic>, d.id),
            )
            .toList();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _BookingCard(
              booking: booking,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => NewBookingModal(bookingToEdit: booking),
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
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text(
          'Painel de Controle',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.stadium_outlined),
            tooltip: 'Gerenciar Campos',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FieldManagementScreen()),
            ),
          ),
          // NOVO: botão de configurações
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDashboard(), // ← NOVO: métricas do mês
          _buildDateHeader(),
          _buildFieldTabs(),
          Expanded(child: _buildBookingList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.calendar_month, color: Colors.white),
        label: const Text(
          'Nova Reserva',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const NewBookingModal(),
        ),
      ),
    );
  }
}

// ── COMPONENTES ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.75),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FieldTab({
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
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
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

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusText;

    switch (booking.status) {
      case 'confirmado':
        statusColor = const Color(0xFF2E7D32);
        statusText = 'Confirmado';
        break;
      case 'cancelado':
        statusColor = const Color(0xFFD32F2F);
        statusText = 'Cancelado';
        break;
      case 'concluido':
        statusColor = const Color(0xFF1565C0);
        statusText = 'Concluído';
        break;
      default:
        statusColor = const Color(0xFFF57C00);
        statusText = 'Pendente';
    }

    final timeStr =
        "${booking.dataHorarioInicio.hour.toString().padLeft(2, '0')}:${booking.dataHorarioInicio.minute.toString().padLeft(2, '0')}";
    final endTimeStr =
        "${booking.dataHorarioFim.hour.toString().padLeft(2, '0')}:${booking.dataHorarioFim.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Faixa lateral de status
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),

            // Horário
            Container(
              width: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B1B1B),
                    ),
                  ),
                  Text(
                    'até $endTimeStr',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Conteúdo principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.usuarioNome,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.stadium_outlined,
                          size: 12,
                          color: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.campoNome,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'R\$ ${booking.valorTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
