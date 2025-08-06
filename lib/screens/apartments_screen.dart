import 'package:flutter/material.dart';
import 'add_apartment_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApartmentsScreen extends StatefulWidget {
  final String? rol;
  const ApartmentsScreen({Key? key, this.rol}) : super(key: key);

  @override
  State<ApartmentsScreen> createState() => _ApartmentsScreenState();
}

class _ApartmentsScreenState extends State<ApartmentsScreen> {
  Map<String, dynamic>? lastApartment;
  TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String _dimensionFilter = '';

  Future<void> _addApartment() async {
    // Aquí deberías recibir los datos del apartamento guardado desde AddApartmentScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddApartmentScreen()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        lastApartment = result;
      });
    }
  }

  Widget _apartmentCard(Map<String, dynamic> apt) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                apt['nombre'] ?? 'Sin nombre',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (widget.rol == 'admin')
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Color(0xFF4F8DFD)),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddApartmentScreen(apartmentData: apt),
                          ),
                        );
                        // Ya actualizado en Firestore, puedes mostrar un mensaje o refrescar si es necesario
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // Eliminar apartamento de Firestore
                        if (apt['id'] != null) {
                          await FirebaseFirestore.instance
                              .collection('apartamentos')
                              .doc(apt['id'])
                              .delete();
                        }
                      },
                    ),
                  ],
                ),
            ],
          ),
          if (apt['direccion'] != null &&
              apt['direccion'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                apt['direccion'],
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.home, size: 18, color: Color(0xFF8F9BB3)),
              const SizedBox(width: 6),
              Text('Número: ${apt['numero'] ?? ''}'),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.vpn_key, size: 18, color: Color(0xFF8F9BB3)),
              const SizedBox(width: 6),
              Text(
                'Número de la caja de la llave: ${apt['numeroCajaLlave'] ?? ''}',
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.apartment, size: 18, color: Color(0xFF8F9BB3)),
              const SizedBox(width: 6),
              Text('Piso: ${apt['piso'] ?? ''}'),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Color(0xFF8F9BB3)),
              const SizedBox(width: 6),
              Text('Citófono: ${apt['citofono'] ?? ''}'),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.phone, size: 18, color: Color(0xFF8F9BB3)),
              const SizedBox(width: 6),
              Text('Teléfono: ${apt['telefono'] ?? ''}'),
            ],
          ),
          if (apt['nota'] != null && apt['nota'].toString().isNotEmpty)
            Row(
              children: [
                const Icon(Icons.note, size: 18, color: Color(0xFF8F9BB3)),
                const SizedBox(width: 6),
                Expanded(child: Text('Nota: ${apt['nota']}')),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Apartamentos',
          style: TextStyle(
            color: Color(0xFF222B45),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.rol == 'admin')
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF222B45)),
              onPressed: _addApartment,
            ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF8F9BB3)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar apartamentos...',
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            style: TextStyle(fontSize: 16),
                            onChanged: (value) {
                              setState(() {
                                _searchText = value.trim().toLowerCase();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Validar que el valor esté en la lista de ítems permitidos y limpiar si no es válido
                Builder(
                  builder: (context) {
                    final allowed = ['', 'pequeño', 'mediano', 'grande'];
                    if (!allowed.contains(_dimensionFilter)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _dimensionFilter = '';
                        });
                      });
                    }
                    return DropdownButton<String>(
                      value: allowed.contains(_dimensionFilter)
                          ? _dimensionFilter
                          : '',
                      hint: const Text('Dimensión'),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Todas')),
                        DropdownMenuItem(
                          value: 'pequeño',
                          child: Text('Pequeño'),
                        ),
                        DropdownMenuItem(
                          value: 'mediano',
                          child: Text('Mediano'),
                        ),
                        DropdownMenuItem(
                          value: 'grande',
                          child: Text('Grande'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _dimensionFilter = value ?? '';
                        });
                      },
                      underline: Container(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('apartamentos')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text('No hay apartamentos registrados.'),
                    );
                  }
                  final docs = snapshot.data!.docs;
                  var filteredDocs = docs;
                  if (_searchText.isNotEmpty) {
                    filteredDocs = filteredDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nombre = (data['nombre'] ?? '')
                          .toString()
                          .toLowerCase();
                      return nombre.contains(_searchText);
                    }).toList();
                  }
                  if (_dimensionFilter.isNotEmpty) {
                    filteredDocs = filteredDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final dimension = (data['dimension'] ?? '')
                          .toString()
                          .toLowerCase();
                      return dimension == _dimensionFilter;
                    }).toList();
                  }
                  // Ordenar alfabéticamente por nombre
                  filteredDocs.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;
                    final nombreA = (dataA['nombre'] ?? '')
                        .toString()
                        .toLowerCase();
                    final nombreB = (dataB['nombre'] ?? '')
                        .toString()
                        .toLowerCase();
                    return nombreA.compareTo(nombreB);
                  });
                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      return _apartmentCard(data);
                    },
                  );
                },
              ),
            ),
            // Aquí puedes agregar la lista de apartamentos
          ],
        ),
      ),
    );
  }
}
