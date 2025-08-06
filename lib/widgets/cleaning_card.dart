import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CleaningCard extends StatelessWidget {
  final Map<String, dynamic> cleaningData;
  final Map<String, dynamic> apartmentData;
  final String docId;
  final bool showButtons;
  final bool isOperario;

  const CleaningCard({
    Key? key,
    required this.cleaningData,
    required this.apartmentData,
    required this.docId,
    this.showButtons = true,
    this.isOperario = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Procesar el nombre para extraer partes
    final raw = cleaningData['nombre'] ?? '';
    String nombre = raw;
    String salida = '';
    String entrada = '';
    String pax = '';
    String noches = '';
    String nota = '';

    // Regex para formato especial y parsing flexible
    final regex = RegExp(
      r'^(.*?)\s*>>>?\s*OUT\s*(\d{1,2}:?\d{0,2})\s*\+?\s*IN\s*(\d{1,2}:?\d{0,2})\s*PAX\s*(\d+)\s*H\s*(\d+)\s*N.*?(PREPARA\s*PER\s*\d+)?',
      caseSensitive: false,
    );
    final match = regex.firstMatch(raw);
    if (match != null) {
      nombre = match.group(1)?.trim() ?? nombre;
      salida = match.group(2) ?? '';
      entrada = match.group(3) ?? '';
      pax = match.group(4) ?? '';
      noches = match.group(5) ?? '';
      nota = match.group(6) ?? '';
    } else {
      // Si el nombre contiene OUT, IN, PAX, etc, intentar extraer manualmente
      final outMatch = RegExp(r'OUT\s*(\d{1,2}:?\d{0,2})').firstMatch(raw);
      final inMatch = RegExp(r'IN\s*(\d{1,2}:?\d{0,2})').firstMatch(raw);
      final paxMatch = RegExp(r'(\d+)\s*PAX').firstMatch(raw);
      final nochesMatch = RegExp(r'(\d+)\s*N').firstMatch(raw);
      final notaMatch = RegExp(r'PREPARA\s*PER\s*(\d+)').firstMatch(raw);
      salida = outMatch?.group(1) ?? cleaningData['salida']?.toString() ?? '';
      entrada = inMatch?.group(1) ?? cleaningData['entrada']?.toString() ?? '';
      pax = paxMatch?.group(1) ?? cleaningData['pax']?.toString() ?? '';
      noches =
          nochesMatch?.group(1) ?? cleaningData['noches']?.toString() ?? '';
      nota = notaMatch != null
          ? 'PREPARA PER ${notaMatch.group(1)}'
          : cleaningData['nota'] ?? '';
      // El nombre es lo que está antes de '>>>' si existe
      if (raw.contains('>>>')) {
        nombre = raw.split('>>>').first.trim();
      }
    }

    // Estado de limpieza
    String estado = cleaningData['estado'] ?? 'Pendiente';

    // Construir lista dinámica para la fila de datos
    List<Widget> infoWidgets = [];
    if (salida.isNotEmpty) {
      infoWidgets.addAll([
        Icon(Icons.logout, size: 18, color: Colors.red),
        SizedBox(width: 4),
        Text(salida),
      ]);
    }
    if (salida.isNotEmpty &&
        (entrada.isNotEmpty || pax.isNotEmpty || noches.isNotEmpty)) {
      infoWidgets.add(SizedBox(width: 12));
    }
    if (entrada.isNotEmpty) {
      infoWidgets.addAll([
        Icon(Icons.login, size: 18, color: Colors.green),
        SizedBox(width: 4),
        Text(entrada),
      ]);
    }
    if (entrada.isNotEmpty && (pax.isNotEmpty || noches.isNotEmpty)) {
      infoWidgets.add(SizedBox(width: 12));
    }
    if (pax.isNotEmpty) {
      infoWidgets.addAll([
        Icon(Icons.people, size: 18, color: Colors.blue),
        SizedBox(width: 4),
        Text('$pax PAX'),
      ]);
    }
    if (pax.isNotEmpty && noches.isNotEmpty) {
      infoWidgets.add(SizedBox(width: 12));
    }
    if (noches.isNotEmpty) {
      infoWidgets.addAll([
        Icon(Icons.nightlight_round, size: 18, color: Colors.purple),
        SizedBox(width: 4),
        Text(noches),
      ]);
    }

    // Widget para la nota
    Widget? notaWidget;
    if (nota.isNotEmpty) {
      notaWidget = Column(
        children: [
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.folder, size: 18, color: Colors.orange),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  nota,
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      );
    }

    void actualizarEstado(String nuevoEstado) async {
      // Actualiza en Firestore
      await Future.delayed(Duration(milliseconds: 200));
      try {
        await FirebaseFirestore.instance
            .collection('itinerarios_v2')
            .doc(docId)
            .update({'estado': nuevoEstado});
      } catch (e) {}
      // Actualiza la UI
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a $nuevoEstado')),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: Color(0xFFF7F5FF),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.apartment, color: Color(0xFF6A82FB), size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.5,
                      color: Color(0xFF22223B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            if (infoWidgets.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: infoWidgets,
              ),
            if (notaWidget != null) ...[SizedBox(height: 10), notaWidget],
            // Estado y botones solo para operario
            if (isOperario) ...[
              SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Estado: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: estado == 'Pendiente'
                          ? Colors.grey[200]
                          : estado == 'En proceso'
                          ? Colors.orange[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      estado,
                      style: TextStyle(
                        color: estado == 'Pendiente'
                            ? Colors.grey
                            : estado == 'En proceso'
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: estado == 'Pendiente'
                        ? () => actualizarEstado('En proceso')
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Inicio'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: estado == 'En proceso'
                        ? () => actualizarEstado('Finalizado')
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Termina'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
