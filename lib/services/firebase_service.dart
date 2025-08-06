import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<void> guardarApartamento(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    if (id != null && id.isNotEmpty) {
      await firestore.collection('apartamentos').doc(id).update(data);
    } else {
      await firestore.collection('apartamentos').add(data);
    }
  }
}
