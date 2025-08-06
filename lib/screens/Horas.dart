// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HorasScreen extends StatefulWidget {
  const HorasScreen({Key? key}) : super(key: key);

  @override
  State<HorasScreen> createState() => _HorasScreenState();
}

class _HorasScreenState extends State<HorasScreen> {
  double totalHorasMes = 0.0;
  bool cargando = true;
  List<Map<String, dynamic>> horasPorDia = [];
  Map<String, dynamic> apartamentosHoy = {};
  Map<String, dynamic> resettingHoy = {};
  Map<String, String> horasPorApartamento = {}; // nombre -> horas

  @override
  void initState() {
    super.initState();
    cargarHorasOperarioMesActual();
  }

  Future<void> cargarHorasOperarioMesActual() async {
    setState(() {
      cargando = true;
    });
    final ahora = DateTime.now();
    final mesAnio = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';
    final diaActual =
        '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid ?? '';
    // Horas por día
    final diasSnap = await FirebaseFirestore.instance
        .collection('HORAS_OPERARIOS')
        .doc(uid)
        .collection('fechas')
        .doc(mesAnio)
        .collection('dias')
        .get();
    double total = 0.0;
    List<Map<String, dynamic>> listaDias = [];
    for (final doc in diasSnap.docs) {
      final data = doc.data();
      final horas = (data['horas'] ?? 0.0) is int
          ? (data['horas'] as int).toDouble()
          : (data['horas'] ?? 0.0) as double;
      total += horas;
      listaDias.add({'fecha': data['fecha'] ?? doc.id, 'horas': horas});
    }
    // Apartamentos y resetting del día
    final mesDoc = await FirebaseFirestore.instance
        .collection('conteo_apartamentos_mes')
        .doc(mesAnio)
        .collection('apartamento')
        .get();
    Map<String, dynamic> apartamentos = {};
    Map<String, dynamic> resetting = {};
    for (final doc in mesDoc.docs) {
      final data = doc.data();
      if (data['apartamentos'] != null) {
        apartamentos.addAll(Map<String, dynamic>.from(data['apartamentos']));
      }
      if (data['resetting'] != null) {
        resetting.addAll(Map<String, dynamic>.from(data['resetting']));
      }
    }
    // Obtener horas de cada apartamento desde la colección "apartamentos"
    Map<String, String> horasApto = {};
    final aptosSnap = await FirebaseFirestore.instance
        .collection('apartamentos')
        .get();
    for (final doc in aptosSnap.docs) {
      final data = doc.data();
      final nombre = (data['nombre'] ?? '').toString().trim().toUpperCase();
      final horas = (data['horas'] ?? '').toString();
      if (nombre.isNotEmpty && horas.isNotEmpty) {
        horasApto[nombre] = horas;
      }
    }
    setState(() {
      totalHorasMes = total;
      horasPorDia = listaDias;
      apartamentosHoy = apartamentos;
      resettingHoy = resetting;
      horasPorApartamento = horasApto;
      cargando = false;
    });
  }

  Future<void> guardarHorasOperario({
    required String uid,
    required DateTime fecha,
    required double horas,
  }) async {
    final mesAnio = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
    final dia =
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    final docRef = FirebaseFirestore.instance
        .collection('HORAS_OPERARIOS')
        .doc(uid)
        .collection('fechas')
        .doc(mesAnio)
        .collection('dias')
        .doc(dia);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      double horasActual = 0.0;
      if (snapshot.exists) {
        horasActual = (snapshot.data()?['horas'] ?? 0.0) is int
            ? (snapshot.data()?['horas'] as int).toDouble()
            : (snapshot.data()?['horas'] ?? 0.0) as double;
      }
      transaction.set(docRef, {'horas': horasActual + horas, 'fecha': dia});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horas'),
        backgroundColor: const Color(0xFF6A82FB),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A82FB), Color(0xFFFC5C7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : horasPorDia.isEmpty
            ? const Center(
                child: Text(
                  'No hay horas registradas este mes.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 12,
                ),
                children: [
                  // ...
                  // Mostrar lista tipo imagen 3: apartamentos y resetting limpiados hoy
                  ...(() {
                    // Unir ambos mapas y marcar si es resetting
                    final List<Map<String, dynamic>> items = [];
                    apartamentosHoy.forEach((nombre, v) {
                      items.add({'nombre': nombre, 'tipo': 'apartamento'});
                    });
                    resettingHoy.forEach((nombre, v) {
                      items.add({'nombre': nombre, 'tipo': 'resetting'});
                    });
                    // Ordenar por nombre
                    items.sort(
                      (a, b) => a['nombre'].toString().compareTo(
                        b['nombre'].toString(),
                      ),
                    );
                    // Calcular suma total de horas
                    double sumaHoras = 0.0;
                    final List<Widget> tarjetas = [];
                    for (final item in items) {
                      final nombre = item['nombre']
                          .toString()
                          .trim()
                          .toUpperCase();
                      final tipo = item['tipo'];
                      final horasStr = horasPorApartamento[nombre] ?? '';
                      final horas =
                          double.tryParse(horasStr.replaceAll(',', '.')) ?? 0.0;
                      sumaHoras += horas;
                      tarjetas.add(
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: tipo == 'resetting'
                                ? const Color(0xFFFFE6EC)
                                : Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                nombre,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: tipo == 'resetting'
                                      ? const Color(0xFFFC5C7D)
                                      : const Color(0xFF333333),
                                ),
                              ),
                              Text(
                                horas > 0
                                    ? '${horas.toStringAsFixed(1)} h'
                                    : '-',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: tipo == 'resetting'
                                      ? const Color(0xFFFC5C7D)
                                      : const Color(0xFF6A82FB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    // Tarjeta de suma total
                    tarjetas.add(
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total horas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A82FB),
                              ),
                            ),
                            Text(
                              '${sumaHoras.toStringAsFixed(1)} h',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFC5C7D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    return tarjetas;
                  })(),
                ],
              ),
      ),
    );
  }
}
