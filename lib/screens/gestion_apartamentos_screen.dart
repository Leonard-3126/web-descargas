import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';

class GestionApartamentosScreen extends StatefulWidget {
  const GestionApartamentosScreen({Key? key}) : super(key: key);

  @override
  State<GestionApartamentosScreen> createState() =>
      _GestionApartamentosScreenState();
}

class _GestionApartamentosScreenState extends State<GestionApartamentosScreen> {
  int get totalApartamentosYResetting {
    int total = 0;
    for (final usuario in conteoUsuarios) {
      final apartamentos = usuario['apartamentos'] as Map? ?? {};
      final resetting = usuario['resetting'] as Map? ?? {};
      total += apartamentos.values.fold(
        0,
        (a, b) => a + (b is int ? b : int.tryParse(b.toString()) ?? 0),
      );
      total += resetting.values.fold(
        0,
        (a, b) => a + (b is int ? b : int.tryParse(b.toString()) ?? 0),
      );
    }
    return total;
  }

  bool cargando = true;
  String mesActual = '';
  List<String> mesesDisponibles = [];
  List<Map<String, dynamic>> conteoUsuarios = [];

  @override
  void initState() {
    super.initState();
    cargarMesesDisponiblesYActual();
  }

  Future<void> cargarMesesDisponiblesYActual() async {
    final ahora = DateTime.now();
    final mesActualTmp =
        '${ahora.year.toString()}-${ahora.month.toString().padLeft(2, '0')}';
    final firestore = FirebaseFirestore.instance;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final emailUsuario = authProvider.user?.email;
    final snapshot = await firestore
        .collection('conteo_apartamentos_mes')
        .get();
    List<String> mesesConDatos = [];
    for (final doc in snapshot.docs) {
      final sub = await firestore
          .collection('conteo_apartamentos_mes')
          .doc(doc.id)
          .collection('apartamento')
          .get();
      for (final subdoc in sub.docs) {
        final data = subdoc.data();
        final usuarioEmail = data['usuario'] ?? subdoc.id;
        final apartamentos = data['apartamentos'] ?? {};
        final resetting = data['resetting'] ?? {};
        final tieneDatos =
            (usuarioEmail == emailUsuario) &&
            ((apartamentos as Map).isNotEmpty || (resetting as Map).isNotEmpty);
        if (tieneDatos) {
          mesesConDatos.add(doc.id);
          break;
        }
      }
    }
    // Asegurar que el mes actual siempre esté
    if (!mesesConDatos.contains(mesActualTmp)) {
      mesesConDatos.insert(0, mesActualTmp);
    }
    setState(() {
      mesesDisponibles = mesesConDatos.take(3).toList();
      mesActual = mesesDisponibles[0];
    });
    await cargarConteoMesActual();
  }

  Future<void> cargarConteoMesActual() async {
    setState(() {
      cargando = true;
    });
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('conteo_apartamentos_mes')
        .doc(mesActual)
        .collection('apartamento')
        .get();
    // Obtener email del usuario logueado usando Provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final emailUsuario = authProvider.user?.email;
    Map<String, dynamic>? usuarioUnico;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final usuarioEmail = data['usuario'] ?? doc.id;
      if (usuarioEmail == emailUsuario) {
        // Si ya existe, sumamos los apartamentos y resetting
        if (usuarioUnico == null) {
          usuarioUnico = {
            'usuario': usuarioEmail,
            'apartamentos': Map<String, dynamic>.from(
              data['apartamentos'] ?? {},
            ),
            'resetting': Map<String, dynamic>.from(data['resetting'] ?? {}),
          };
        } else {
          // Sumar apartamentos
          final apartMap = Map<String, dynamic>.from(
            data['apartamentos'] ?? {},
          );
          apartMap.forEach((k, v) {
            usuarioUnico!['apartamentos'][k] =
                (usuarioUnico['apartamentos'][k] ?? 0) +
                (v is int ? v : int.tryParse(v.toString()) ?? 0);
          });
          // Sumar resetting
          final resetMap = Map<String, dynamic>.from(data['resetting'] ?? {});
          resetMap.forEach((k, v) {
            usuarioUnico!['resetting'][k] =
                (usuarioUnico['resetting'][k] ?? 0) +
                (v is int ? v : int.tryParse(v.toString()) ?? 0);
          });
        }
      }
    }
    setState(() {
      conteoUsuarios = usuarioUnico != null ? [usuarioUnico] : [];
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Apartamentos'),
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
            : conteoUsuarios.isEmpty
            ? const Center(
                child: Text(
                  'No hay datos de apartamentos finalizados este mes.',
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
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conteo de apartamentos finalizados en',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButton<String>(
                          value: mesActual,
                          dropdownColor: const Color.fromARGB(228, 21, 27, 63),
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          items: mesesDisponibles.map((mes) {
                            return DropdownMenuItem<String>(
                              value: mes,
                              child: Text(mes),
                            );
                          }).toList(),
                          onChanged: (nuevoMes) {
                            if (nuevoMes != null && nuevoMes != mesActual) {
                              setState(() {
                                mesActual = nuevoMes;
                              });
                              cargarConteoMesActual();
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.format_list_numbered,
                                color: Color(0xFF6A82FB),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Total: $totalApartamentosYResetting',
                                style: TextStyle(
                                  color: Color(0xFF6A82FB),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...conteoUsuarios.map(
                    (usuario) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                usuario['usuario'],
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                size: 20,
                                color: Color(0xFF6A82FB),
                              ),
                              tooltip: 'Copiar todo',
                              onPressed: () {
                                final email = usuario['usuario'] ?? '';
                                final apartamentos =
                                    usuario['apartamentos'] as Map? ?? {};
                                final resetting =
                                    usuario['resetting'] as Map? ?? {};
                                final buffer = StringBuffer();
                                buffer.writeln('Usuario: $email');
                                if (apartamentos.isNotEmpty) {
                                  buffer.writeln('Apartamentos:');
                                  apartamentos.forEach((k, v) {
                                    buffer.writeln('  - $k: $v');
                                  });
                                }
                                if (resetting.isNotEmpty) {
                                  buffer.writeln('Resetting:');
                                  resetting.forEach((k, v) {
                                    buffer.writeln('  - $k: $v');
                                  });
                                }
                                Clipboard.setData(
                                  ClipboardData(text: buffer.toString()),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('¡Información copiada!'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        children: [
                          if (usuario['apartamentos'].isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                top: 8,
                                bottom: 4,
                              ),
                              child: Text(
                                'Apartamentos:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6A82FB),
                                ),
                              ),
                            ),
                            ...usuario['apartamentos'].entries.map<Widget>(
                              (e) => ListTile(
                                title: Text(e.key),
                                trailing: Text(
                                  e.value.toString(),
                                  style: const TextStyle(
                                    color: Color(0xFF6A82FB),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (usuario['resetting'].isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                top: 8,
                                bottom: 4,
                              ),
                              child: Text(
                                'Resetting:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFC5C7D),
                                ),
                              ),
                            ),
                            ...usuario['resetting'].entries.map<Widget>(
                              (e) => ListTile(
                                title: Text(e.key),
                                trailing: Text(
                                  e.value.toString(),
                                  style: const TextStyle(
                                    color: Color(0xFFFC5C7D),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
