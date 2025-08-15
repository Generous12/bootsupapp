import 'package:bootsup/Vista/EmpresaVista/GestionEmpresaPubli/empresaPedidos/ObservacionesCompro.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/FullScreenWidget.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';

class VerificarCompraScreen extends StatefulWidget {
  final String usuarioId;
  final String compraId;

  const VerificarCompraScreen({
    super.key,
    required this.usuarioId,
    required this.compraId,
  });

  @override
  State<VerificarCompraScreen> createState() => _VerificarCompraScreenState();
}

class _VerificarCompraScreenState extends State<VerificarCompraScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? comprobanteData;

  @override
  void initState() {
    super.initState();
    _fetchComprobante();
  }

  Future<void> _fetchComprobante() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('compras')
          .doc(widget.compraId)
          .collection('comprobante')
          .where('usuarioId', isEqualTo: widget.usuarioId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          comprobanteData = snapshot.docs.first.data();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error al obtener comprobante: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

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
            tooltip: 'Volver',
          ),
          title: Text(
            'Verificar comprobante',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 20,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TipsScreen()),
                  );
                },
                child: Icon(
                  Iconsax.info_circle,
                  size: 24,
                  color: theme.iconTheme.color,
                ),
              ),
            ),
          ],
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : comprobanteData == null
                ? Center(
                    child: Text(
                      'No se encontró comprobante para verificar.',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        infoRow(context, 'Nombres y apellidos:',
                            comprobanteData!['nombre']),
                        const SizedBox(height: 8),
                        infoRow(context, 'Correo electronico:',
                            comprobanteData!['correo']),
                        const SizedBox(height: 8),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 1,
                          color:
                              isDark ? const Color(0xFF1F1F1F) : Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Row(
                                  children: [
                                    const Icon(Iconsax.image, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Comprobante',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImagePage(
                                        imageUrl:
                                            comprobanteData!['comprobanteUrl'],
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    comprobanteData!['comprobanteUrl'],
                                    height: 300,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 300,
                                        color: Colors.grey[200],
                                        child: const Center(
                                            child: CircularProgressIndicator()),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 300,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child:
                                            Text("No se pudo cargar la imagen"),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
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
                                      // Actualiza estado de la compra como 'recibido'
                                      await FirebaseFirestore.instance
                                          .collection('compras')
                                          .doc(widget.compraId)
                                          .update({'estado': 'Recibidos'});

                                      // Obtiene el comprobante más reciente
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
                                            .update({'estado': 'aprobado'});
                                      }

                                      if (mounted) Navigator.pop(context);
                                    } catch (e) {
                                      debugPrint('Error al aprobar compra: $e');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Error al aprobar la compra')),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? const Color(0xFF2D2D2D)
                                      : Colors.black,
                                  elevation: 5.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                ),
                                child: const Text(
                                  'Aprobar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Afacad',
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final confirmar = await showCustomDialog(
                                    context: context,
                                    title: '¿Rechazar comprobante?',
                                    message:
                                        '¿Estás seguro de que deseas rechazar este comprobante y agregar observaciones?',
                                    confirmButtonText: 'Sí',
                                    cancelButtonText: 'No',
                                    confirmButtonColor:
                                        const Color.fromARGB(255, 255, 0, 0),
                                    cancelButtonColor: Colors.black,
                                  );

                                  if (confirmar == true) {
                                    try {
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
                                            .update({'estado': 'Rechazado'});
                                      }
                                      navegarConSlideDerecha(
                                        context,
                                        AplicarObservacionesScreen(
                                          compraId: widget.compraId,
                                          usuarioId: widget.usuarioId,
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint(
                                          'Error al rechazar compra: $e');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Error al rechazar la compra')),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFAF00),
                                  elevation: 5.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                ),
                                child: const Text(
                                  'Rechazar',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Afacad',
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ));
  }
}
