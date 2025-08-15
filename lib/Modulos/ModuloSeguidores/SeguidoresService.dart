import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SeguidorService {
  Future<Map<String, dynamic>?> fetchEmpresaDataSeguir(String userId) async {
    try {
      final empresaQuery = await FirebaseFirestore.instance
          .collection('empresa')
          .where('userid', isEqualTo: userId)
          .limit(1)
          .get();

      if (empresaQuery.docs.isNotEmpty) {
        final empresaDoc = empresaQuery.docs.first;
        final data = empresaDoc.data();
        return {
          ...data,
          'id': empresaDoc.id,
        };
      }
      return null;
    } catch (e) {
      debugPrint("Error al obtener datos empresa: $e");
      return null;
    }
  }

  Future<void> initVerificacionSeguidor(String userId) async {
    try {
      final empresaData = await fetchEmpresaDataSeguir(userId);
      if (empresaData != null && empresaData['id'] != null) {
        final idEmpresa = empresaData['id'];
        await verificarSiSigueEmpresa(idEmpresa);
      } else {
        debugPrint(
            'No se encontró la empresa o ID inválido para userId: $userId');
      }
    } catch (e) {
      debugPrint('Error en initVerificacionSeguidor: $e');
    }
  }

  Future<String> obtenerTipoSeguidor(String userId) async {
    try {
      final empresaQuery = await FirebaseFirestore.instance
          .collection('empresa')
          .where('userid', isEqualTo: userId)
          .get();

      if (empresaQuery.docs.isNotEmpty) return 'empresa';

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('userid', isEqualTo: userId)
          .get();

      if (userQuery.docs.isNotEmpty) return 'usuario';

      return 'usuario';
    } catch (e) {
      debugPrint("Error al obtener tipo seguidor: $e");
      return 'usuario';
    }
  }

  Future<bool> seguirEmpresa(String idEmpresa) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final idUsuario = user.uid;

      final snapshot = await FirebaseFirestore.instance
          .collection('seguidores')
          .where('idusuario', isEqualTo: idUsuario)
          .where('idempresasiguiendo', isEqualTo: idEmpresa)
          .get();

      if (snapshot.docs.isEmpty) {
        final tipoSeguidor = await obtenerTipoSeguidor(idUsuario);
        await FirebaseFirestore.instance.collection('seguidores').add({
          'idusuario': idUsuario,
          'idempresasiguiendo': idEmpresa,
          'tipoSeguidor': tipoSeguidor,
          'timestamp': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      debugPrint("Error al seguir la empresa: $e");
    }
    return false;
  }

  Future<bool> verificarSiSigueEmpresa(String idEmpresa) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final idUsuario = user.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('seguidores')
        .where('idusuario', isEqualTo: idUsuario)
        .where('idempresasiguiendo', isEqualTo: idEmpresa)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<bool> dejarDeSeguirEmpresa(String idEmpresa) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final idUsuario = user.uid;

      final snapshot = await FirebaseFirestore.instance
          .collection('seguidores')
          .where('idusuario', isEqualTo: idUsuario)
          .where('idempresasiguiendo', isEqualTo: idEmpresa)
          .get();

      for (var doc in snapshot.docs) {
        await FirebaseFirestore.instance
            .collection('seguidores')
            .doc(doc.id)
            .delete();
      }

      return true;
    } catch (e) {
      debugPrint("Error al dejar de seguir la empresa: $e");
      return false;
    }
  }

  Future<int> countSeguidoresEmpresa(String idEmpresa) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('seguidores')
          .where('idempresasiguiendo', isEqualTo: idEmpresa)
          .get();
      return querySnapshot.size;
    } catch (e) {
      debugPrint('Error al contar los seguidores: $e');
      return 0;
    }
  }
}
