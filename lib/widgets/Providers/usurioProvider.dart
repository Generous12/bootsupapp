import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsuarioProvider with ChangeNotifier {
  DocumentSnapshot? _datosUsuario;
  String? _uid;

  DocumentSnapshot? get datosUsuario => _datosUsuario;

  Future<void> cargarDatos(String uid) async {
    if (_uid == uid && _datosUsuario != null) return;
    _uid = uid;

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    _datosUsuario = snapshot;
    notifyListeners();
  }

  Future<void> recargarDatos() async {
    if (_uid != null) {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      _datosUsuario = snapshot;
      notifyListeners();
    }
  }
}
