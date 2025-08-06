import 'package:flutter/material.dart';

class _ResumenCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final Color iconColor;
  const _ResumenCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.iconColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Icon(icon, color: iconColor),
            ],
          ),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardVisita extends StatelessWidget {
  final Map<String, dynamic> user;

  const DashboardVisita({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nombre = (user['nombre'] ?? '') + ' ' + (user['apellido'] ?? '');
    final telefono = user['telefono'] ?? 'Sin teléfono';
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Visita'),
        backgroundColor: Color(0xFF009688),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nombre: ' + (nombre.isEmpty ? 'Sin nombre' : nombre),
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 12),
            Text('Teléfono: $telefono', style: TextStyle(fontSize: 16)),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ResumenCard(
                    label: 'Apartamento MES',
                    value: 0,
                    color: Colors.blue,
                    icon: Icons.apartment,
                    iconColor: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _ResumenCard(
                    label: 'HORAS',
                    value: 0,
                    color: Colors.green,
                    icon: Icons.timer,
                    iconColor: Colors.green,
                  ),
                ),
                Expanded(
                  child: _ResumenCard(
                    label: 'Limpiezas Hoy',
                    value: 8,
                    color: Colors.orange,
                    icon: Icons.cleaning_services,
                    iconColor: Colors.orange,
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
