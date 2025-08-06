import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  UserModel? userModel;

  Future<void> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    user = credential.user;
    // Obtener datos del usuario desde Firestore
    final doc = await _firestore.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      userModel = UserModel.fromMap(doc.data()!);
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    user = null;
    userModel = null;
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    user = credential.user;
    notifyListeners();
  }

  bool get isLoggedIn => user != null;
  String? get userRole => userModel?.rol;
}
