import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetallePedidoRechazadoScreen extends StatefulWidget {
  final String usuarioId;
  final String compraId;

  const DetallePedidoRechazadoScreen({
    super.key,
    required this.usuarioId,
    required this.compraId,
  });

  @override
  State<DetallePedidoRechazadoScreen> createState() =>
      _DetallePedidoRechazadoScreenState();
}

class _DetallePedidoRechazadoScreenState
    extends State<DetallePedidoRechazadoScreen> {
  Future<List<Map<String, dynamic>>>
      obtenerPedidosRechazadosConComprobante() async {
    try {
      final comprasSnapshot = await FirebaseFirestore.instance
          .collection('compras')
          .where('usuarioId', isEqualTo: widget.usuarioId)
          .where('estado', isEqualTo: 'Rechazado')
          .get();

      List<Map<String, dynamic>> pedidosConComprobante = [];

      for (var compraDoc in comprasSnapshot.docs) {
        final compraId = compraDoc.id;
        final Map<String, dynamic> compraData = compraDoc.data();

        final comprobantesSnapshot =
            await compraDoc.reference.collection('comprobante').get();

        for (var comprobanteDoc in comprobantesSnapshot.docs) {
          final Map<String, dynamic> comprobanteData = comprobanteDoc.data();

          // Lista de productos procesada
          final List productosCrudos = compraData['productos'] ?? [];
          List<Map<String, dynamic>> productosProcesados = [];

          for (var producto in productosCrudos) {
            Map<String, dynamic> data = {
              'nombreProducto': producto['nombreProducto'],
              'imagenCompraUrl': producto['imagenCompraUrl'],
              'categoria': producto['categoria'],
              'precio': producto['precio'],
            };

            int cantidadTotal = producto['cantidad'] ?? 1;

            if (producto['categoria'] == 'Ropa' ||
                producto['categoria'] == 'Calzado') {
              data['color'] = producto['color'];
              data['tallas'] = producto['tallas'];
            } else if (producto['categoria'] == 'Tecnologias' ||
                producto['categoria'] == 'Juguetes') {
              data['marca'] = producto['marca'];
              data['cantidad'] = cantidadTotal;
            } else {
              data['cantidad'] = cantidadTotal;
            }

            productosProcesados.add(data);
          }

          pedidosConComprobante.add({
            'compraId': compraId,
            'estadoCompra': compraData['estado'],
            'fecha': compraData['fecha'],
            'direccionEntrega': compraData['direccionEntrega'],
            'total': compraData['total'],
            'nombre': comprobanteData['nombre'],
            'correo': comprobanteData['correo'],
            'estadoComprobante': comprobanteData['estado'],
            'observacion': comprobanteData['observacion'] ?? '',
            'motivo': comprobanteData['motivo'] ?? '',
            'productos': productosProcesados,
          });
        }
      }

      return pedidosConComprobante;
    } catch (e) {
      debugPrint('Error al obtener pedidos rechazados con comprobante: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: theme.iconTheme.color,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pedido rechazado',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[300],
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: obtenerPedidosRechazadosConComprobante(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay pedidos rechazados.'));
          }

          final pedidos = snapshot.data!;

          return ListView.separated(
            itemCount: pedidos.length,
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              final fecha = (pedido['fecha'] as Timestamp?)?.toDate();
              final total = (pedido['total'] ?? 0).toDouble();

              final theme = Theme.of(context);
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ENCABEZADO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detalles del pedido',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Rechazado',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// FECHA
                    Text(
                      fecha != null
                          ? DateFormat('dd/MM/yyyy – hh:mm a').format(fecha)
                          : 'Fecha no disponible',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    /// TOTAL
                    Text(
                      'Total del pedido:',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'S/. ${total.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 16),

                    ...(pedido['productos'] as List<dynamic>).map((producto) {
                      final imagenUrl = producto['imagenCompraUrl'];
                      final nombre = producto['nombreProducto'] ?? 'Producto';
                      final categoria = producto['categoria'] ?? '';
                      final precio = producto['precio'] ?? 0.0;
                      final color = producto['color'];
                      final tallas = producto['tallas'];
                      final marca = producto['marca'];
                      final cantidad = producto['cantidad'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// IMAGEN
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: imagenUrl != null &&
                                      imagenUrl.toString().isNotEmpty
                                  ? Image.network(
                                      imagenUrl,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/images/empresa.png',
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 12),

                            /// DATOS
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombre,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (categoria == 'Ropa' && color != null)
                                    Text('Color: $color'),
                                  if ((categoria == 'Ropa' ||
                                          categoria == 'Calzado') &&
                                      tallas != null)
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: (tallas as Map)
                                            .entries
                                            .map<Widget>((e) {
                                          return Container(
                                            margin: const EdgeInsets.only(
                                                right: 6, top: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.grey.shade800
                                                  : const Color(0xFFEDEDED),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                                'Talla ${e.key}: ${e.value}'),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  if ((categoria == 'Tecnologias' ||
                                          categoria == 'Juguetes') &&
                                      marca != null)
                                    Text('Marca: $marca'),
                                  if (cantidad != null &&
                                      categoria != 'Ropa' &&
                                      categoria != 'Calzado')
                                    Text('Cantidad: $cantidad'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Precio: S/. ${precio.toStringAsFixed(2)}',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    Divider(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      thickness: 1,
                      height: 15,
                    ),

                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// TÍTULO
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 20,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Datos del comprobante',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          /// NOMBRE
                          buildInfoLine(
                            context: context,
                            label: 'Nombre:',
                            value: pedido['nombre'] ?? 'No disponible',
                          ),

                          const SizedBox(height: 10),

                          /// CORREO
                          buildInfoLine(
                            context: context,
                            label: 'Correo:',
                            value: pedido['correo'] ?? 'No disponible',
                          ),

                          const SizedBox(height: 10),
                          buildInfoLine(
                            context: context,
                            label: 'Motivo del rechazo del pedido:',
                            value: pedido['motivo'] ?? 'No disponible',
                          ),
                          const SizedBox(height: 10),
                          if ((pedido['observacion'] ?? '')
                              .toString()
                              .isNotEmpty)
                            buildInfoLine(
                              context: context,
                              label: 'Observación:',
                              value: pedido['observacion'],
                            ),

                          const SizedBox(height: 20),

                          /// BOTÓN
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final confirmar = await showCustomDialog(
                                  context: context,
                                  title: '¿Aprobar comprobante?',
                                  message:
                                      '¿Estás seguro de que deseas aprobar este comprobante?',
                                  confirmButtonText: 'Sí',
                                  cancelButtonText: 'No',
                                  confirmButtonColor:
                                      const Color.fromARGB(255, 255, 0, 0),
                                  cancelButtonColor: const Color(0xFFFFAF00),
                                );

                                if (confirmar == true) {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('compras')
                                        .doc(widget.compraId)
                                        .update({'estado': 'Recibidos'});

                                    final comprobanteSnapshot =
                                        await FirebaseFirestore.instance
                                            .collection('compras')
                                            .doc(widget.compraId)
                                            .collection('comprobante')
                                            .where('usuarioId',
                                                isEqualTo: widget.usuarioId)
                                            .limit(1)
                                            .get();

                                    if (comprobanteSnapshot.docs.isNotEmpty) {
                                      final comprobanteId =
                                          comprobanteSnapshot.docs.first.id;

                                      await FirebaseFirestore.instance
                                          .collection('compras')
                                          .doc(widget.compraId)
                                          .collection('comprobante')
                                          .doc(comprobanteId)
                                          .update({
                                        'estado': 'Aprobado',
                                        'motivo': 'Resuelto'
                                      });
                                    }

                                    if (mounted) Navigator.pop(context);
                                  } catch (e) {
                                    debugPrint('Error al aprobar compra: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Error al aprobar la compra')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 18),
                              label: const Text(
                                'Aprobar comprobante',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Afacad',
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(
                                        0xFF2D2D2D) // gris oscuro elegante para modo oscuro
                                    : Colors.black,
                                elevation: 5.0,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
