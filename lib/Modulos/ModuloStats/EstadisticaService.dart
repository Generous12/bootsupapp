import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class EstadisticaService {
  Future<Map<String, dynamic>> obtenerEstadisticasCompras(
      String empresaId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('compras')
        .where('empresaId', isEqualTo: empresaId)
        .get();

    final Map<String, int> comprasPorDia = {};
    double totalIngresos = 0;
    double totalDescuentos = 0;
    double totalImpuestos = 0;
    double totalSubtotal = 0;
    int totalCompras = snapshot.docs.length;

    final Map<String, int> contadorProductos = {};
    final Map<String, int> contadorCategorias = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final usuarioId = data['usuarioId'];
      final fecha = (data['fecha'] as Timestamp?)?.toDate();
      final total = (data['total'] as num?)?.toDouble() ?? 0.0;
      final descuento = (data['descuento'] as num?)?.toDouble() ?? 0.0;
      final impuesto = (data['impuesto'] as num?)?.toDouble() ?? 0.0;
      final subtotal = (data['subtotal'] as num?)?.toDouble() ?? 0.0;
      final productos = data['productos'] as List<dynamic>? ?? [];

      if (usuarioId == null || fecha == null) continue;

      // Compras por día
      final dia = DateFormat('dd/MM').format(fecha);
      comprasPorDia[dia] = (comprasPorDia[dia] ?? 0) + 1;

      // Totales acumulados
      totalIngresos += total;
      totalDescuentos += descuento;
      totalImpuestos += impuesto;
      totalSubtotal += subtotal;

      // Conteo de productos y categorías
      for (var producto in productos) {
        final nombre = producto['nombreProducto'] ?? 'Desconocido';
        final categoria = producto['categoria'] ?? 'Sin categoría';
        final cantidad = (producto['cantidad'] ?? 1) as int;

        contadorProductos[nombre] = (contadorProductos[nombre] ?? 0) + cantidad;
        contadorCategorias[categoria] =
            (contadorCategorias[categoria] ?? 0) + cantidad;
      }
    }

    // Ordenar productos y categorías más vendidos
    final topProductos = Map.fromEntries(
      contadorProductos.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    final topCategorias = Map.fromEntries(
      contadorCategorias.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    return {
      'comprasPorDia': comprasPorDia,
      'ingresosTotales': totalIngresos,
      'descuentosTotales': totalDescuentos,
      'impuestosTotales': totalImpuestos,
      'subtotalPromedio': totalCompras > 0 ? totalSubtotal / totalCompras : 0,
      'totalCompras': totalCompras,
      'topProductos': topProductos,
      'topCategorias': topCategorias,
    };
  }
}
//PDF

class PDFGenerator {
  static Future<File> generarBoleta({
    required int totalCompras,
    required double ingresosTotales,
    required double descuentosTotales,
    required double impuestosTotales,
    required double subtotalPromedio,
    required Map<String, int> topProductos,
    required Map<String, int> topCategorias,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text('Estadisticas generales',
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 24),

            // 🧾 Tabla de resumen
            pw.Text('Resumen general:',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              columnWidths: {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
              },
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
              children: [
                _buildRow('Total de compras', '$totalCompras'),
                _buildRow('Ingresos totales',
                    'S/ ${ingresosTotales.toStringAsFixed(2)}'),
                _buildRow(
                    'Descuentos', 'S/ ${descuentosTotales.toStringAsFixed(2)}'),
                _buildRow(
                    'Impuestos', 'S/ ${impuestosTotales.toStringAsFixed(2)}'),
                _buildRow('Subtotal promedio',
                    'S/ ${subtotalPromedio.toStringAsFixed(2)}'),
              ],
            ),
            pw.SizedBox(height: 20),

            // 🛒 Top productos
            pw.Text('Top productos vendidos:',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              columnWidths: {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1),
              },
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
              children: topProductos.entries
                  .map((e) => _buildRow(e.key, e.value.toString()))
                  .toList(),
            ),
            pw.SizedBox(height: 20),

            // 📦 Top categorías
            pw.Text('Top categorías:',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              columnWidths: {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1),
              },
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
              children: topCategorias.entries
                  .map((e) => _buildRow(e.key, e.value.toString()))
                  .toList(),
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Estadisticasgenerales.pdf');
    await file.writeAsBytes(await pdf.save());

    print('PDF guardado en: ${file.path}');
    return file;
  }

  // Helper para construir filas de tabla
  static pw.TableRow _buildRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(label,
                style: pw.TextStyle(fontWeight: pw.FontWeight.normal))),
        pw.Container(
            padding: const pw.EdgeInsets.all(8),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(value,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
      ],
    );
  }
}

class PDFGeneratorBoleta {
  static String _formatearMoneda(dynamic valor) {
    try {
      if (valor == null) return '0.00';

      if (valor is num) return valor.toDouble().toStringAsFixed(2);

      if (valor is String) {
        String v = valor.trim();

        // Detectar formato contable (10.00) → -10.00
        if (v.startsWith('(') && v.endsWith(')')) {
          v = '-${v.substring(1, v.length - 1)}';
        }

        // Eliminar cualquier símbolo extraño, excepto números, punto y signo -
        v = v.replaceAll(RegExp(r'[^\d.-]'), '');

        final parsed = double.tryParse(v);
        return parsed?.toStringAsFixed(2) ?? '0.00';
      }

      return '0.00';
    } catch (e) {
      print('Error al formatearMoneda: $valor → $e');
      return '0.00';
    }
  }

  static Future<File> generarBoletaCompra({
    required List<Map<String, dynamic>> productos,
    required Map<String, dynamic> data,
  }) async {
    final pdf = pw.Document();
    final fechaRaw = data['fecha'];
    final fecha = (fechaRaw is DateTime)
        ? fechaRaw
        : DateTime.tryParse(fechaRaw.toString()) ?? DateTime.now();
    final dateString = DateFormat('dd/MM/yyyy - hh:mm a').format(fecha);

    // Cargar imagen de perfil de la empresa
    pw.ImageProvider? perfilEmpresaImage;
    final perfilUrl = data['perfilEmpresa'];
    if (perfilUrl != null && perfilUrl.toString().isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(perfilUrl));
        if (response.statusCode == 200) {
          perfilEmpresaImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }

    // Preparar productos con imagen
    final productosConImagen =
        await Future.wait(productos.map((producto) async {
      pw.ImageProvider? imageProvider;
      final imagenUrl = producto['imagenCompraUrl'];

      try {
        if (imagenUrl != null && imagenUrl.toString().isNotEmpty) {
          final response = await http.get(Uri.parse(imagenUrl));
          if (response.statusCode == 200) {
            imageProvider = pw.MemoryImage(response.bodyBytes);
          }
        }
      } catch (_) {}

      return {
        ...producto,
        'imagen': imageProvider,
      };
    }));

    // Crear PDF
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabecera empresa
              if (perfilEmpresaImage != null || data['nombre'] != null) ...[
                pw.Row(
                  children: [
                    if (perfilEmpresaImage != null)
                      pw.Container(
                        width: 50,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          image: pw.DecorationImage(
                            image: perfilEmpresaImage,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          data['nombre'] ?? 'Nombre de la Empresa',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          data['ruc'] ?? 'Ruc de la empresa',
                          style: pw.TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        pw.Text(
                          'Boleta de compra',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                pw.SizedBox(height: 16),
              ],

              // Info cliente y fecha
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cliente: ${data['cliente'] ?? 'No identificado'}'),
                  pw.Text(
                    dateString,
                    style: pw.TextStyle(color: PdfColors.grey600),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(),

              // Detalle de productos
              ...productosConImagen.map((producto) {
                final nombre = producto['nombreProducto'] ?? 'Producto';
                final categoria = producto['categoria'] ?? '';
                final color = producto['color'];
                final marca = producto['marca'];
                final cantidad = producto['cantidad'];
                final precio = producto['precio'];
                final tallas = producto['tallas'] is Map<String, dynamic>
                    ? Map<String, dynamic>.from(producto['tallas'])
                    : null;
                final pw.ImageProvider? imageProvider = producto['imagen'];

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (imageProvider != null)
                        pw.Container(
                          width: 80,
                          height: 80,
                          child: pw.Image(imageProvider, fit: pw.BoxFit.cover),
                        )
                      else
                        pw.Container(
                          width: 80,
                          height: 80,
                          color: PdfColors.grey300,
                          child: pw.Center(
                            child: pw.Text('Sin\nimagen',
                                textAlign: pw.TextAlign.center),
                          ),
                        ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(nombre,
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold)),
                            if (categoria == 'Ropa' && color != null)
                              pw.Text('Color: $color'),
                            if ((categoria == 'Ropa' ||
                                    categoria == 'Calzado') &&
                                tallas != null)
                              pw.Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                children: tallas.entries.map((e) {
                                  return pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: pw.BoxDecoration(
                                      color: PdfColors.grey200,
                                      borderRadius: pw.BorderRadius.circular(4),
                                    ),
                                    child: pw.Text('Talla ${e.key}: ${e.value}',
                                        style: pw.TextStyle(fontSize: 10)),
                                  );
                                }).toList(),
                              ),
                            if ((categoria == 'Tecnologias' ||
                                    categoria == 'Juguetes') &&
                                marca != null)
                              pw.Text('Marca: $marca'),
                            if (!(categoria == 'Ropa' ||
                                categoria == 'Calzado'))
                              pw.Text('Cantidad: $cantidad'),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Precio: S/. ${precio?.toStringAsFixed(2) ?? '0.00'}',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 16),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(width: 1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Resumen de la Compra',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline,
                        )),
                    pw.SizedBox(height: 10),
                    pw.Text('Dirección de entrega:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(data['direccionEntrega'] ?? 'No especificada'),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Descuento:'),
                        pw.Text(
                          'S/. ${_formatearMoneda(data['descuento'])}',
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Impuesto - IGV:'),
                        pw.Text(
                          'S/. ${_formatearMoneda(data['impuesto'])}',
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total a pagar:',
                            style: pw.TextStyle(
                                fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          'S/. ${_formatearMoneda(data['total'])}',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Gracias por tu compra ',
                  style: pw.TextStyle(color: PdfColors.grey700),
                ),
              )
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/BoletaCompra.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
