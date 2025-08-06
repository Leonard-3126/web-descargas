// ignore_for_file: prefer_interpolation_to_compose_strings, unused_import

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class CalendarScreen extends StatefulWidget {
  final String rol;
  CalendarScreen({Key? key, required this.rol}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> apartamentosEventos = [];
  List<Map<String, dynamic>> resettingEventos = [];
  List<Map<String, dynamic>> limpiezaFondoEventos = [];
  List<Map<String, dynamic>> horasExtraEventos = [];

  @override
  void initState() {
    super.initState();
    cargarEventosDelDiaDesdeFirestore(_focusedDay);
  }

  Future<void> cargarEventosDelDiaDesdeFirestore(DateTime fecha) async {
    final fechaStr =
        '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    final firestore = FirebaseFirestore.instance;
    // Apartamentos
    final aptosSnap = await firestore
        .collection('itinerarios_v2')
        .doc('${fechaStr}_Apartamentos')
        .collection('apartamentos')
        .get();
    apartamentosEventos = aptosSnap.docs.map((d) => d.data()).toList();
    // Resetting
    final resetSnap = await firestore
        .collection('itinerarios_v2')
        .doc('${fechaStr}_Resetting')
        .collection('resetting')
        .get();
    resettingEventos = resetSnap.docs.map((d) => d.data()).toList();
    // Limpieza a fondo
    final fondoSnap = await firestore
        .collection('itinerarios_v2')
        .doc('${fechaStr}_Limpieza_a_fondo')
        .collection('limpieza_a_fondo')
        .get();
    limpiezaFondoEventos = fondoSnap.docs.map((d) => d.data()).toList();
    // Horas extra
    final extraSnap = await firestore
        .collection('itinerarios_v2')
        .doc('${fechaStr}_Horas_extra')
        .collection('horas_extra')
        .get();
    horasExtraEventos = extraSnap.docs.map((d) => d.data()).toList();
    setState(() {});
  }

  Future<void> mostrarModalCargaItinerario(BuildContext context) async {
    TextEditingController itinerarioController = TextEditingController();
    DateTime fechaEvento = _selectedDay ?? DateTime.now();
    String categoriaSeleccionada = 'Apartamentos';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Carga tu Itinerario',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: categoriaSeleccionada,
                        items:
                            [
                                  'Apartamentos',
                                  'Resetting',
                                  'Limpieza a fondo',
                                  'Horas extra',
                                ]
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            categoriaSeleccionada = val ?? 'Apartamentos';
                          });
                        },
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: fechaEvento,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              fechaEvento = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${fechaEvento.day}/${fechaEvento.month}/${fechaEvento.year}',
                              ),
                              Spacer(),
                              Icon(Icons.calendar_today, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: itinerarioController,
                        minLines: 4,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: 'Pega aquí la lista de apartamentos...',
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await guardarItinerarioFirestore(
                            fechaEvento,
                            categoriaSeleccionada,
                            itinerarioController.text,
                          );
                          cargarEventosDelDiaDesdeFirestore(fechaEvento);
                          Navigator.pop(context);
                        },
                        child: Text('Guardar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> guardarItinerarioFirestore(
    DateTime fecha,
    String categoria,
    String texto,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final fechaStr =
        '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}_' +
        categoria.replaceAll(' ', '_');
    final docRef = firestore
        .collection('itinerarios_v2')
        .doc(fechaStr)
        .collection(categoria.toLowerCase().replaceAll(' ', '_'));
    final lines = texto
        .split(RegExp(r'\n|\r'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    for (final line in lines) {
      String nombre;
      String datos;
      List<String> notas = [];
      if (categoria.toLowerCase() == 'resetting') {
        // Separar nombre y nota por guion
        final dashIndex = line.indexOf('-');
        if (dashIndex != -1) {
          nombre = line.substring(0, dashIndex).trim();
          final nota = line.substring(dashIndex + 1).trim();
          if (nota.isNotEmpty) notas.add(nota);
        } else {
          nombre = line.trim();
        }
        datos = '';
      } else {
        final partes = line.split('>>>');
        nombre = partes[0].trim();
        datos = partes.length > 1 ? partes[1] : '';
        // Notas: buscar frases tipo 'PREPARA PER <n>' o lo que esté después de '-'
        final preparaPerMatch = RegExp(
          r'PREPARA PER\s*\d+',
          caseSensitive: false,
        ).firstMatch(datos);
        if (preparaPerMatch != null) {
          notas.add(preparaPerMatch.group(0)!.trim());
        } else {
          final dashIndex = datos.indexOf('-');
          if (dashIndex != -1) {
            final nota = datos.substring(dashIndex + 1).trim();
            if (nota.isNotEmpty) notas.add(nota);
          }
        }
      }
      // Parseo de datos
      String? out;
      String? h;
      int? pax;
      int? n;
      final regexOut = RegExp(r'out\s*:?\s*([\w\d:]+)', caseSensitive: false);
      final regexH = RegExp(r'h\s*:?\s*([\w\d:]+)', caseSensitive: false);
      final regexPax = RegExp(r'pax\s*:?\s*(\d+)', caseSensitive: false);
      final regexInPax = RegExp(r'IN\s*(\d+)\s*PAX', caseSensitive: false);
      // Buscar valores
      final outMatch = regexOut.firstMatch(datos);
      if (outMatch != null) out = outMatch.group(1);
      final hMatch = regexH.firstMatch(datos);
      if (hMatch != null) h = hMatch.group(1);
      // Buscar pax en ambos formatos
      final paxMatch = regexPax.firstMatch(datos);
      if (paxMatch != null) {
        pax = int.tryParse(paxMatch.group(1)!);
      } else {
        final inPaxMatch = regexInPax.firstMatch(datos);
        if (inPaxMatch != null) pax = int.tryParse(inPaxMatch.group(1)!);
      }
      // Extraer noches usando el mismo regex que la tarjeta
      final matchNoches = RegExp(
        r'\(\s*(\d+)\s*N\s*\)',
        caseSensitive: false,
      ).firstMatch(datos);
      if (matchNoches != null) {
        n = int.tryParse(matchNoches.group(1)!);
      } else {
        n = null;
      }

      await docRef.doc(nombre).set({
        'nombre': nombre,
        'datos': datos,
        'out': out,
        'h': h,
        'pax': pax,
        'n': n,
        'notas': notas,
        'asignadoA': '',
        'asignadoNombre': '',
        'categoria': categoria,
        'fecha': fechaStr,
        'status': 'pendiente',
        'timestamp': Timestamp.now(),
      });
    }
  }

  Future<void> asignarOperario(
    Map<String, dynamic> evento,
    String categoria,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final operariosSnap = await firestore.collection('users').get();
    final operarios = operariosSnap.docs
        .where((d) => d['rol'] == 'operario' || d['rol'] == 'operario(a)')
        .map((d) => {'uid': d['uid'], 'nombre': d['nombre']})
        .toList();
    String? operarioSeleccionado = await mostrarSelectorOperario(
      context,
      operarios,
      evento['nombre'],
    );
    if (operarioSeleccionado != null) {
      final nombreOperario = operarios.firstWhere(
        (o) => o['uid'] == operarioSeleccionado,
      )['nombre'];
      final fechaStr = evento['fecha'];
      final nombreDoc = evento['nombre'];
      List asignados = evento['asignados'] ?? [];
      // Limitar a máximo 10 operarios
      if (asignados.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Máximo 10 operarios por tarjeta.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Evitar duplicados
      if (!asignados.any((o) => o['uid'] == operarioSeleccionado)) {
        asignados.add({'uid': operarioSeleccionado, 'nombre': nombreOperario});
        await firestore
            .collection('itinerarios_v2')
            .doc(fechaStr)
            .collection(categoria.toLowerCase().replaceAll(' ', '_'))
            .doc(nombreDoc)
            .set({'asignados': asignados}, SetOptions(merge: true));
        setState(() {
          evento['asignados'] = asignados;
        });
      }
    }
  }

  Future<String?> mostrarSelectorOperario(
    BuildContext context,
    List<Map<String, dynamic>> operarios,
    String nombreEvento,
  ) async {
    String? seleccionado;
    TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredOperarios = List.from(operarios);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: EdgeInsets.only(top: 60),
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Selecciona operario para "$nombreEvento"',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF222B45),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F6FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Color(0xFF8F9BB3)),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Buscar por nombre...',
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                filteredOperarios = operarios
                                    .where(
                                      (o) => o['nombre']
                                          .toString()
                                          .toLowerCase()
                                          .contains(value.toLowerCase()),
                                    )
                                    .toList();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  ...filteredOperarios.map(
                    (o) => ListTile(
                      title: Text(o['nombre'], style: TextStyle(fontSize: 16)),
                      onTap: () {
                        seleccionado = o['uid'];
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  if (filteredOperarios.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          'No se encontraron operarios',
                          style: TextStyle(color: Color(0xFF8F9BB3)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
    return seleccionado;
  }

  Future<void> eliminarEvento(
    Map<String, dynamic> evento,
    String categoria,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final fechaStr = evento['fecha'];
    final nombreDoc = evento['nombre'];
    final categorias = [
      'Apartamentos',
      'Resetting',
      'Limpieza a fondo',
      'Horas extra',
    ];
    // Eliminar de todas las subcolecciones de itinerarios_v2 para ese día
    for (final cat in categorias) {
      final col = cat.toLowerCase().replaceAll(' ', '_');
      await firestore
          .collection('itinerarios_v2')
          .doc(fechaStr)
          .collection(col)
          .doc(nombreDoc)
          .delete()
          .catchError((_) {}); // Ignorar si no existe
    }

    // Eliminar de conteo_apartamentos_mes si existe (por nombre y fecha)
    final conteoSnap = await firestore
        .collection('conteo_apartamentos_mes')
        .where('nombre', isEqualTo: nombreDoc)
        .where('fecha', isEqualTo: fechaStr)
        .get();
    for (final doc in conteoSnap.docs) {
      await doc.reference.delete();
    }

    // Eliminar de limpiezas_realizadas si existe (por nombre y fecha)
    final limpiezasSnap = await firestore
        .collection('limpiezas_realizadas')
        .where('nombre', isEqualTo: nombreDoc)
        .where('fecha', isEqualTo: fechaStr)
        .get();
    for (final doc in limpiezasSnap.docs) {
      await doc.reference.delete();
    }

    setState(() {
      apartamentosEventos.removeWhere((e) => e['nombre'] == nombreDoc);
      resettingEventos.removeWhere((e) => e['nombre'] == nombreDoc);
      limpiezaFondoEventos.removeWhere((e) => e['nombre'] == nombreDoc);
      horasExtraEventos.removeWhere((e) => e['nombre'] == nombreDoc);
    });
  }

  Widget tarjetaEvento(Map<String, dynamic> evento, String categoria) {
    final asignados = evento['asignados'] is List
        ? evento['asignados'] as List
        : [];
    // Obtener el rol del usuario actual
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? rol = authProvider.userRole;
    final rolNorm = (rol ?? '')
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    final isOperario = rolNorm.contains('operari');
    final isSupervisor = rolNorm.contains('supervisor');

    Future<void> eliminarOperario(String uid) async {
      final firestore = FirebaseFirestore.instance;
      final fechaStr = evento['fecha'];
      final nombreDoc = evento['nombre'];
      List nuevosAsignados = List.from(asignados)
        ..removeWhere((o) => o is Map ? o['uid'] == uid : o == uid);
      await firestore
          .collection('itinerarios_v2')
          .doc(fechaStr)
          .collection(categoria.toLowerCase().replaceAll(' ', '_'))
          .doc(nombreDoc)
          .set({'asignados': nuevosAsignados}, SetOptions(merge: true));
      setState(() {
        evento['asignados'] = nuevosAsignados;
      });
    }

    // Campos con fallback
    final nombre = evento['nombre'] ?? '-';
    final out = evento['out']?.toString() ?? '-';
    final pax = evento['pax']?.toString() ?? '-';
    final h = evento['h']?.toString() ?? '-';
    // Extraer noches desde 'datos' usando regex para formato '( 3 N )'
    final datos = evento['datos']?.toString() ?? '';
    final matchNoches = RegExp(
      r'\(\s*(\d+)\s*N\s*\)',
      caseSensitive: false,
    ).firstMatch(datos);
    final noches = matchNoches != null ? matchNoches.group(1) : '-';
    final notas =
        (evento['notas'] is List && (evento['notas'] as List).isNotEmpty)
        ? (evento['notas'] as List)
        : [];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFFF8F6FC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF222B45),
                      ),
                    ),
                    if (asignados.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Wrap(
                          spacing: 6,
                          children: asignados.map<Widget>((o) {
                            final nombreOp = o is Map && o['nombre'] != null
                                ? o['nombre'].toString()
                                : o.toString();
                            final uidOp = o is Map && o['uid'] != null
                                ? o['uid'].toString()
                                : null;
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF5D5FEF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    nombreOp,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  // Solo mostrar la X si NO es operario NI supervisor
                                  if (uidOp != null &&
                                      !isOperario &&
                                      !isSupervisor) ...[
                                    SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        await eliminarOperario(uidOp);
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isOperario && !isSupervisor)
                PopupMenuButton<int>(
                  icon: Icon(Icons.more_vert, color: Color(0xFF8F9BB3)),
                  itemBuilder: (context) {
                    final List<PopupMenuEntry<int>> items = [];
                    if (widget.rol == 'admin') {
                      items.add(
                        PopupMenuItem(
                          value: 2,
                          child: Row(children: [Text('Asignar operario')]),
                        ),
                      );
                    }
                    items.add(
                      PopupMenuItem(
                        value: 3,
                        child: Row(children: [Text('Cancelar tarjeta')]),
                      ),
                    );
                    return items;
                  },
                  onSelected: (value) async {
                    if (value == 2 && widget.rol == 'admin') {
                      await asignarOperario(evento, categoria);
                    } else if (value == 3) {
                      await eliminarEvento(evento, categoria);
                    }
                  },
                ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.exit_to_app, size: 18, color: Colors.red),
              SizedBox(width: 2),
              Text(
                out,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.people, size: 18, color: Color(0xFF5D5FEF)),
              SizedBox(width: 2),
              Text(
                '$pax PAX',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D5FEF),
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward, size: 18, color: Colors.green),
              SizedBox(width: 2),
              Text(
                h,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.nightlight_round, size: 18, color: Color(0xFFAB47BC)),
              SizedBox(width: 2),
              Text(
                noches ?? '-',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAB47BC),
                ),
              ),
            ],
          ),
          if (notas.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                notas.first,
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    final isAdmin = rolNorm.contains('admin');
    final isOperario = rolNorm.contains('operari');

    // Filtrar eventos asignados solo para operario
    List<Map<String, dynamic>> aptosAsignados = isOperario && uid != null
        ? apartamentosEventos
              .where(
                (e) =>
                    (e['asignados'] is List) &&
                    (e['asignados'] as List).any(
                      (o) => o is Map && o['uid'] == uid,
                    ),
              )
              .toList()
        : apartamentosEventos;
    List<Map<String, dynamic>> resettingAsignados = isOperario && uid != null
        ? resettingEventos
              .where(
                (e) =>
                    (e['asignados'] is List) &&
                    (e['asignados'] as List).any(
                      (o) => o is Map && o['uid'] == uid,
                    ),
              )
              .toList()
        : resettingEventos;
    List<Map<String, dynamic>> fondoAsignados = isOperario && uid != null
        ? limpiezaFondoEventos
              .where(
                (e) =>
                    (e['asignados'] is List) &&
                    (e['asignados'] as List).any(
                      (o) => o is Map && o['uid'] == uid,
                    ),
              )
              .toList()
        : limpiezaFondoEventos;
    List<Map<String, dynamic>> extraAsignados = isOperario && uid != null
        ? horasExtraEventos
              .where(
                (e) =>
                    (e['asignados'] is List) &&
                    (e['asignados'] as List).any(
                      (o) => o is Map && o['uid'] == uid,
                    ),
              )
              .toList()
        : horasExtraEventos;

    return Scaffold(
      backgroundColor: Color(0xFFF8F6FC),
      appBar: AppBar(
        title: Text('Calendario'),
        actions: [
          if (isAdmin)
            GestureDetector(
              onTap: () => mostrarModalCargaItinerario(context),
              child: Container(
                margin: EdgeInsets.only(right: 12, left: 4),
                child: CircleAvatar(
                  backgroundColor: Color(0xFF5D5FEF),
                  radius: 18,
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Center(
              //   child: Container(
              //     decoration: BoxDecoration(
              //       color: Colors.white,
              //       borderRadius: BorderRadius.circular(24),
              //     ),
              //     padding: const EdgeInsets.symmetric(
              //       vertical: 24,
              //       horizontal: 24,
              //     ),
              //     margin: const EdgeInsets.symmetric(vertical: 12),
              //     child: TableCalendar(
              //       firstDay: DateTime.utc(2020, 1, 1),
              //       lastDay: DateTime.utc(2100, 12, 31),
              //       focusedDay: _focusedDay,
              //       locale: 'es_ES',
              //       selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              //       onDaySelected: (selectedDay, focusedDay) {
              //         setState(() {
              //           _selectedDay = selectedDay;
              //           _focusedDay = focusedDay;
              //         });
              //         cargarEventosDelDiaDesdeFirestore(selectedDay);
              //       },
              //     ),
              //   ),
              // ),
              SizedBox(height: 24),
              Text(
                'Eventos del día',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 12),
              // Apartamentos
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.apartment, color: Color(0xFF5D5FEF)),
                        SizedBox(width: 8),
                        Text(
                          'Apartamentos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D5FEF),
                          ),
                        ),
                        Spacer(),
                        Text(
                          aptosAsignados.length.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D5FEF),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (aptosAsignados.isEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F6FC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'No hay itinerarios en esta categoría',
                          style: TextStyle(color: Color(0xFF8F9BB3)),
                        ),
                      )
                    else
                      ...aptosAsignados
                          .map((apto) => tarjetaEvento(apto, 'Apartamentos'))
                          .toList(),
                  ],
                ),
              ),
              // Resetting
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF4CBF4B)),
                        SizedBox(width: 8),
                        Text(
                          'Resetting',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CBF4B),
                          ),
                        ),
                        Spacer(),
                        Text(
                          resettingAsignados.length.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CBF4B),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (resettingAsignados.isEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F6FC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'No hay itinerarios en esta categoría',
                          style: TextStyle(color: Color(0xFF8F9BB3)),
                        ),
                      )
                    else
                      ...resettingAsignados
                          .map((evento) => tarjetaEvento(evento, 'Resetting'))
                          .toList(),
                  ],
                ),
              ),
              // Limpieza a fondo
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cleaning_services, color: Color(0xFFFFA726)),
                        SizedBox(width: 8),
                        Text(
                          'Limpieza a fondo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFA726),
                          ),
                        ),
                        Spacer(),
                        Text(
                          fondoAsignados.length.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFA726),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (fondoAsignados.isEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F6FC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'No hay itinerarios en esta categoría',
                          style: TextStyle(color: Color(0xFF8F9BB3)),
                        ),
                      )
                    else
                      ...fondoAsignados
                          .map(
                            (evento) =>
                                tarjetaEvento(evento, 'Limpieza a fondo'),
                          )
                          .toList(),
                  ],
                ),
              ),
              // Horas extra
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Color(0xFFAB47BC)),
                        SizedBox(width: 8),
                        Text(
                          'Horas extra',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFAB47BC),
                          ),
                        ),
                        Spacer(),
                        Text(
                          extraAsignados.length.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFAB47BC),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (extraAsignados.isEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F6FC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'No hay itinerarios en esta categoría',
                          style: TextStyle(color: Color(0xFF8F9BB3)),
                        ),
                      )
                    else
                      ...extraAsignados
                          .map((evento) => tarjetaEvento(evento, 'Horas extra'))
                          .toList(),
                  ],
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
