import 'package:bootsup/Modulos/ModuloStats/EstadisticaService.dart';
import 'package:bootsup/Vista/EmpresaVista/Estadistica/VerPdf.dart';
import 'package:bootsup/widgets/FullScreenWidget.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class DetalleCompraScreenVinos extends StatefulWidget {
  final String compraId;
  final DateTime fecha;

  const DetalleCompraScreenVinos({
    Key? key,
    required this.compraId,
    required this.fecha,
  }) : super(key: key);

  @override
  State<DetalleCompraScreenVinos> createState() => _DetalleCompraScreenState();
}

class _DetalleCompraScreenState extends State<DetalleCompraScreenVinos> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  late final Future<Map<String, dynamic>> _datosCompraConEmpresa;
  @override
  void initState() {
    super.initState();

    _datosCompraConEmpresa = _obtenerDatosCompraYEmpresa();
  }

  Future<Map<String, dynamic>> _obtenerDatosCompraYEmpresa() async {
    final compraSnap = await FirebaseFirestore.instance
        .collection('compras')
        .doc(widget.compraId)
        .get();

    if (!compraSnap.exists) {
      throw Exception('Compra no encontrada');
    }
    final compraData = compraSnap.data()!;
    return {
      'compra': compraData,
    };
  }

  double _parseToDouble(dynamic value) {
    try {
      if (value == null) return 0.0;

      if (value is num) return value.toDouble();

      if (value is String) {
        String cleaned = value.trim();
        if (cleaned.startsWith('(') && cleaned.endsWith(')')) {
          cleaned = '-${cleaned.substring(1, cleaned.length - 1)}';
        }
        cleaned = cleaned.replaceAll(RegExp(r'[^\d.-]'), '');
        return double.parse(cleaned);
      }

      return 0.0;
    } catch (e) {
      print('⚠️ Error parsing "$value": $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(children: [
      Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 48,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(
              Iconsax.arrow_left,
              color: theme.iconTheme.color,
              size: 25,
            ),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
          ),
          title: Text(
            'Detalle de la compra',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 20,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _datosCompraConEmpresa,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Color(0xFFA30000),
                  size: 50,
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Error cargando datos.'));
            }

            final compraData = snapshot.data!['compra'] as Map<String, dynamic>;

            final productos =
                List<Map<String, dynamic>>.from(compraData['productos'] ?? []);
            final estado = (compraData['estado'] ?? 'Sin estado').toString();
            final fecha = (compraData['fecha'] as Timestamp).toDate();
            final data = {
              'direccionEntrega': compraData['direccionEntrega'] ?? '',
              'total': _parseToDouble(compraData['total']),
              'descuento': _parseToDouble(compraData['descuento']),
              'impuesto': _parseToDouble(compraData['impuesto']),
              'cliente': currentUser?.displayName ?? 'Cliente',
              'fecha': (compraData['fecha'] as Timestamp).toDate(),
            };

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
              children: [
                SeguimientoEnvio(estado: estado),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Compra ',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorEstado(estado),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        estado.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat('dd/MM/yyyy – hh:mm a').format(fecha),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ...productos.map((producto) {
                  final imagenUrl = producto['imagenCompraUrl'];
                  final nombre = producto['nombreProducto'] ?? 'Producto';
                  final categoria = producto['categoria'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imagenUrl != null &&
                                  imagenUrl.toString().isNotEmpty
                              ? Image.network(
                                  imagenUrl,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/empresa.png',
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (categoria == 'Ropa' &&
                                  producto['color'] != null)
                                Text(
                                  'Color: ${producto['color']}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                              if ((categoria == 'Ropa' ||
                                      categoria == 'Calzado') &&
                                  producto['tallas'] is Map)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: producto['tallas']
                                        .entries
                                        .map<Widget>((e) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey.shade800
                                              : const Color(0xFFEDEDED),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Talla ${e.key}: ${e.value}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              if ((categoria == 'Tecnologias' ||
                                      categoria == 'Juguetes') &&
                                  producto['marca'] != null)
                                Text(
                                  'Marca: ${producto['marca']}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                              if (!(categoria == 'Ropa' ||
                                  categoria == 'Calzado'))
                                Text(
                                  'Cantidad: ${producto['cantidad']}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Precio: S/. ${producto['precio']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Column(
                  children: [
                    buildDetalleFila(
                      context,
                      'Dirección de entrega',
                      compraData['direccionEntrega'] ?? 'No especificada',
                    ),
                    buildDetalleFila(
                      context,
                      'Descuento',
                      'S/. ${_formatearMoneda(compraData['descuento'])}',
                    ),
                    buildDetalleFila(
                      context,
                      'Impuesto',
                      'S/. ${_formatearMoneda(compraData['impuesto'])}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total de la compra:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      'S/. ${(compraData['total'] ?? 0).toDouble().toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: SizedBox(
                    width: double.infinity, // ocupa todo el ancho disponible
                    child: TextButton.icon(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          final pdfFile =
                              await PDFGeneratorBoleta.generarBoletaCompra(
                            productos: productos,
                            data: data,
                          );

                          if (await pdfFile.exists()) {
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    VerBoletaScreen(filePath: pdfFile.path),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Error al generar el PDF')),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error generando PDF: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Error generando el PDF')),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                      icon: Icon(
                        Iconsax.document_download,
                        size: 20,
                        color: isDark
                            ? const Color.fromARGB(255, 255, 255, 255)
                            : Colors.white,
                      ),
                      label: Text(
                        'Descargar PDF',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? const Color.fromARGB(255, 255, 255, 255)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            isDark ? const Color(0xFFA30000) : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
      if (_isLoading)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Color(0xFFA30000),
                size: 50,
              ),
            ),
          ),
        ),
    ]);
  }
}

String _formatearMoneda(dynamic valor) {
  try {
    if (valor == null) return '0.00';

    if (valor is num) return valor.toStringAsFixed(2);

    if (valor is String) {
      if (valor.contains('(') && valor.contains(')')) {
        valor = valor.replaceAll('(', '-').replaceAll(')', '');
      }
      final limpio = valor.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.parse(limpio).toStringAsFixed(2);
    }
  } catch (e) {
    print('Error al formatear moneda: $e');
  }

  return '0.00';
}
