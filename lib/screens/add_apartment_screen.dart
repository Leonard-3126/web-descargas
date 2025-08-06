import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AddApartmentScreen extends StatefulWidget {
  final Map<String, dynamic>? apartmentData;
  const AddApartmentScreen({Key? key, this.apartmentData}) : super(key: key);

  @override
  State<AddApartmentScreen> createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _viaController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _citofonoController = TextEditingController();
  final TextEditingController _pisoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _numeroCajaLlaveController =
      TextEditingController();
  final TextEditingController _notaController = TextEditingController();
  final TextEditingController _horasController = TextEditingController();
  String? _dimensionValue;

  @override
  void initState() {
    super.initState();
    if (widget.apartmentData != null) {
      final data = widget.apartmentData!;
      _nombreController.text = data['nombre'] ?? '';
      _viaController.text = data['direccion'] ?? '';
      _numeroController.text = data['numero'] ?? '';
      _citofonoController.text = data['citofono'] ?? '';
      _pisoController.text = data['piso'] ?? '';
      _telefonoController.text = data['telefono'] ?? '';
      _numeroCajaLlaveController.text = data['numeroCajaLlave'] ?? '';
      _notaController.text = data['nota'] ?? '';
      _horasController.text = data['horas'] ?? '';
      _dimensionValue = data['dimension'];
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _viaController.dispose();
    _numeroController.dispose();
    _citofonoController.dispose();
    _pisoController.dispose();
    _telefonoController.dispose();
    _numeroCajaLlaveController.dispose();
    _notaController.dispose();
    _horasController.dispose();
    // _dimensionController eliminado
    super.dispose();
  }

  final FirebaseService _firebaseService = FirebaseService();

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final datos = {
        'Nombre': _nombreController.text.trim(),
        'Via': _viaController.text.trim(),
        'Número': _numeroController.text.trim(),
        'Número de la caja de la llave': _numeroCajaLlaveController.text.trim(),
        'Citófono': _citofonoController.text.trim(),
        'Piso': _pisoController.text.trim(),
        'Teléfono': _telefonoController.text.trim(),
        'Horas': _horasController.text.trim(),
        'Dimensión': _dimensionValue ?? '',
        'Nota': _notaController.text.trim(),
      };
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Datos del apartamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: datos.entries
                .where((e) => e.value.isNotEmpty)
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text(e.value)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Editar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final isEdit =
                    widget.apartmentData != null &&
                    widget.apartmentData!['id'] != null;
                final id = isEdit
                    ? widget.apartmentData!['id'] as String
                    : null;
                final dataToSave = {
                  'nombre': _nombreController.text.trim(),
                  'direccion': _viaController.text.trim(),
                  'numero': _numeroController.text.trim(),
                  'numeroCajaLlave': _numeroCajaLlaveController.text.trim(),
                  'citofono': _citofonoController.text.trim(),
                  'piso': _pisoController.text.trim(),
                  'telefono': _telefonoController.text.trim(),
                  'horas': _horasController.text.trim(),
                  'dimension': _dimensionValue ?? '',
                  'nota': _notaController.text.trim(),
                };
                await _firebaseService.guardarApartamento(dataToSave, id: id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        id != null
                            ? 'Apartamento actualizado correctamente'
                            : 'Apartamento guardado correctamente',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                Navigator.pop(context, {
                  ...dataToSave,
                  if (id != null) 'id': id,
                });
              },
              child: const Text('Confirmar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFAB47BC),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar apartamento'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF222B45)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF222B45),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _viaController,
                decoration: const InputDecoration(labelText: 'Via'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(labelText: 'Número'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _citofonoController,
                decoration: const InputDecoration(labelText: 'Citófono'),
              ),
              TextFormField(
                controller: _pisoController,
                decoration: const InputDecoration(labelText: 'Piso'),
              ),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Número de teléfono',
                ),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _numeroCajaLlaveController,
                decoration: const InputDecoration(
                  labelText: 'Número de la caja de la llave',
                ),
              ),
              TextFormField(
                controller: _horasController,
                decoration: const InputDecoration(labelText: 'Horas'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              DropdownButtonFormField<String>(
                value: _dimensionValue,
                decoration: const InputDecoration(labelText: 'Dimensión'),
                items: const [
                  DropdownMenuItem(value: 'pequeño', child: Text('Pequeño')),
                  DropdownMenuItem(value: 'mediano', child: Text('Mediano')),
                  DropdownMenuItem(value: 'grande', child: Text('Grande')),
                ],
                onChanged: (value) {
                  setState(() {
                    _dimensionValue = value;
                  });
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _notaController,
                decoration: const InputDecoration(labelText: 'Nota'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardar,
                child: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFAB47BC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
