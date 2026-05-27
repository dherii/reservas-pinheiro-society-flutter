import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/field_model.dart';

class BookingService {
  final CollectionReference _bookingsCollection = FirebaseFirestore.instance
      .collection('bookings');

  // ── CRIAR UMA RESERVA ─────────────────────────────────────────────────────
  Future<void> createBooking(BookingModel booking) async {
    await _bookingsCollection.add(booking.toMap());
  }

  /// Cria múltiplas reservas de uma vez (seleção de vários horários pelo cliente).
  /// Usa batch para garantir atomicidade — ou tudo salva, ou nada.
  Future<void> createMultipleBookings(List<BookingModel> bookings) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final booking in bookings) {
      final docRef = _bookingsCollection.doc();
      batch.set(docRef, booking.toMap());
    }
    await batch.commit();
  }

  // ── BUSCAR RESERVAS DE UM DIA ─────────────────────────────────────────────
  Stream<List<BookingModel>> getBookingsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _bookingsCollection
        .where(
          'dataHorarioInicio',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'dataHorarioInicio',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
        )
        .orderBy('dataHorarioInicio')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => BookingModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // ── SLOTS OCUPADOS (para marcar chips como indisponíveis) ─────────────────
  Future<List<TimeOfDay>> getOccupiedSlots(
    String fieldId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

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
          .where('status', whereNotIn: ['cancelado'])
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final start = (data['dataHorarioInicio'] as Timestamp).toDate();
        return TimeOfDay.fromDateTime(start);
      }).toList();
    } catch (e) {
      debugPrint("Erro ao buscar slots ocupados: $e");
      return [];
    }
  }

  // ── SLOTS DINÂMICOS (substitui o getFixedSlots hardcoded) ────────────────
  /// Gera os slots disponíveis com base nas configurações do campo.
  /// Filtra também os horários bloqueados pelo admin.
  List<DateTime> getDynamicSlots(FieldModel field, DateTime date) {
    final allSlots = field.getSlotsForDate(date);

    // Remove horários bloqueados pelo admin
    return allSlots.where((slot) {
      final slotStr =
          '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}';
      return !field.horariosBloqueados.contains(slotStr);
    }).toList();
  }

  // ── CANCELAR / ATUALIZAR ──────────────────────────────────────────────────
  Future<void> cancelBooking(String bookingId) async {
    await _bookingsCollection.doc(bookingId).delete();
  }

  Future<void> updateBooking(BookingModel booking) async {
    await _bookingsCollection.doc(booking.id).update(booking.toMap());
  }

  // ── LEGADO: mantido para compatibilidade com NewBookingModal do admin ─────
  // Será removido quando o modal do admin for atualizado para usar FieldModel.
  List<TimeOfDay> getFixedSlots() {
    return const [
      TimeOfDay(hour: 17, minute: 0),
      TimeOfDay(hour: 18, minute: 10),
      TimeOfDay(hour: 19, minute: 20),
      TimeOfDay(hour: 20, minute: 30),
      TimeOfDay(hour: 21, minute: 40),
    ];
  }
}
