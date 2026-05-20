import 'package:flutter/material.dart';
import 'new_booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  int _selectedDateIndex = 0;
  int _selectedFieldIndex = 2;
  int _selectedNavIndex = 0;

  final List<String> _tabs = ['Rachas', 'Escola de Futebol'];
  final List<String> _dates = ['Hoje', 'Amanhã', '14/05'];
  final List<String> _fields = ['Campo 1', 'Campo 2', 'Campo 3', 'Campo 4'];

  final List<_BookingItem> _bookings = [
    _BookingItem(
      time: '17:30',
      title: 'Agendado por: Carlos M.',
      isAvailable: false,
    ),
    _BookingItem(
      time: '18:25',
      title: 'Agendado por: Eduardo',
      isAvailable: false,
    ),
    _BookingItem(
      time: '19:20',
      title: 'Agendado por: Eduardo',
      isAvailable: false,
    ),
    _BookingItem(
      time: '20:15',
      title: 'Agendado por: Caio Fre...',
      isAvailable: false,
    ),
    _BookingItem(
      time: '21:10',
      title: 'Agendado por: Vinicius Jr',
      isAvailable: false,
    ),
    _BookingItem(time: '22:05', title: 'Disponível', isAvailable: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text('Pinheiro Society Arena'),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(10),
          child: CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _selectedNavIndex == 0
          ? _buildMainContent()
          : _buildEditFieldsPlaceholder(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() => _selectedNavIndex = index),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Editar Campos',
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTabSelector(),
            const SizedBox(height: 18),
            _buildDateSelector(),
            const SizedBox(height: 18),
            _buildFieldChips(),
            const SizedBox(height: 18),
            ..._bookings.map((booking) => _buildBookingCard(booking)).toList(),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewBookingScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Novo Agendamento +',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEditFieldsPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.edit, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Editar Campos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Aqui você poderá editar campos em breve.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Row(
      children: List.generate(_tabs.length, (index) {
        final selected = index == _selectedTab;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : Colors.green.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.green : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: List.generate(_dates.length, (index) {
        final selected = index == _selectedDateIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == _dates.length - 1 ? 0 : 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: selected ? Colors.green : Colors.grey[200],
                foregroundColor: selected ? Colors.white : Colors.black87,
                side: BorderSide(
                  color: selected ? Colors.green : Colors.grey.shade300,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => setState(() => _selectedDateIndex = index),
              child: Text(_dates[index]),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFieldChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_fields.length, (index) {
            final selected = index == _selectedFieldIndex;
            return Padding(
              padding: EdgeInsets.only(
                right: index == _fields.length - 1 ? 0 : 8,
              ),
              child: ChoiceChip(
                selectedColor: Colors.green,
                backgroundColor: Colors.grey[200],
                label: Text(
                  _fields[index],
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
                selected: selected,
                onSelected: (_) => setState(() => _selectedFieldIndex = index),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBookingCard(_BookingItem booking) {
    final available = booking.isAvailable;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: available ? Colors.grey[200] : Colors.green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.time,
                style: TextStyle(
                  color: available ? Colors.black87 : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                booking.title,
                style: TextStyle(
                  color: available ? Colors.black54 : Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (!available)
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.menu, color: Colors.white),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add, color: Colors.black54),
            ),
        ],
      ),
    );
  }
}

class _BookingItem {
  final String time;
  final String title;
  final bool isAvailable;

  _BookingItem({
    required this.time,
    required this.title,
    required this.isAvailable,
  });
}
