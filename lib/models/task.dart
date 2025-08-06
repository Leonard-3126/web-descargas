import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String titulo;
  final String descripcion;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime fechaLimite;
  final String apartamentoId;
  final String usuarioId;
  final double tEst;
  final double tReal;
  final List<String> evidencias;
  final double pagoTotal;

  TaskModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaLimite,
    required this.apartamentoId,
    required this.usuarioId,
    required this.tEst,
    required this.tReal,
    required this.evidencias,
    required this.pagoTotal,
  });

  factory TaskModel.fromMap(Map<String, dynamic> data) {
    return TaskModel(
      id: data['id'] ?? '',
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      estado: data['estado'] ?? '',
      fechaCreacion: (data['fechaCreacion'] is Timestamp)
          ? (data['fechaCreacion'] as Timestamp).toDate()
          : DateTime.tryParse(data['fechaCreacion'] ?? '') ?? DateTime.now(),
      fechaLimite: (data['fechaLimite'] is Timestamp)
          ? (data['fechaLimite'] as Timestamp).toDate()
          : DateTime.tryParse(data['fechaLimite'] ?? '') ?? DateTime.now(),
      apartamentoId: data['apartamentoId'] ?? '',
      usuarioId: data['usuarioId'] ?? '',
      tEst: (data['t_est'] ?? 0).toDouble(),
      tReal: (data['t_real'] ?? 0).toDouble(),
      evidencias: List<String>.from(data['evidencias'] ?? []),
      pagoTotal: (data['pago_total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'estado': estado,
      'fechaCreacion': fechaCreacion,
      'fechaLimite': fechaLimite,
      'apartamentoId': apartamentoId,
      'usuarioId': usuarioId,
      't_est': tEst,
      't_real': tReal,
      'evidencias': evidencias,
      'pago_total': pagoTotal,
    };
  }
}
