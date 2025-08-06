// Para que la carga de foto funcione, agrega en pubspec.yaml:
//
// dependencies:
//   image_picker: ^1.0.7
//   firebase_storage: ^11.6.6
//
// Luego ejecuta:
// flutter pub get
//
// Además, asegúrate de tener configurado Firebase Storage en tu proyecto.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  final String? rol;
  const ProfileScreen({Key? key, this.rol}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  Future<void> _pickAndUploadPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;
    setState(() {
      loading = true;
    });
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_photos/${user.uid}.jpg',
      );
      await storageRef.putData(await image.readAsBytes());
      final url = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fotoUrl': url},
      );
      setState(() {
        fotoUrl = url;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la foto de perfil')),
      );
    }
  }

  String nombre = '';
  String apellido = '';
  String email = '';
  String telefono = '';
  String fotoUrl = '';
  int propiedades = 0;
  int horas = 0;
  double rating = 0.0;
  String rolDescripcion = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    final uid = user.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();
    setState(() {
      nombre = data?['nombre'] ?? '';
      apellido = data?['apellido'] ?? '';
      email = data?['email'] ?? user.email ?? '';
      telefono = data?['telefono'] ?? '';
      fotoUrl = data?['fotoUrl'] ?? '';
      propiedades = data?['propiedades'] ?? 0;
      horas = data?['horas'] ?? 0;
      rating = (data?['rating'] ?? 0).toDouble();
      rolDescripcion = data?['rolDescripcion'] ?? '';
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F8FA),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 24),
                      // Card superior: foto, nombre y UID (no editable)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [Color(0xFF6A5AE0), Color(0xFF6ED0F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundImage: (fotoUrl.isNotEmpty)
                                      ? NetworkImage(fotoUrl)
                                      : null,
                                  child: (fotoUrl.isEmpty)
                                      ? Icon(
                                          Icons.person,
                                          size: 32,
                                          color: Colors.white,
                                        )
                                      : null,
                                  backgroundColor: Color(0xFF6A5AE0),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickAndUploadPhoto,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.edit,
                                        color: Color(0xFF6A5AE0),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (nombre + ' ' + apellido).trim().isEmpty
                                        ? 'Sin nombre'
                                        : (nombre + ' ' + apellido),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  FutureBuilder<User?>(
                                    future: Future.value(
                                      FirebaseAuth.instance.currentUser,
                                    ),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return SizedBox();
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 2,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'UID: ' + snapshot.data!.uid,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      // Información personal editable
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Editar Perfil',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildEditableTextField(
                              'Nombre',
                              nombre,
                              (val) => setState(() => nombre = val),
                            ),
                            SizedBox(height: 10),
                            _buildEditableTextField(
                              'Apellido',
                              apellido,
                              (val) => setState(() => apellido = val),
                            ),
                            SizedBox(height: 10),
                            _buildEditableTextField(
                              'Email',
                              email,
                              (val) => setState(() => email = val),
                            ),
                            SizedBox(height: 10),
                            _buildEditableTextField(
                              'Teléfono',
                              telefono,
                              (val) => setState(() => telefono = val),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .update({
                                        'nombre': nombre,
                                        'apellido': apellido,
                                        'email': email,
                                        'telefono': telefono,
                                      });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Perfil actualizado'),
                                    ),
                                  );
                                }
                              },
                              child: Text('Guardar Cambios'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      // Menú de acciones
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              Icons.group,
                              'Trabajadores',
                              iconColor: Color(0xFF009688),
                              onTap: () {
                                Navigator.pushNamed(context, '/trabajadores');
                              },
                            ),
                            // Notificaciones eliminado por solicitud del usuario
                            _buildMenuItem(
                              Icons.logout,
                              'Cerrar Sesión',
                              iconColor: Color(0xFFFF3B30),
                              textColor: Color(0xFFFF3B30),
                              onTap: () async {
                                await FirebaseAuth.instance.signOut();
                                if (mounted) {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/',
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEditableTextField(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.black87)),
        SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Color(0xFFF7F8FA),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String text, {
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Color(0xFF6A5AE0)),
      title: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black26),
      onTap: onTap,
    );
  }
}
