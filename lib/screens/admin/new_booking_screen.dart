import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final List<Map<String, String>> _fields = [
    {'name': 'Campo 1', 'type': 'Society - Sintético', 'price': 'R\$ 40,00'},
    {'name': 'Campo 2', 'type': 'Society - Sintético', 'price': 'R\$ 40,00'},
  ];

  final List<Map<String, dynamic>> _timeSlots = [
    {'time': '17:30', 'enabled': false},
    {'time': '18:25', 'enabled': true},
    {'time': '19:20', 'enabled': false},
    {'time': '20:15', 'enabled': false},
    {'time': '21:10', 'enabled': true},
    {'time': '22:05', 'enabled': true},
  ];

  DateTime _selectedDate = DateTime.now();
  int _selectedFieldIndex = 0;
  String _selectedSlot = '18:25';
  String _selectedPayment = 'pix';

  String get _formattedDate =>
      DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedField = _fields[_selectedFieldIndex];
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pinheiro Society Arena'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateCard(),
            const SizedBox(height: 18),
            _buildFieldSelector(),
            const SizedBox(height: 18),
            _buildTimeSlotGrid(),
            const SizedBox(height: 18),
            _buildSummaryCard(selectedField),
            const SizedBox(height: 16),
            _buildPaymentSelectors(),
            const SizedBox(height: 22),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Data da Reserva:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formattedDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.calendar_today, color: Colors.green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Selecione um Campo:',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _fields.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final field = _fields[index];
              final selected = index == _selectedFieldIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedFieldIndex = index),
                child: Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.green : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: const Icon(
                            Icons.sports_soccer,
                            size: 72,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              field['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              field['type']!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  field['price']!,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Horários',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _timeSlots.map((slot) {
            final enabled = slot['enabled'] as bool;
            final time = slot['time'] as String;
            final selected = time == _selectedSlot;
            return GestureDetector(
              onTap: enabled
                  ? () => setState(() => _selectedSlot = time)
                  : null,
              child: Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.green
                      : enabled
                      ? Colors.white
                      : Colors.grey.shade200,
                  border: Border.all(
                    color: selected
                        ? Colors.green
                        : enabled
                        ? Colors.grey.shade300
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    time,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : enabled
                          ? Colors.black87
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, String> selectedField) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Resumo:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Data:', _formattedDate),
          _buildSummaryRow('Hora:', _selectedSlot),
          _buildSummaryRow('Campo:', selectedField['name']!),
          _buildSummaryRow('Valor:', selectedField['price']!),
          _buildSummaryRow('Reservado por:', 'Eduardo Cavalcante'),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Forma de Pagamento:',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Escolhido:',
            _selectedPayment == 'pix' ? 'Pix' : 'Cartão',
          ),
          const SizedBox(height: 12),
          const Text(
            'Verificar Disponibilidade de Adicionais',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Forma de Pagamento',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPayment == 'pix'
                      ? Colors.green
                      : Colors.grey.shade200,
                  foregroundColor: _selectedPayment == 'pix'
                      ? Colors.white
                      : Colors.black87,
                ),
                onPressed: () => setState(() => _selectedPayment = 'pix'),
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('Pix'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPayment == 'cartao'
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  foregroundColor: _selectedPayment == 'cartao'
                      ? Colors.white
                      : Colors.black87,
                ),
                onPressed: () => setState(() => _selectedPayment = 'cartao'),
                icon: const Icon(Icons.credit_card, size: 18),
                label: const Text('Cartão'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Agendamento confirmado!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Ok', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.shade400),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Cancelar Reserva',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
