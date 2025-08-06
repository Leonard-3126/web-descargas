import 'package:flutter/material.dart';

class DashboardApartmentCard extends StatelessWidget {
  final String nombre;
  final int? entrada;
  final int? salida;
  final int? pax;
  final int? noches;
  final String? nota;

  const DashboardApartmentCard({
    Key? key,
    required this.nombre,
    this.entrada,
    this.salida,
    this.pax,
    this.noches,
    this.nota,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.apartment, color: Color(0xFF6A82FB)),
                SizedBox(width: 8),
                Text(
                  nombre,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.logout, size: 18, color: Colors.red),
                SizedBox(width: 4),
                Text(salida != null ? '$salida' : '-'),
                SizedBox(width: 12),
                Icon(Icons.login, size: 18, color: Colors.green),
                SizedBox(width: 4),
                Text(entrada != null ? '$entrada' : '-'),
                SizedBox(width: 12),
                Icon(Icons.people, size: 18, color: Colors.blue),
                SizedBox(width: 4),
                Text(pax != null ? '$pax PAX' : '-'),
                SizedBox(width: 12),
                Icon(Icons.nightlight_round, size: 18, color: Colors.purple),
                SizedBox(width: 4),
                Text(noches != null ? '$noches' : '-'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.note, size: 18, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  nota ?? '',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
