import 'package:bootsup/Vista/EmpresaVista/GestionEmpresaPubli/empresaPedidos/compradores.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/BotonesSeleccionables.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/SnackBar.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AplicarObservacionesScreen extends StatefulWidget {
  final String compraId;
  final String usuarioId;

  const AplicarObservacionesScreen({
    super.key,
    required this.compraId,
    required this.usuarioId,
  });

  @override
  State<AplicarObservacionesScreen> createState() =>
      _AplicarObservacionesScreenState();
}

class _AplicarObservacionesScreenState
    extends State<AplicarObservacionesScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;
  String? _motivoSeleccionado;
  Future<void> _guardarObservacion() async {
    final texto = _controller.text.trim();
    final motivo = _motivoSeleccionado;

    if (texto.isEmpty || motivo == null || motivo.isEmpty) {
      showCustomDialog(
        context: context,
        title: 'Campo vacío',
        message: 'Completa los campos vacíos',
        confirmButtonText: 'Cerrar',
      );
      return;
    }
    final confirmar = await showCustomDialog(
      context: context,
      title: '¿Deseas aplicar los camios?',
      message: '¿Estás seguro de que deseas continuar?',
      confirmButtonText: 'Sí',
      cancelButtonText: 'No',
      confirmButtonColor: const Color.fromARGB(255, 255, 0, 0),
      cancelButtonColor: const Color(0xFFFFAF00),
    );

    if (confirmar == true) {
      setState(() => _isSaving = true);

      try {
        // 🟡 Actualiza estado de la compra como 'Rechazado'
        await FirebaseFirestore.instance
            .collection('compras')
            .doc(widget.compraId)
            .update({'estado': 'Rechazado'});

        // 🔵 Busca el comprobante correspondiente
        final comprobanteSnapshot = await FirebaseFirestore.instance
            .collection('compras')
            .doc(widget.compraId)
            .collection('comprobante')
            .where('usuarioId', isEqualTo: widget.usuarioId)
            .limit(1)
            .get();

        if (comprobanteSnapshot.docs.isNotEmpty) {
          final comprobanteId = comprobanteSnapshot.docs.first.id;

          // 🟢 Actualiza la observación dentro del comprobante
          await FirebaseFirestore.instance
              .collection('compras')
              .doc(widget.compraId)
              .collection('comprobante')
              .doc(comprobanteId)
              .update({
            'observacion': texto,
            'motivo': motivo,
          });
        }

        if (mounted) {
          SnackBarUtil.mostrarSnackBarPersonalizado(
            context: context,
            mensaje: 'Observaciones aplicada con exito',
            icono: Icons.check_circle,
            colorFondo: const Color.fromARGB(255, 0, 0, 0),
          );
          navegarConSlideDerecha(context, ComprasUsuarioPage());
        }
      } catch (e) {
        debugPrint('Error al guardar observación: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar observación.')),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
        onWillPop: () async {
          if (_isSaving) {
            return false;
          }

          final confirmar = await showCustomDialog(
            context: context,
            title: '¿Anular rechazo?',
            message:
                '¿Deseas volver atrás y dejar el comprobante como pendiente? Esta acción anulará el rechazo.',
            confirmButtonText: 'Sí',
            cancelButtonText: 'No',
            confirmButtonColor: const Color.fromARGB(255, 255, 0, 0),
            cancelButtonColor: const Color.fromARGB(255, 0, 0, 0),
          );

          if (confirmar == true) {
            try {
              final comprobanteSnapshot = await FirebaseFirestore.instance
                  .collection('compras')
                  .doc(widget.compraId)
                  .collection('comprobante')
                  .where('usuarioId', isEqualTo: widget.usuarioId)
                  .limit(1)
                  .get();

              if (comprobanteSnapshot.docs.isNotEmpty) {
                final comprobanteId = comprobanteSnapshot.docs.first.id;

                await FirebaseFirestore.instance
                    .collection('compras')
                    .doc(widget.compraId)
                    .collection('comprobante')
                    .doc(comprobanteId)
                    .update({'estado': 'pendiente'});
              }
              await FirebaseFirestore.instance
                  .collection('compras')
                  .doc(widget.compraId)
                  .update({'estado': 'No atendido'});

              Navigator.pop(context);
            } catch (e) {
              debugPrint('Error al revertir estado: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error al revertir el rechazo')),
              );
            }
          }

          return false;
        },
        child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            behavior: HitTestBehavior.translucent,
            child: Scaffold(
              appBar: AppBar(
                centerTitle: true,
                titleSpacing: 0,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                toolbarHeight: 48,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: theme.iconTheme.color,
                    size: 20,
                  ),
                  onPressed: () async {
                    final confirmar = await showCustomDialog(
                      context: context,
                      title: '¿Anular rechazo?',
                      message:
                          '¿Deseas volver atrás y dejar el comprobante como pendiente? Esta acción anulará el rechazo.',
                      confirmButtonText: 'Sí',
                      cancelButtonText: 'No',
                      confirmButtonColor: const Color.fromARGB(255, 255, 0, 0),
                      cancelButtonColor: const Color.fromARGB(255, 0, 0, 0),
                    );

                    if (confirmar == true) {
                      try {
                        final comprobanteSnapshot = await FirebaseFirestore
                            .instance
                            .collection('compras')
                            .doc(widget.compraId)
                            .collection('comprobante')
                            .where('usuarioId', isEqualTo: widget.usuarioId)
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
                              .update({'estado': 'pendiente'});
                        }

                        // Revertir estado de la compra a "No atendido"
                        await FirebaseFirestore.instance
                            .collection('compras')
                            .doc(widget.compraId)
                            .update({'estado': 'No atendido'});

                        Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Error al revertir estado: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Error al revertir el rechazo')),
                        );
                      }
                    }
                  },
                ),
                title: Text(
                  'Observaciones',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                  ),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Observaciones del comprobante',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Agrega cualquier detalle adicional relevante sobre el comprobante. Por ejemplo, si el nombre del receptor no coincide, si hay algún error en el monto, o si deseas dejar un mensaje adicional.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 15.5,
                            height: 1.45,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.9),
                          ),
                    ),
                    const SizedBox(height: 18),
                    MotivosObservacionRow(
                      onMotivoSeleccionado: (motivo) {
                        setState(() {
                          _motivoSeleccionado = motivo;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _controller,
                      maxLines: 6,
                      style: const TextStyle(fontFamily: 'Afacad'),
                      decoration: InputDecoration(
                        hintText: 'Escribe aquí tus observaciones...',
                        hintStyle: TextStyle(
                          color: theme.hintColor,
                          fontFamily: 'Afacad',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: LoadingOverlayButton(
                        text: 'Guardar',
                        onPressedLogic: () async {
                          _guardarObservacion();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )));
  }
}
