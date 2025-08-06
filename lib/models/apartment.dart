import 'package:cloud_firestore/cloud_firestore.dart';

class ApartmentModel {
  final String id;
  final String nombre;
  final String direccion;
  final String detalles;
  final String tipo;
  final List<String> fotos;
  final List<String> usuariosAsignados;
  final List<String> tareas;
  final String estado;
  final DateTime fechaCreacion;

  ApartmentModel({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.detalles,
    required this.tipo,
    required this.fotos,
    required this.usuariosAsignados,
    required this.tareas,
    required this.estado,
    required this.fechaCreacion,
  });

  factory ApartmentModel.fromMap(Map<String, dynamic> data) {
    return ApartmentModel(
      id: data['id'] ?? '',
      nombre: data['nombre'] ?? '',
      direccion: data['direccion'] ?? '',
      detalles: data['detalles'] ?? '',
      tipo: data['tipo'] ?? '',
      fotos: List<String>.from(data['fotos'] ?? []),
      usuariosAsignados: List<String>.from(data['usuariosAsignados'] ?? []),
      tareas: List<String>.from(data['tareas'] ?? []),
      estado: data['estado'] ?? '',
      fechaCreacion: (data['fechaCreacion'] is Timestamp)
          ? (data['fechaCreacion'] as Timestamp).toDate()
          : DateTime.tryParse(data['fechaCreacion'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'detalles': detalles,
      'tipo': tipo,
      'fotos': fotos,
      'usuariosAsignados': usuariosAsignados,
      'tareas': tareas,
      'estado': estado,
      'fechaCreacion': fechaCreacion,
    };
  }
}
