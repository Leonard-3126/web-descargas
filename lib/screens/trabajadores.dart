import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:w_cleaning/widgets/dashboard_visita.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class TrabajadoresScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trabajadores'),
        backgroundColor: Color(0xFF009688),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final rol = authProvider.userRole;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No hay trabajadores registrados'));
              }
              final users = snapshot.data!.docs;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  final nombre =
                      (user['nombre'] ?? '') + ' ' + (user['apellido'] ?? '');
                  final telefono = user['telefono'] ?? 'Sin teléfono';
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(nombre.isEmpty ? 'Sin nombre' : nombre),
                      subtitle: Row(
                        children: [
                          Expanded(child: Text(telefono)),
                          IconButton(
                            icon: Icon(Icons.copy, size: 18),
                            tooltip: 'Copiar número',
                            onPressed: () {
                              if (telefono != 'Sin teléfono') {
                                Clipboard.setData(
                                  ClipboardData(text: telefono),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Teléfono copiado')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      trailing: rol == 'admin'
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF009688),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DashboardVisita(user: user),
                                  ),
                                );
                              },
                              child: Text('Visita'),
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
