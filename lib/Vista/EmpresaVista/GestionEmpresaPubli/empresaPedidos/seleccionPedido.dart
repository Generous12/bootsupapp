import 'package:bootsup/Vista/EmpresaVista/GestionEmpresaPubli/ChatEmpresa/chatsClientes.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/dropdownbutton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class EmpresaPedidosScreen extends StatefulWidget {
  final String usuarioId;
  final DateTime fecha;

  const EmpresaPedidosScreen({
    super.key,
    required this.usuarioId,
    required this.fecha,
  });

  @override
  State<EmpresaPedidosScreen> createState() => _EmpresaPedidosScreenState();
}

class _EmpresaPedidosScreenState extends State<EmpresaPedidosScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  Future<List<Map<String, dynamic>>> obtenerPedidosConCliente() async {
    if (currentUser == null) return [];

    try {
      final comprasSnapshot = await FirebaseFirestore.instance
          .collection('compras')
          .where('usuarioId', isEqualTo: widget.usuarioId)
          .get();
      final comprasEmpresa = comprasSnapshot.docs.where((doc) {
        final data = doc.data();
        final fechaPedido = (data['fecha'] as Timestamp?)?.toDate();
        return data['empresaId'] == currentUser!.uid &&
            fechaPedido?.isAtSameMomentAs(widget.fecha) == true;
      }).toList();
      List<Map<String, dynamic>> resultados = [];

      for (var compra in comprasEmpresa) {
        final clienteData = await obtenerCliente(compra['usuarioId']);
        resultados.add({
          'compra': compra,
          'cliente': clienteData,
        });
      }
      return resultados;
    } catch (e) {
      debugPrint('❌ Error al obtener compras: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> obtenerCliente(String usuarioId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(usuarioId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error obteniendo empresa: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 40,
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
          'Pedidos del Cliente',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: obtenerPedidosConCliente(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFAF00)),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No hay pedidos realizados por este usuario.'));
          }

          final pedidos = snapshot.data!;
          pedidos.sort((a, b) {
            final dataA = (a['compra'] as DocumentSnapshot).data()
                as Map<String, dynamic>?;
            final dataB = (b['compra'] as DocumentSnapshot).data()
                as Map<String, dynamic>?;

            final fechaA = (dataA?['fecha'] as Timestamp?)?.toDate();
            final fechaB = (dataB?['fecha'] as Timestamp?)?.toDate();

            if (fechaA == null && fechaB == null) return 0;
            if (fechaA == null) return 1;
            if (fechaB == null) return -1;

            return fechaA.compareTo(fechaB);
          });

          return ListView.builder(
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidos[index];
                final compraDoc = pedido['compra'] as DocumentSnapshot;
                final data = compraDoc.data() as Map<String, dynamic>;
                final cliente = pedido['cliente'] as Map<String, dynamic>?;
                final productos =
                    List<Map<String, dynamic>>.from(data['productos'] ?? []);
                final estadoActual =
                    (data['estado'] ?? 'Sin estado').toString();
                final fecha = (data['fecha'] as Timestamp?)?.toDate();
                final pedidoId = compraDoc.id;

                String? selectedEstado = estadoActual;
                final estados = [
                  //SI DESEAS ELIMINA EL NO ATENDIDO
                  'No atendido',
                  'Recibidos',
                  'Preparación',
                  'Enviado',
                ];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pedido ${data['codigo'] ?? ''}',
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
                              color: colorEstado(estadoActual),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              estadoActual.toUpperCase(),
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
                        fecha != null
                            ? DateFormat('dd/MM/yyyy – hh:mm a').format(fecha)
                            : 'Sin fecha',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomDropdownSelector(
                        labelText: 'Estado del pedido',
                        hintText: 'Seleccione',
                        value: selectedEstado,
                        items: estados,
                        onChanged: (value) async {
                          setState(() {
                            selectedEstado = value;
                          });

                          await FirebaseFirestore.instance
                              .collection('compras')
                              .doc(pedidoId)
                              .update({'estado': value});
                        },
                      ),
                      const SizedBox(height: 20),
                      ...productos.map((producto) {
                        final imagenUrl = producto['imagenCompraUrl'];
                        final nombre = producto['nombreProducto'] ?? 'Producto';
                        final categoria = producto['categoria'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (categoria == 'Ropa' &&
                                        producto['color'] != null)
                                      Text('Color: ${producto['color']}'),
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
                                              margin: const EdgeInsets.only(
                                                  right: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey.shade800
                                                    : const Color(0xFFEDEDED),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Talla ${e.key}: ${e.value}',
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    if ((categoria == 'Tecnologias' ||
                                            categoria == 'Juguetes') &&
                                        producto['marca'] != null)
                                      Text('Marca: ${producto['marca']}'),
                                    if (!(categoria == 'Ropa' ||
                                        categoria == 'Calzado'))
                                      Text('Cantidad: ${producto['cantidad']}'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Precio: S/. ${producto['precio']?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (cliente != null) ...[
                        Container(
                          padding: const EdgeInsets.only(
                              left: 12, top: 0, bottom: 0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Cliente del pedido',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: cliente['profileImageUrl'] !=
                                        null
                                    ? NetworkImage(cliente['profileImageUrl'])
                                    : null,
                                backgroundColor: const Color(0xFFEEEEEE),
                                child: cliente['profileImageUrl'] == null
                                    ? const Icon(Icons.person,
                                        color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cliente['username'] ?? 'Sin nombre',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Dni: ${cliente['dni'] ?? 'Sin RUC'}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 12,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          buildDetalleFila(context, 'Dirección de entrega',
                              data['direccionEntrega'] ?? 'No especificada'),
                          buildDetalleFila(context, 'Descuento',
                              'S/. ${(data['descuento'] ?? 0).toDouble().toStringAsFixed(2)}'),
                          buildDetalleFila(context, 'Impuesto',
                              'S/. ${(data['impuesto'] ?? 0).toDouble().toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total del pedido:',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            'S/. ${(data['total'] ?? 0).toDouble().toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              final empresaId = currentUser!.uid;
                              final clienteId = data['usuarioId'];

                              final fechaPedido = fecha ?? DateTime.now();
                              final estadoPedido =
                                  data['estado'] ?? 'Sin estado';
                              final totalPedido =
                                  (data['total'] ?? 0).toDouble();

                              navegarConSlideDerecha(
                                context,
                                ContactoEmpresaScreen(
                                  userIdVisitante: clienteId,
                                  empresaUserId: empresaId,
                                  fechaPedido: fechaPedido,
                                  estadoPedido: estadoPedido,
                                  totalPedido: totalPedido,
                                ),
                              );
                            },
                            icon: Icon(
                              Iconsax.message,
                              size: 18,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                            label: Text('Contactar cliente',
                                style: TextStyle(
                                  color: isDark ? Colors.black : Colors.white,
                                )),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  isDark ? Colors.amber : Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {},
                            icon: Icon(
                              Iconsax.document_download,
                              size: 18,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                            label: Text('Descargar PDF',
                                style: TextStyle(
                                  color: isDark ? Colors.black : Colors.white,
                                )),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  isDark ? Colors.amber : Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              });
        },
      ),
    );
  }
}
