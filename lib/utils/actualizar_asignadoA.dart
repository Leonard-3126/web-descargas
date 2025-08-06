import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> actualizarAsignadoA() async {
  final firestore = FirebaseFirestore.instance;
  final colecciones = [
    'Apartamentos',
    'Resetting',
    'Limpieza_a_fondo',
    'Horas_extra',
  ];
  final fechaStr =
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
  for (final categoria in colecciones) {
    final docRef = firestore
        .collection('itinerarios_v2')
        .doc('${fechaStr}_$categoria');
    final snapshot = await docRef.collection('apartamentos').get();
    for (final doc in snapshot.docs) {
      final asignaciones = await doc.reference.collection('asignaciones').get();
      if (asignaciones.docs.isNotEmpty) {
        final asignado = asignaciones.docs.first.data()['nombre'];
        await doc.reference.update({'asignadoA': asignado});
      }
    }
  }
}

// Para ejecutar: llama a actualizarAsignadoA() desde main o desde un botón de admin.
