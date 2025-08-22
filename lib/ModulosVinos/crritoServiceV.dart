import 'package:flutter/material.dart';

class CarritoServiceVinos extends ChangeNotifier {
  final Map<String, List<Map<String, dynamic>>> _carritosPorUsuario = {};

  String? _uidActual;

  void setUsuario(String? uid) {
    _uidActual = uid;
    _carritosPorUsuario.putIfAbsent(_uidActual ?? 'anonimo', () => []);
    notifyListeners();
  }

  List<Map<String, dynamic>> get _carritoActual =>
      _carritosPorUsuario[_uidActual ?? 'anonimo'] ?? [];

  void agregarProductoVinos(Map<String, dynamic> nuevoProducto) {
    final nombreProducto = nuevoProducto['nombreProducto'];
    final marca = nuevoProducto['marca'];
    final volumen = nuevoProducto['volumen'];

    int cantidadNueva = 1;

    if (nuevoProducto['cantidad'] is int) {
      cantidadNueva = nuevoProducto['cantidad'];
    } else if (nuevoProducto['cantidad'] is String) {
      cantidadNueva = int.tryParse(nuevoProducto['cantidad']) ?? 1;
    }

    int indexExistente = _carritoActual.indexWhere(
      (item) =>
          item['nombreProducto'] == nombreProducto &&
          item['marca'] == marca &&
          item['volumen'] == volumen,
    );

    if (indexExistente != -1) {
      var productoExistente = _carritoActual[indexExistente];
      int cantidadExistente = productoExistente['cantidad'] is int
          ? productoExistente['cantidad']
          : int.tryParse(productoExistente['cantidad'].toString()) ?? 1;

      productoExistente['cantidad'] = cantidadExistente + cantidadNueva;
      productoExistente['descuento'] = nuevoProducto['descuento'];
    } else {
      nuevoProducto['cantidad'] = cantidadNueva;
      _carritoActual.add(nuevoProducto);
    }

    notifyListeners();
  }

  List<Map<String, dynamic>> obtenerCarrito() =>
      List.unmodifiable(_carritoActual);

  void limpiarCarrito() {
    _carritoActual.clear();
    _direccionEntrega = '';
    notifyListeners();
  }

  void limpiardescripcion() {
    _direccionEntrega = '';
    notifyListeners();
  }

  void eliminarProducto(int index) {
    if (index >= 0 && index < _carritoActual.length) {
      _carritoActual.removeAt(index);
      notifyListeners();
    }
  }

  double calcularTotal() {
    return _carritoActual.fold(0.0, (sum, item) {
      double precio;

      if (item['precio'] is String) {
        precio = double.tryParse(item['precio']) ?? 0.0;
      } else if (item['precio'] is num) {
        precio = item['precio'].toDouble();
      } else {
        precio = 0.0;
      }

      int cantidad = item['cantidad'] ?? 1;

      return sum + (precio * cantidad);
    });
  }

  int obtenerCantidadTotal() {
    return _carritoActual.length;
  }

  int obtenerCantidadTotalProductos() {
    int total = 0;
    for (var producto in _carritoActual) {
      if (producto['cantidad'] is int) {
        total += producto['cantidad'] as int;
      } else if (producto['cantidad'] is String) {
        total += int.tryParse(producto['cantidad']) ?? 0;
      }
    }
    return total;
  }

  String _direccionEntrega = '';

  String get direccionEntrega =>
      _direccionEntrega.isNotEmpty ? _direccionEntrega : '';

  void guardarDireccionEntrega(String nuevaDireccion) {
    _direccionEntrega = nuevaDireccion.trim();
    notifyListeners();
  }
}
