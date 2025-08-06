// ignore_for_file: unused_field, unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HorarioScreen extends StatefulWidget {
  @override
  _HorarioScreenState createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen> {
  String _totalHorasTrabajadasMes = '00:00';
  // ...existing code...

  DateTime? _inicio;
  Duration _transcurrido = Duration.zero;
  bool _corriendo = false;
  late final Ticker _ticker;
  List<Map<String, dynamic>> _historial = [];
  String? _email;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick);
    _restaurarEstadoCronometro();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _cargarHistorial();
      await _calcularTotalMes();
    });
  }

  Future<void> _restaurarEstadoCronometro() async {
    final prefs = await SharedPreferences.getInstance();
    final corriendo = prefs.getBool('horario_corriendo') ?? false;
    final inicioStr = prefs.getString('horario_inicio');
    if (corriendo && inicioStr != null) {
      final inicio = DateTime.tryParse(inicioStr);
      if (inicio != null) {
        setState(() {
          _inicio = inicio;
          _corriendo = true;
          _transcurrido = DateTime.now().difference(_inicio!);
        });
        _ticker.start();
      }
    }
  }

  Future<void> _cargarHistorial() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.user?.email ?? 'sin_email';
    _email = email;
    final colRef = FirebaseFirestore.instance
        .collection('area_supervisor')
        .doc('usuarios')
        .collection('usuarios')
        .doc(email)
        .collection('historial');
    final snap = await colRef.orderBy('fecha', descending: true).get();
    setState(() {
      _historial = snap.docs.map((d) => d.data()).toList();
    });
  }

  Future<void> _calcularTotalMes() async {
    final now = DateTime.now();
    final mesActual = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    int totalMin = 0;
    for (final h in _historial) {
      final fecha = h['fecha'] ?? '';
      if (fecha.startsWith(mesActual)) {
        final tiempo = h['tiempo'] ?? '00:00';
        final partes = tiempo.split(':');
        if (partes.length == 2) {
          final horas = int.tryParse(partes[0]) ?? 0;
          final minutos = int.tryParse(partes[1]) ?? 0;
          totalMin += horas * 60 + minutos;
        }
      }
    }
    final horasTot = (totalMin ~/ 60).toString().padLeft(2, '0');
    final minTot = (totalMin % 60).toString().padLeft(2, '0');
    setState(() {
      _totalHorasTrabajadasMes = '$horasTot:$minTot';
    });
  }

  void _onTick(Duration elapsed) {
    if (_corriendo && _inicio != null) {
      setState(() {
        _transcurrido = DateTime.now().difference(_inicio!);
      });
    }
  }

  void _iniciar() async {
    final ahora = DateTime.now();
    setState(() {
      _inicio = ahora;
      _transcurrido = Duration.zero;
      _corriendo = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('horario_corriendo', true);
    await prefs.setString('horario_inicio', ahora.toIso8601String());
    _ticker.start();
  }

  Future<void> _finalizar() async {
    setState(() {
      _corriendo = false;
    });
    _ticker.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('horario_corriendo', false);
    await prefs.remove('horario_inicio');

    // Guardar en Firestore como historial
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.user?.email ?? 'sin_email';
    final horaInicio = _inicio;
    final horaFinal = DateTime.now();
    final tiempo = _formatoTiempo(_transcurrido);
    final fecha = DateTime.now();

    final colRef = FirebaseFirestore.instance
        .collection('area_supervisor')
        .doc('usuarios')
        .collection('usuarios')
        .doc(email)
        .collection('historial');

    await colRef.add({
      'hora_inicio': horaInicio?.toIso8601String(),
      'hora_finalizado': horaFinal.toIso8601String(),
      'tiempo': tiempo,
      'fecha':
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
    });
    await _cargarHistorial();
    await _calcularTotalMes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registro guardado en Firestore.')),
      );
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  String _formatoTiempo(Duration d) {
    final horas = d.inHours;
    final minutos = d.inMinutes % 60;
    final segundos = d.inSeconds % 60;
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Horario'),
            Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Colors.grey[700]),
                SizedBox(width: 4),
                Text(
                  _totalHorasTrabajadasMes,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contador arriba, más pequeño
            Center(
              child: Column(
                children: [
                  Text(
                    'Tiempo actual',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatoTiempo(_transcurrido),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _corriendo ? null : _iniciar,
                        child: Text('Iniciar'),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _corriendo ? _finalizar : null,
                        child: Text('Finalizar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 18),
            Divider(),
            SizedBox(height: 8),
            Text(
              'Historial',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: _historial.isEmpty
                  ? Center(
                      child: Text(
                        'No hay registros previos.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _historial.length,
                      itemBuilder: (context, idx) {
                        final h = _historial[idx];
                        final fecha = h['fecha'] ?? '-';
                        final tiempo = h['tiempo'] ?? '-';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(fecha, style: TextStyle(fontSize: 16)),
                              Text(
                                tiempo,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ticker simple para actualizar el cronómetro
class Ticker {
  final void Function(Duration) onTick;
  Duration _elapsed = Duration.zero;
  bool _active = false;
  Ticker(this.onTick);
  void start() {
    _active = true;
    _tick();
  }

  void stop() {
    _active = false;
  }

  void dispose() {
    _active = false;
  }

  void _tick() async {
    while (_active) {
      await Future.delayed(Duration(seconds: 1));
      if (_active) {
        _elapsed += Duration(seconds: 1);
        onTick(_elapsed);
      }
    }
  }
}
