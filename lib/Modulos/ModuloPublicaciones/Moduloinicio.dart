import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static Future<List<DocumentSnapshot>> fetchProductos() async {
    try {
      Query productosQuery = FirebaseFirestore.instance.collection('productos');
      QuerySnapshot productosSnapshot = await productosQuery.get();
      return productosSnapshot.docs;
    } catch (e) {
      print("Error al cargar los productos: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPublicacionesConEmpresa({
    required List<String> idsMostrados,
    int limit = 6,
    required String userId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 🔹 1. Obtener publicaciones
      Query query = firestore
          .collection('publicaciones')
          .orderBy('fecha', descending: true)
          .limit(30); // más para evitar duplicados

      QuerySnapshot publicacionesSnapshot = await query.get();
      List<QueryDocumentSnapshot> docs = publicacionesSnapshot.docs;

      // 🔹 2. Filtrar y barajar
      docs.removeWhere((doc) => idsMostrados.contains(doc.id));
      docs.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
      final subset = docs.take(limit).toList();
      idsMostrados.addAll(subset.map((doc) => doc.id));

      // 🔹 3. Cache de empresas
      final empresaIds = subset
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['publicacionDeEmpresa'])
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> empresaCache = {};
      const batchSize = 10;
      for (var i = 0; i < empresaIds.length; i += batchSize) {
        var batch = empresaIds.skip(i).take(batchSize).toList();
        var empresasSnapshot = await firestore
            .collection('empresa')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var empresaDoc in empresasSnapshot.docs) {
          empresaCache[empresaDoc.id] = empresaDoc.data();
        }
      }

      // 🔹 4. Recolectar futures en paralelo para likes y comentarios
      final List<Future<Map<String, dynamic>>> futures =
          subset.map((pubDoc) async {
        final pubData = pubDoc.data() as Map<String, dynamic>;
        final String? empresaId = pubData['publicacionDeEmpresa'];
        final empresaData = empresaCache[empresaId];

        final meGustasFuture = pubDoc.reference.collection('meGustas').get();
        final comentariosFuture =
            pubDoc.reference.collection('comentarios').get();
        final dioLikeFuture =
            pubDoc.reference.collection('meGustas').doc(userId).get();

        final results = await Future.wait([
          meGustasFuture,
          comentariosFuture,
          dioLikeFuture,
        ]);

        final meGustasSnap = results[0] as QuerySnapshot;
        final comentariosSnap = results[1] as QuerySnapshot;
        final dioLikeSnap = results[2] as DocumentSnapshot;

        return {
          'empresaId': empresaId, //
          'publicacion': empresaData?['nombre'] ?? 'Nombre no disponible',
          'perfilEmpresa': empresaData?['perfilEmpresa'] ?? '',
          'descripcion': pubData['descripcion'] ?? '',
          'userid': pubData['userid'] ?? '',
          'imagenes': pubData['imagenes'] ?? [],
          'fecha': pubData['fecha'] != null
              ? (pubData['fecha'] as Timestamp).toDate()
              : null,
          'empresa': empresaData,
          'cantidadMeGustas': meGustasSnap.size,
          'cantidadComentarios': comentariosSnap.size,
          'dioLike': dioLikeSnap.exists,
          'imageRatio': pubData['imageRatio'] != null
              ? {
                  'width': (pubData['imageRatio']['width'] ?? 1.0).toDouble(),
                  'height': (pubData['imageRatio']['height'] ?? 1.0).toDouble(),
                }
              : {'width': 1.0, 'height': 1.0},
          'docRef': pubDoc,
        };
      }).toList();

      // 🔹 5. Esperar todos en paralelo
      final publicacionesConEmpresa = await Future.wait(futures);

      return publicacionesConEmpresa;
    } catch (e) {
      print('❌ Error al cargar publicaciones: $e');
      return [];
    }
  }

  /// Dar Me Gusta
  Future<void> darMeGusta(String publicacionId, String userId) async {
    final docRef = _db
        .collection('publicaciones')
        .doc(publicacionId)
        .collection('meGustas')
        .doc(userId);

    await docRef.set({'fecha': Timestamp.now()});
  }

  /// Quitar Me Gusta
  Future<void> quitarMeGusta(String publicacionId, String userId) async {
    final docRef = _db
        .collection('publicaciones')
        .doc(publicacionId)
        .collection('meGustas')
        .doc(userId);

    await docRef.delete();
  }

  /// Verifica si el usuario ha dado like (opcional para UI)
  Future<bool> haDadoMeGusta(String publicacionId, String userId) async {
    final docSnap = await _db
        .collection('publicaciones')
        .doc(publicacionId)
        .collection('meGustas')
        .doc(userId)
        .get();

    return docSnap.exists;
  }

  /// Comentar en una publicación
  Future<void> comentar(
      String publicacionId, String userId, String texto) async {
    final docRef = _db
        .collection('publicaciones')
        .doc(publicacionId)
        .collection('comentarios')
        .doc();

    await docRef.set({
      'usuarioId': userId,
      'texto': texto,
      'fecha': Timestamp.now(),
    });
  }

  /// Eliminar comentario (solo si pertenece al usuario)
  Future<void> eliminarComentario(
      String publicacionId, String comentarioId, String userId) async {
    final docRef = _db
        .collection('publicaciones')
        .doc(publicacionId)
        .collection('comentarios')
        .doc(comentarioId);

    final snap = await docRef.get();
    if (snap.exists && snap.data()?['usuarioId'] == userId) {
      await docRef.delete();
    }
  }
}
