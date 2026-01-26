import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/field_model.dart';

// --- SELETOR DE DATA ---
class BookingDateSelector extends StatelessWidget {
  final String formattedDate;
  final VoidCallback onTap;

  const BookingDateSelector({
    super.key,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: "Data do Jogo",
          prefixIcon: Icon(Icons.calendar_month, color: Colors.green),
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// --- SELETOR DE QUADRA (Com Correção de Identidade de Objeto) ---
class BookingFieldSelector extends StatelessWidget {
  final FieldModel? selectedField;
  final Function(FieldModel) onChanged;

  const BookingFieldSelector({
    super.key,
    required this.selectedField,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('fields').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator(color: Colors.green);
        }

        // 1. Converte snapshot para Lista tipada
        List<FieldModel> allFields = snapshot.data!.docs.map((doc) {
          return FieldModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // 2. Cria os itens visuais
        List<DropdownMenuItem<FieldModel>> items = allFields.map((field) {
          return DropdownMenuItem(value: field, child: Text(field.nome));
        }).toList();

        // 3. A MÁGICA: Encontra o objeto REAL da lista que bate com o ID selecionado.
        // Isso evita o erro: "There should be exactly one item with DropdownButton's value"
        FieldModel? valueToUse;

        if (selectedField != null) {
          try {
            valueToUse = allFields.firstWhere((f) => f.id == selectedField!.id);
          } catch (e) {
            valueToUse = null; // Quadra deletada ou não encontrada
          }
        }

        return DropdownButtonFormField<FieldModel>(
          value: valueToUse,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "Quadra",
            prefixIcon: Icon(Icons.stadium, color: Colors.green),
          ),
          items: items,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        );
      },
    );
  }
}

// --- GRID DE HORÁRIOS (Com Lógica de Edição e Dia Lotado) ---
class BookingTimeGrid extends StatelessWidget {
  final List<TimeOfDay> fixedSlots;
  final List<TimeOfDay> occupiedSlots;
  final TimeOfDay? selectedSlot;
  final Function(TimeOfDay?) onSelected;

  // Parâmetros para lógica de edição
  final bool isEditing;
  final DateTime? originalDate;
  final String? originalFieldId;
  final String? currentFieldId;

  const BookingTimeGrid({
    super.key,
    required this.fixedSlots,
    required this.occupiedSlots,
    required this.selectedSlot,
    required this.onSelected,
    this.isEditing = false,
    this.originalDate,
    this.originalFieldId,
    this.currentFieldId,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Verificação de "Dia Lotado"
    // Calcula se todos os slots estão ocupados (considerando a regra de exceção da edição)
    bool isFull = fixedSlots.every((slot) {
      return occupiedSlots.any((oc) {
        if (isEditing &&
            originalDate != null &&
            originalFieldId == currentFieldId) {
          final original = TimeOfDay.fromDateTime(originalDate!);
          if (oc.hour == original.hour && oc.minute == original.minute)
            return false;
        }
        return oc.hour == slot.hour && oc.minute == slot.minute;
      });
    });

    if (isFull) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.sentiment_dissatisfied,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              "Dia Lotado!",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              "Não há horários livres nesta quadra.",
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // 2. Renderização Normal dos Slots
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: fixedSlots.map((slot) {
        // LÓGICA DE OCUPAÇÃO INTELIGENTE
        final bool isOccupied = occupiedSlots.any((oc) {
          if (isEditing && originalDate != null) {
            final original = TimeOfDay.fromDateTime(originalDate!);

            // Regra: Só libera se for o mesmo horário E a mesma quadra original
            bool isSameTime =
                (oc.hour == original.hour && oc.minute == original.minute);
            bool isSameField = (originalFieldId == currentFieldId);

            if (isSameTime && isSameField)
              return false; // É minha reserva, libera.
          }
          return oc.hour == slot.hour && oc.minute == slot.minute;
        });

        final bool isSelected = selectedSlot == slot;
        final startHour =
            "${slot.hour}:${slot.minute.toString().padLeft(2, '0')}";
        final endHour =
            "${slot.hour + 1}:${slot.minute.toString().padLeft(2, '0')}";
        final labelText = "$startHour - $endHour";

        return ChoiceChip(
          label: SizedBox(
            width: 110,
            child: Text(
              labelText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isOccupied
                    ? Colors.red.withOpacity(0.6)
                    : (isSelected ? Colors.white : Colors.black),
                decoration: isOccupied ? TextDecoration.lineThrough : null,
                fontWeight: isOccupied ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          selected: isSelected,
          selectedColor: Colors.green,
          disabledColor: Colors.red.withOpacity(0.05),
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: isOccupied
              ? null
              : (val) => onSelected(val ? slot : null),
        );
      }).toList(),
    );
  }
}
