import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LimpiezasHoyScreen extends StatelessWidget {
  // Método estático para sumar limpieza por apartamento en el mes
  static Future<void> sumarLimpiezaMes(
    String emailUsuario,
    String nombreApartamento,
  ) async {
    final ahora = DateTime.now();
    final mesActual = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';
    final docRef = FirebaseFirestore.instance
        .collection('conteo_apartamentos_mes')
        .doc(mesActual)
        .collection('apartamento')
        .doc(emailUsuario);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      Map<String, dynamic> data = snapshot.exists ? snapshot.data()! : {};
      Map<String, dynamic> apartamentos = Map<String, dynamic>.from(
        data['apartamentos'] ?? {},
      );
      // Sumar o crear el apartamento
      apartamentos[nombreApartamento] =
          (apartamentos[nombreApartamento] ?? 0) + 1;
      transaction.set(docRef, {
        ...data,
        'apartamentos': apartamentos,
        'usuario': emailUsuario,
        'fecha': mesActual,
      });
    });
  }

  const LimpiezasHoyScreen({Key? key}) : super(key: key);

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
    final bool isAdmin = rolNorm.contains('admin');

    Future<List<Map<String, dynamic>>> getNombresFiltrados() async {
      final DateTime hoy = DateTime.now();
      final String fechaStr =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}_Apartamentos';
      final snapshotApartamentos = await FirebaseFirestore.instance
          .collection('itinerarios_v2')
          .doc(fechaStr)
          .collection('apartamentos')
          .get();
      final nombresApartamentos = snapshotApartamentos.docs
          .where((doc) {
            if (isAdmin) return true;
            final data = doc.data();
            final asignados = data['asignados'] as List?;
            if (asignados == null || uid == null) return false;
            return asignados.any((o) => o is Map && o['uid'] == uid);
          })
          .map((doc) {
            final data = doc.data();
            return {
              'nombre': data['nombre']?.toString() ?? doc.id,
              'status': data['status']?.toString() ?? 'pendiente',
              'tipo': 'apartamento',
            };
          })
          .toList();

      final fechaStrResetting =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}_Resetting';
      final snapshotResetting = await FirebaseFirestore.instance
          .collection('itinerarios_v2')
          .doc(fechaStrResetting)
          .collection('resetting')
          .get();
      final nombresResetting = snapshotResetting.docs
          .where((doc) {
            if (isAdmin) return true;
            final data = doc.data();
            final asignados = data['asignados'] as List?;
            if (asignados == null || uid == null) return false;
            return asignados.any((o) => o is Map && o['uid'] == uid);
          })
          .map((doc) {
            final data = doc.data();
            return {
              'nombre': data['nombre']?.toString() ?? doc.id,
              'status': data['status']?.toString() ?? 'pendiente',
              'tipo': 'resetting',
            };
          })
          .toList();

      final todos = [...nombresApartamentos, ...nombresResetting];
      todos.sort(
        (a, b) => (a['nombre'] ?? '').toLowerCase().compareTo(
          (b['nombre'] ?? '').toLowerCase(),
        ),
      );
      return todos;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Limpiezas Hoy'),
        backgroundColor: const Color(0xFF6A82FB),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Guardar',
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final String? uid = authProvider.user?.uid;
              final String? nombreUsuario =
                  authProvider.user?.displayName ??
                  authProvider.user?.email ??
                  'Desconocido';
              final DateTime hoy = DateTime.now();
              final fechaStr =
                  '${hoy.day.toString().padLeft(2, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.year}';
              final mesStr =
                  '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}';
              final items = await getNombresFiltrados();
              final firestore = FirebaseFirestore.instance;
              final finalizados = items
                  .where(
                    (i) =>
                        (i['status']?.toString().toLowerCase() == 'finalizado'),
                  )
                  .toList();
              if (finalizados.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Falta un apartamento por finalizar. Si no lo finalizas no se te contará.',
                    ),
                  ),
                );
                return;
              }
              // Guardar limpiezas individuales agrupadas por mes, tipo y usuario
              for (final item in finalizados) {
                final tipo = item['tipo']?.toString() ?? 'apartamento';
                final nombre = item['nombre']?.toString() ?? '-';
                // ID único: apartamento_fecha_uid (sin espacios ni caracteres raros)
                final idUnico = '${nombre}_${fechaStr}_${uid}'.replaceAll(
                  RegExp(r'[^a-zA-Z0-9]'),
                  '_',
                );
                // Guardar automáticamente sin pedir minutos
                final docRef = firestore
                    .collection('limpiezas_realizadas')
                    .doc(mesStr)
                    .collection(tipo)
                    .doc(nombreUsuario)
                    .collection('limpiezas')
                    .doc(idUnico);
                await docRef.set({
                  'apartamento': nombre,
                  'fecha': fechaStr,
                  'usuario': nombreUsuario,
                  'uid': uid,
                  'tipo': tipo,
                  'status': item['status'],
                  'timestamp': Timestamp.now(),
                  // No se guarda el campo minutos
                });
              }
              // Guardar conteo mensual agrupado solo por usuario
              final conteoPorUsuario =
                  <String, Map<String, Map<String, int>>>{};
              for (final item in finalizados) {
                final nombre = item['nombre']?.toString() ?? '-';
                final usuario = (nombreUsuario ?? 'Desconocido');
                final tipo = item['tipo']?.toString() ?? 'apartamento';
                conteoPorUsuario[usuario] ??= {};
                conteoPorUsuario[usuario]![tipo] ??= {};
                conteoPorUsuario[usuario]![tipo]![nombre] =
                    (conteoPorUsuario[usuario]![tipo]![nombre] ?? 0) + 1;
              }
              // Sumar correctamente los apartamentos en vez de sobrescribir
              for (final usuario in conteoPorUsuario.keys) {
                final apartamentos =
                    conteoPorUsuario[usuario]?['apartamento'] ?? {};
                final resetting = conteoPorUsuario[usuario]?['resetting'] ?? {};
                // Sumar apartamentos
                for (final nombre in apartamentos.keys) {
                  final cantidad = apartamentos[nombre] ?? 1;
                  for (int i = 0; i < cantidad; i++) {
                    await LimpiezasHoyScreen.sumarLimpiezaMes(usuario, nombre);
                  }
                }
                // Sumar resetting
                for (final nombre in resetting.keys) {
                  final cantidad = resetting[nombre] ?? 1;
                  for (int i = 0; i < cantidad; i++) {
                    await LimpiezasHoyScreen.sumarLimpiezaMes(usuario, nombre);
                  }
                }
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Guardado correctamente.')),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A82FB), Color(0xFFFC5C7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: getNombresFiltrados(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No hay apartamentos por limpiar hoy.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            final items = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final nombre = item['nombre'] ?? '';
                final status = item['status'] ?? 'pendiente';
                final tipo = item['tipo'] ?? '';
                Color statusColor;
                String statusText;
                switch (status.toLowerCase()) {
                  case 'finalizado':
                    statusColor = Colors.green;
                    statusText = 'Finalizado';
                    break;
                  case 'en progreso':
                    statusColor = Colors.blue;
                    statusText = 'En progreso';
                    break;
                  case 'pendiente':
                    statusColor = Colors.orange;
                    statusText = 'Pendiente';
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusText = status;
                }
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    title: Text(
                      tipo == 'resetting' ? '$nombre (Resetting)' : nombre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
