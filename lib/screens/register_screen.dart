import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String error = '';
  bool loading = false;
  String selectedRole = 'operario(a)';
  final List<String> roles = ['admin', 'supervisor', 'operario(a)'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nombre'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: 'Apellido'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Correo electrónico'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirmar contraseña'),
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: roles
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role[0].toUpperCase() + role.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Rol'),
              ),
              SizedBox(height: 24),
              loading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          error = '';
                          loading = true;
                        });
                        if (nameController.text.isEmpty ||
                            lastNameController.text.isEmpty ||
                            emailController.text.isEmpty) {
                          setState(() {
                            error = 'Completa todos los campos obligatorios';
                            loading = false;
                          });
                          return;
                        }
                        if (passwordController.text !=
                            confirmPasswordController.text) {
                          setState(() {
                            error = 'Las contraseñas no coinciden';
                            loading = false;
                          });
                          return;
                        }
                        try {
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          // Registrar usuario en Firebase Auth
                          await authProvider.signUp(
                            emailController.text.trim(),
                            passwordController.text.trim(),
                          );
                          final user = authProvider.user;
                          if (user != null) {
                            // Guardar datos adicionales en Firestore
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                                  'nombre': nameController.text.trim(),
                                  'apellido': lastNameController.text.trim(),
                                  'telefono': phoneController.text.trim(),
                                  'email': emailController.text.trim(),
                                  'uid': user.uid,
                                  'rol': selectedRole,
                                });
                          } else {
                            setState(() {
                              error =
                                  'No se pudo obtener el usuario registrado.';
                              loading = false;
                            });
                            return;
                          }
                          setState(() {
                            loading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cuenta registrada correctamente'),
                            ),
                          );
                          Navigator.of(context).pop();
                        } catch (e) {
                          setState(() {
                            error =
                                'Error al registrar usuario: ' + e.toString();
                            loading = false;
                          });
                        }
                      },
                      child: Text('Registrar'),
                    ),
              if (error.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(error, style: TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
