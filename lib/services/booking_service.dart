import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Necessário para usar TimeOfDay
import '../models/booking_model.dart';

class BookingService {
  final CollectionReference _bookingsCollection = FirebaseFirestore.instance
      .collection('bookings');

  // Criar uma nova reserva
  Future<void> createBooking(BookingModel booking) async {
    await _bookingsCollection.add(booking.toMap());
  }

  // Buscar reservas de um dia específico (Para a lista da Home)
  Stream<List<BookingModel>> getBookingsForDate(DateTime date) {
    DateTime startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _bookingsCollection
        .where(
          'dataHorarioInicio', // Nome correto do campo no Firebase
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'dataHorarioInicio',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
        )
        .orderBy('dataHorarioInicio')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BookingModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  // Verificar quais horários estão ocupados em uma quadra/dia
  Future<List<TimeOfDay>> getOccupiedSlots(
    String fieldId,
    DateTime date,
  ) async {
    DateTime startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      final snapshot = await _bookingsCollection
          .where('campoId', isEqualTo: fieldId)
          .where(
            'dataHorarioInicio',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'dataHorarioInicio',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Converte o Timestamp do banco para DateTime e depois extrai a Hora/Minuto
        final start = (data['dataHorarioInicio'] as Timestamp).toDate();
        return TimeOfDay.fromDateTime(start);
      }).toList();
    } catch (e) {
      debugPrint("Erro ao buscar slots ocupados: $e");
      return []; // Retorna lista vazia em caso de erro para não travar o app
    }
  }

  // Cancelar reserva
  Future<void> cancelBooking(String bookingId) async {
    await _bookingsCollection.doc(bookingId).delete();
  }

  Future<void> updateBooking(BookingModel booking) async {
    await _bookingsCollection.doc(booking.id).update(booking.toMap());
  }

  List<TimeOfDay> getFixedSlots() {
    return const [
      TimeOfDay(hour: 17, minute: 10),
      TimeOfDay(hour: 18, minute: 20),
      TimeOfDay(hour: 19, minute: 30),
      TimeOfDay(hour: 20, minute: 40),
      TimeOfDay(hour: 21, minute: 50),
    ];
  }
}
