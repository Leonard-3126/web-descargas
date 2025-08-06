import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nombre;
  final String email;
  final String rol;
  final String fotoUrl;
  final List<String> apartamentosAsignados;
  final List<String> tareasAsignadas;
  final DateTime fechaRegistro;
  final double tarifaExtra;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.fotoUrl,
    required this.apartamentosAsignados,
    required this.tareasAsignadas,
    required this.fechaRegistro,
    required this.tarifaExtra,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      rol: data['rol'] ?? '',
      fotoUrl: data['fotoUrl'] ?? '',
      apartamentosAsignados: List<String>.from(
        data['apartamentosAsignados'] ?? [],
      ),
      tareasAsignadas: List<String>.from(data['tareasAsignadas'] ?? []),
      fechaRegistro: (data['fechaRegistro'] is Timestamp)
          ? (data['fechaRegistro'] as Timestamp).toDate()
          : DateTime.tryParse(data['fechaRegistro'] ?? '') ?? DateTime.now(),
      tarifaExtra: (data['tarifaExtra'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'fotoUrl': fotoUrl,
      'apartamentosAsignados': apartamentosAsignados,
      'tareasAsignadas': tareasAsignadas,
      'fechaRegistro': fechaRegistro,
      'tarifaExtra': tarifaExtra,
    };
  }
}
