import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InventarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retorna un mapa con la cantidad de productos por categoría
  Future<Map<String, int>> contarProductosPorCategoria() async {
    Map<String, int> resultado = {};

    try {
      QuerySnapshot snapshot =
          await _firestore.collection('VinosPiscosProductos').get();

      for (var doc in snapshot.docs) {
        String categoria = doc['categoria'] ?? 'Sin categoría';
        if (resultado.containsKey(categoria)) {
          resultado[categoria] = resultado[categoria]! + 1;
        } else {
          resultado[categoria] = 1;
        }
      }
    } catch (e) {
      debugPrint("Error al contar productos: $e");
    }

    return resultado;
  }

  /// Lista todos los productos
  Future<List<Map<String, dynamic>>> listarProductos() async {
    List<Map<String, dynamic>> productos = [];

    try {
      QuerySnapshot snapshot =
          await _firestore.collection('VinosPiscosProductos').get();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Guardar el ID del documento
        productos.add(data);
      }
    } catch (e) {
      debugPrint("Error al listar productos: $e");
    }

    return productos;
  }

  /// Lista productos filtrando por categoría
  Future<List<Map<String, dynamic>>> listarProductosPorCategoria(
    String categoria,
  ) async {
    List<Map<String, dynamic>> productos = [];

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('VinosPiscosProductos')
          .where('categoria', isEqualTo: categoria)
          .get();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Guardar el ID del documento
        productos.add(data);
      }
    } catch (e) {
      debugPrint("Error al listar productos por categoría: $e");
    }

    return productos;
  }

  /// Eliminar producto por ID
  Future<void> eliminarProducto(String id) async {
    try {
      await _firestore.collection('VinosPiscosProductos').doc(id).delete();
    } catch (e) {
      debugPrint("Error al eliminar producto: $e");
    }
  }

  Stream<Map<String, int>> streamConteoProductos() {
    return FirebaseFirestore.instance
        .collection('VinosPiscosProductos')
        .snapshots()
        .map((snapshot) {
      Map<String, int> conteo = {};
      for (var doc in snapshot.docs) {
        String categoria = doc['categoria'] ?? 'Sin categoría';
        conteo[categoria] = (conteo[categoria] ?? 0) + 1;
      }
      List<String> categoriasMaestras = [
        'Vino Tinto',
        'Vino Blanco',
        'Pisco Italia',
        'Pisco Acholado',
        'Pisco Mosto Verde',
        'Pisco Quebranta',
      ];

      Map<String, int> resultadoFinal = {};
      for (String cat in categoriasMaestras) {
        resultadoFinal[cat] = conteo[cat] ?? 0;
      }

      return resultadoFinal;
    });
  }
}
