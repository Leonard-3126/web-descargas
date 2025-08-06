// ignore_for_file: unused_field
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:w_cleaning/screens/gestion_apartamentos_screen.dart';
import 'package:w_cleaning/screens/limpiezas_hoy_screen.dart';
import 'package:w_cleaning/screens/Horas.dart';
import 'package:w_cleaning/screens/horario.dart';

class DashboardScreen extends StatefulWidget {
  final String? rol;
  const DashboardScreen({Key? key, this.rol}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Stream<double> getTotalHorasMesUsuarioStream() {
    final ahora = DateTime.now();
    final mesAnio = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid ?? '';
    final colRef = FirebaseFirestore.instance
        .collection('HORAS_OPERARIOS')
        .doc(uid)
        .collection('fechas')
        .doc(mesAnio)
        .collection('dias');
    return colRef.snapshots().map((diasSnap) {
      double total = 0.0;
      for (final doc in diasSnap.docs) {
        final data = doc.data();
        final horas = (data['horas'] ?? 0.0) is int
            ? (data['horas'] as int).toDouble()
            : (data['horas'] ?? 0.0) as double;
        total += horas;
      }
      return total;
    });
  }

  DateTime _selectedDate = DateTime.now();
  int _refreshKey = 0;

  Future<int> getApartmentsCount() async {
    // Lógica similar a GestionApartamentosScreen para sumar apartamentos y resetting del mes actual
    final now = DateTime.now();
    final mesActual =
        '${now.year.toString()}-${now.month.toString().padLeft(2, '0')}';
    final firestore = FirebaseFirestore.instance;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final emailUsuario = authProvider.user?.email;
    int total = 0;
    final snapshot = await firestore
        .collection('conteo_apartamentos_mes')
        .doc(mesActual)
        .collection('apartamento')
        .get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final usuarioEmail = data['usuario'] ?? doc.id;
      if (usuarioEmail == emailUsuario) {
        final apartamentos = data['apartamentos'] ?? {};
        final resetting = data['resetting'] ?? {};
        total += (apartamentos as Map).values.fold(
          0,
          (a, b) => a + (b is int ? b : int.tryParse(b.toString()) ?? 0),
        );
        total += (resetting as Map).values.fold(
          0,
          (a, b) => a + (b is int ? b : int.tryParse(b.toString()) ?? 0),
        );
      }
    }
    return total;
  }

  Future<int> getLimpiezasHoyCount() async {
    final fecha = _selectedDate;
    final fechaStrAptos =
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}_Apartamentos';
    final docRefAptos = FirebaseFirestore.instance
        .collection('itinerarios_v2')
        .doc(fechaStrAptos);
    final subAptos = await docRefAptos.collection('apartamentos').get();
    final fechaStrResetting =
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}_Resetting';
    final docRefResetting = FirebaseFirestore.instance
        .collection('itinerarios_v2')
        .doc(fechaStrResetting);
    final subResetting = await docRefResetting.collection('resetting').get();

    // Obtener UID y rol
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? uid = authProvider.user?.uid;
    final String? rol = authProvider.userRole;
    final rolNorm = (rol ?? '')
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    final isOperario = rolNorm.contains('operari');

    int total = 0;
    if (isOperario && uid != null) {
      total += subAptos.docs.where((d) {
        final data = d.data() as Map<String, dynamic>?;
        final asignados = data?['asignados'] as List?;
        if (asignados == null) return false;
        return asignados.any((o) => o is Map && o['uid'] == uid);
      }).length;
      total += subResetting.docs.where((d) {
        final data = d.data() as Map<String, dynamic>?;
        final asignados = data?['asignados'] as List?;
        if (asignados == null) return false;
        return asignados.any((o) => o is Map && o['uid'] == uid);
      }).length;
    } else {
      total = subAptos.docs.length + subResetting.docs.length;
    }
    return total;
  }

  Widget tarjetaCompacta(Map<String, dynamic> evento) {
    final nombre = evento['nombre'] ?? '-';
    final out = evento['out']?.toString() ?? '-';
    final pax = evento['pax']?.toString() ?? '-';
    final h = evento['h']?.toString() ?? '-';
    final n = evento['n']?.toString() ?? '-';
    final notas =
        (evento['notas'] is List && (evento['notas'] as List).isNotEmpty)
        ? (evento['notas'] as List)
        : [];
    final status = evento['status']?.toString() ?? 'pendiente';
    final inicio = evento['inicio'] != null
        ? DateTime.tryParse(evento['inicio'].toString())
        : null;
    final fin = evento['fin'] != null
        ? DateTime.tryParse(evento['fin'].toString())
        : null;
    String? tiempoStr;
    if (inicio != null && fin != null) {
      final duracion = fin.difference(inicio);
      final horas = duracion.inHours;
      final minutos = duracion.inMinutes % 60;
      tiempoStr = 'Tiempo: ';
      if (horas > 0) tiempoStr += '${horas}h ';
      tiempoStr += '${minutos}min';
    }
    // ...existing code...
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF8F6FC),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.apartment, color: Color(0xFF5D5FEF), size: 18),
              SizedBox(width: 6),
              Text(
                nombre,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF222B45),
                ),
              ),
              Spacer(),
              Icon(Icons.people, size: 16, color: Color(0xFF5D5FEF)),
              SizedBox(width: 2),
              Text(
                '$pax PAX',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5D5FEF),
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward, size: 16, color: Colors.green),
              SizedBox(width: 2),
              Text(
                h,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.nightlight_round, size: 16, color: Color(0xFFAB47BC)),
              SizedBox(width: 2),
              Text(
                n,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFAB47BC),
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.exit_to_app, size: 16, color: Colors.red),
              SizedBox(width: 2),
              Text(
                out,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (notas.isNotEmpty) ...[
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                notas.first,
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          // Estado y botones según rol
          SizedBox(height: 6),
          Builder(
            builder: (context) {
              final rolNorm = (widget.rol ?? '')
                  .toLowerCase()
                  .replaceAll('á', 'a')
                  .replaceAll('é', 'e')
                  .replaceAll('í', 'i')
                  .replaceAll('ó', 'o')
                  .replaceAll('ú', 'u');
              final isAdmin = rolNorm.contains('admin');
              final isOperario = rolNorm.contains('operario');
              if (isAdmin) {
                // Solo muestra el estado y tiempo si existe
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado: $status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: status == 'finalizado'
                            ? Colors.green
                            : status == 'en proceso'
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                    if (tiempoStr != null)
                      Text(
                        tiempoStr,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey,
                        ),
                      ),
                  ],
                );
              } else if (isOperario) {
                // Botones según estado y tiempo si existe
                if (status == 'pendiente') {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: Size(100, 36),
                    ),
                    child: Text('Iniciar'),
                    onPressed: () async {
                      // Actualizar estado a "en proceso" y guardar timestamp de inicio
                      final ahora = DateTime.now().toIso8601String();
                      await evento['ref']?.update({
                        'status': 'en proceso',
                        'inicio': ahora,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Marcado como iniciado.')),
                      );
                      setState(() {});
                    },
                  );
                } else if (status == 'en proceso') {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(100, 36),
                    ),
                    child: Text('Finalizar'),
                    onPressed: () async {
                      // Actualizar estado a "finalizado" y guardar timestamp de fin
                      final ahora = DateTime.now().toIso8601String();
                      await evento['ref']?.update({
                        'status': 'finalizado',
                        'fin': ahora,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Marcado como finalizado.')),
                      );
                      setState(() {});
                    },
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado: $status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (tiempoStr != null)
                        Text(
                          tiempoStr,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.blueGrey,
                          ),
                        ),
                    ],
                  );
                }
              } else {
                // Otros roles solo ven el estado y tiempo si existe
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado: $status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (tiempoStr != null)
                      Text(
                        tiempoStr,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey,
                        ),
                      ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget emptyCategoryMsg() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'No hay itinerarios en esta categoría',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rolNorm = (widget.rol ?? '')
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    final isAdmin = rolNorm.contains('admin');
    final isSupervisor = rolNorm.contains('supervisor');
    final isOperario = rolNorm.contains('operari');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final emailUsuario = authProvider.user?.email;

    return Scaffold(
      appBar: AppBar(
        title: Text('Wcleaning'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF222B45)),
            tooltip: 'Actualizar',
            onPressed: () {
              setState(() {
                _refreshKey++;
              });
            },
          ),
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.add, color: Color(0xFF5D5FEF)),
              onPressed: () {},
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: isSupervisor && emailUsuario != null
                      ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HorarioScreen(),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.all(4),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // StreamBuilder para horas totales
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('area_supervisor')
                                          .doc('usuarios')
                                          .collection('usuarios')
                                          .doc(emailUsuario)
                                          .collection('historial')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        int totalMinMes = 0;
                                        int totalMinDia = 0;
                                        final now = DateTime.now();
                                        final hoyStr =
                                            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                                        final mesStr =
                                            '${now.year}-${now.month.toString().padLeft(2, '0')}';
                                        if (snapshot.hasData) {
                                          for (final doc
                                              in snapshot.data!.docs) {
                                            final data =
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            final fecha = data['fecha'] ?? '';
                                            final tiempo =
                                                data['tiempo'] ?? '00:00';
                                            final partes = tiempo.split(':');
                                            if (partes.length == 2) {
                                              final horas =
                                                  int.tryParse(partes[0]) ?? 0;
                                              final minutos =
                                                  int.tryParse(partes[1]) ?? 0;
                                              final min = horas * 60 + minutos;
                                              if (fecha == hoyStr)
                                                totalMinDia += min;
                                              if (fecha.startsWith(mesStr))
                                                totalMinMes += min;
                                            }
                                          }
                                        }
                                        final horasMes = totalMinMes ~/ 60;
                                        final minutosMes = totalMinMes % 60;
                                        final horasDia = totalMinDia ~/ 60;
                                        final minutosDia = totalMinDia % 60;
                                        // Mostrar solo el total del mes y del día, sin texto extra
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${horasDia}h ${minutosDia}m',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.purple,
                                              ),
                                            ),
                                            Text(
                                              '${horasMes}h ${minutosMes}m',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.purple,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    Icon(Icons.schedule, color: Colors.purple),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Horario',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : FutureBuilder<int>(
                          future: getApartmentsCount(),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            final card = Container(
                              margin: EdgeInsets.all(4),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Icon(Icons.apartment, color: Colors.blue),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Apartamento MES',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        GestionApartamentosScreen(),
                                  ),
                                );
                              },
                              child: card,
                            );
                          },
                        ),
                ),
                if (isOperario)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HorasScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.all(4),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            StreamBuilder<double>(
                              stream: getTotalHorasMesUsuarioStream(),
                              builder: (context, snapshot) {
                                final totalHoras = snapshot.data ?? 0.0;
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${totalHoras.toStringAsFixed(1)} h',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Icon(Icons.timer, color: Colors.green),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'HORAS',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: FutureBuilder<int>(
                    future: getLimpiezasHoyCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      final card = Container(
                        margin: EdgeInsets.all(4),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                Icon(
                                  Icons.cleaning_services,
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Limpiezas Hoy',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (isSupervisor) {
                        return card;
                      } else {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LimpiezasHoyScreen(),
                              ),
                            );
                          },
                          child: card,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Apartamentos por Limpiar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: Color(0xFF222B45)),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(
                            Duration(days: 1),
                          );
                        });
                      },
                    ),
                    Text(
                      _selectedDate.day == DateTime.now().day &&
                              _selectedDate.month == DateTime.now().month &&
                              _selectedDate.year == DateTime.now().year
                          ? 'hoy'
                          : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: Color(0xFF222B45)),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(Duration(days: 1));
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            Text(
              isAdmin
                  ? 'Vista de administrador'
                  : isSupervisor
                  ? 'Vista de supervisor'
                  : isOperario
                  ? 'Vista de operario'
                  : 'Vista general',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  // Apartamentos
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('itinerarios_v2')
                        .doc(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}_Apartamentos',
                        )
                        .collection('apartamentos')
                        .get(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data?.docs ?? [];
                      // Obtener UID y rol
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final String? uid = authProvider.user?.uid;
                      final String? rol = authProvider.userRole;
                      final isOperario = (rol ?? '').toLowerCase().contains(
                        'operari',
                      );
                      // Filtrar solo asignados si es operario
                      final filteredDocs = isOperario && uid != null
                          ? docs.where((d) {
                              final data = d.data() as Map<String, dynamic>?;
                              final asignados = data?['asignados'] as List?;
                              if (asignados == null) return false;
                              return asignados.any(
                                (o) => o is Map && o['uid'] == uid,
                              );
                            }).toList()
                          : docs;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFF7F5FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.apartment, color: Color(0xFF6A82FB)),
                                const SizedBox(width: 8),
                                Text(
                                  'Apartamentos',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF6A82FB),
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  filteredDocs.length.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6A82FB),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (filteredDocs.isEmpty)
                              emptyCategoryMsg()
                            else
                              ...filteredDocs.map((d) {
                                final data = d.data() as Map<String, dynamic>;
                                // Añadir referencia del documento para actualizar estado
                                data['ref'] = d.reference;
                                return tarjetaCompacta(data);
                              }),
                          ],
                        ),
                      );
                    },
                  ),
                  // Resetting
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('itinerarios_v2')
                        .doc(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}_Resetting',
                        )
                        .collection('resetting')
                        .get(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data?.docs ?? [];
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final String? uid = authProvider.user?.uid;
                      final String? rol = authProvider.userRole;
                      final isOperario = (rol ?? '').toLowerCase().contains(
                        'operari',
                      );
                      final filteredDocs = isOperario && uid != null
                          ? docs.where((d) {
                              final data = d.data() as Map<String, dynamic>?;
                              final asignados = data?['asignados'] as List?;
                              if (asignados == null) return false;
                              return asignados.any(
                                (o) => o is Map && o['uid'] == uid,
                              );
                            }).toList()
                          : docs;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.refresh, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Resetting',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  filteredDocs.length.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (filteredDocs.isEmpty)
                              emptyCategoryMsg()
                            else
                              ...filteredDocs.map((d) {
                                final data = d.data() as Map<String, dynamic>;
                                data['ref'] = d.reference;
                                return tarjetaCompacta(data);
                              }),
                          ],
                        ),
                      );
                    },
                  ),
                  // Limpieza a fondo
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('itinerarios_v2')
                        .doc(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}_Limpieza_a_fondo',
                        )
                        .collection('limpieza_a_fondo')
                        .get(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data?.docs ?? [];
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final String? uid = authProvider.user?.uid;
                      final String? rol = authProvider.userRole;
                      final isOperario = (rol ?? '').toLowerCase().contains(
                        'operari',
                      );
                      final filteredDocs = isOperario && uid != null
                          ? docs.where((d) {
                              final data = d.data() as Map<String, dynamic>?;
                              final asignados = data?['asignados'] as List?;
                              if (asignados == null) return false;
                              return asignados.any(
                                (o) => o is Map && o['uid'] == uid,
                              );
                            }).toList()
                          : docs;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.cleaning_services,
                                  color: Colors.purple,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Limpieza a fondo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.purple,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  filteredDocs.length.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (filteredDocs.isEmpty)
                              emptyCategoryMsg()
                            else
                              ...filteredDocs.map((d) {
                                final data = d.data() as Map<String, dynamic>;
                                data['ref'] = d.reference;
                                return tarjetaCompacta(data);
                              }),
                          ],
                        ),
                      );
                    },
                  ),
                  // Horas extra
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('itinerarios_v2')
                        .doc(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}_Horas_extra',
                        )
                        .collection('horas_extra')
                        .get(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data?.docs ?? [];
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final String? uid = authProvider.user?.uid;
                      final String? rol = authProvider.userRole;
                      final isOperario = (rol ?? '').toLowerCase().contains(
                        'operari',
                      );
                      final filteredDocs = isOperario && uid != null
                          ? docs.where((d) {
                              final data = d.data() as Map<String, dynamic>?;
                              final asignados = data?['asignados'] as List?;
                              if (asignados == null) return false;
                              return asignados.any(
                                (o) => o is Map && o['uid'] == uid,
                              );
                            }).toList()
                          : docs;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F6FC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.timer, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  'Horas extra',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.orange,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  filteredDocs.length.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (filteredDocs.isEmpty)
                              emptyCategoryMsg()
                            else
                              ...filteredDocs.map((d) {
                                final data = d.data() as Map<String, dynamic>;
                                data['ref'] = d.reference;
                                return tarjetaCompacta(data);
                              }),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
