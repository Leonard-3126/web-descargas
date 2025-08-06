import 'package:cloud_firestore/cloud_firestore.dart';

class ItineraryModel {
  final String id;
  final String usuarioId;
  final DateTime fecha;
  final List<String> listaTareas;
  final String categoria;
  final String descripcion;

  ItineraryModel({
    required this.id,
    required this.usuarioId,
    required this.fecha,
    required this.listaTareas,
    required this.categoria,
    required this.descripcion,
  });

  factory ItineraryModel.fromMap(Map<String, dynamic> data) {
    return ItineraryModel(
      id: data['id'] ?? '',
      usuarioId: data['usuarioId'] ?? '',
      fecha: (data['fecha'] is Timestamp)
          ? (data['fecha'] as Timestamp).toDate()
          : DateTime.tryParse(data['fecha'] ?? '') ?? DateTime.now(),
      listaTareas: List<String>.from(data['listaTareas'] ?? []),
      categoria: data['categoria'] ?? '',
      descripcion: data['descripcion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'fecha': fecha,
      'listaTareas': listaTareas,
      'categoria': categoria,
      'descripcion': descripcion,
    };
  }
}
