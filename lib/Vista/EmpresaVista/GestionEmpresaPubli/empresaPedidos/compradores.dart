import 'dart:async';
import 'package:bootsup/Vista/EmpresaVista/GestionEmpresaPubli/empresaPedidos/seleccionPedido.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/BotonesSeleccionables.dart';
import 'package:bootsup/widgets/Redacted/RedactUsados.dart';
import 'package:bootsup/widgets/SnackBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

class ComprasUsuarioPage extends StatefulWidget {
  const ComprasUsuarioPage({Key? key}) : super(key: key);

  @override
  State<ComprasUsuarioPage> createState() => _ComprasUsuarioPageState();
}

class _ComprasUsuarioPageState extends State<ComprasUsuarioPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _compras = [];
  List<Map<String, dynamic>> _comprasFiltradas = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? filtroSeleccionado;
  String estadoSeleccionado = 'No atendidos';
  late final StreamSubscription _comprasSubscription;
  Map<String, String> _estadosAnteriores = {};

  @override
  void initState() {
    super.initState();
    _fetchComprasDelUsuario();
    _escucharComprasEnTiempoReal();
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'enviado':
        return const Color.fromARGB(255, 0, 0, 0);
      case 'preparación':
        return const Color.fromARGB(255, 0, 0, 0);
      case 'recibidos':
        return const Color.fromARGB(255, 0, 0, 0);
      case 'no atendido':
      default:
        return const Color.fromARGB(255, 0, 0, 0);
    }
  }

  void _escucharComprasEnTiempoReal() {
    _isLoading = true;
    _comprasSubscription = FirebaseFirestore.instance
        .collection('compras')
        .where('empresaId', isEqualTo: _user?.uid)
        .snapshots()
        .listen((snapshot) async {
      List<Map<String, dynamic>> comprasList = [];

      for (var doc in snapshot.docs) {
        final compraData = doc.data();
        final usuarioId = compraData['usuarioId'];
        final compraId = doc.id;
        final nuevoEstado = (compraData['estado'] ?? 'Sin estado').toString();

        // Verificar cambio de estado
        if (_estadosAnteriores.containsKey(compraId) &&
            _estadosAnteriores[compraId] != nuevoEstado) {
          final username = await _obtenerNombreUsuario(usuarioId);
          final colorEstado = _colorEstado(nuevoEstado);

          if (mounted) {
            SnackBarUtil.mostrarSnackBarPersonalizado(
              context: context,
              mensaje: 'El pedido de $username cambió a "$nuevoEstado"',
              icono: Icons.info_outline,
              colorFondo: colorEstado,
            );
          }
        }

        // Guardar estado actual
        _estadosAnteriores[compraId] = nuevoEstado;

        if (usuarioId != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(usuarioId)
              .get();

          final userData = userDoc.data() ?? {};

          comprasList.add({
            'username': userData['username'] ?? 'Sin nombre',
            'profileImageUrl': userData['profileImageUrl'] ?? '',
            'estado': nuevoEstado,
            'fecha': compraData['fecha'] as Timestamp?,
            'usuarioId': usuarioId,
            'compraId': compraId,
          });
        }
      }
      comprasList.sort((a, b) {
        final fechaA = (a['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final fechaB = (b['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return fechaA.compareTo(fechaB);
      });

      if (!mounted) return;
      setState(() {
        _compras = comprasList;
        _filtrarCompras();
        _isLoading = false;
      });
    });
  }

  Future<String> _obtenerNombreUsuario(String usuarioId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(usuarioId)
        .get();

    return (userDoc.data()?['username'] ?? 'Usuario') as String;
  }

  Future<void> _fetchComprasDelUsuario() async {
    try {
      final comprasSnapshot = await FirebaseFirestore.instance
          .collection('compras')
          .where('empresaId', isEqualTo: _user?.uid)
          .get();

      List<Map<String, dynamic>> comprasList = [];

      for (var doc in comprasSnapshot.docs) {
        final compraData = doc.data();
        final usuarioId = compraData['usuarioId'];

        if (usuarioId != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(usuarioId)
              .get();

          final userData = userDoc.data() ?? {};

          comprasList.add({
            'username': userData['username'] ?? 'Sin nombre',
            'profileImageUrl': userData['profileImageUrl'] ?? '',
            'estado': compraData['estado'] ?? 'Sin estado',
            'fecha': compraData['fecha'] as Timestamp?,
            'usuarioId': usuarioId,
            'compraId': doc.id,
          });
        }
      }
      comprasList.sort((a, b) {
        final fechaA = (a['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final fechaB = (b['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return fechaA.compareTo(fechaB);
      });

      if (mounted) {
        setState(() {
          _compras = comprasList;
          _filtrarCompras();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al obtener compras: $e');
    }
  }

  void _filtrarCompras() {
    final textoBusqueda = _searchController.text.toLowerCase();

    setState(() {
      _comprasFiltradas = _compras.where((compra) {
        final username = (compra['username'] as String?)?.toLowerCase() ?? '';
        final coincideTexto = username.contains(textoBusqueda);

        final coincideEstado = estadoSeleccionado == 'Todos' ||
            compra['estado'] == estadoSeleccionado;

        return coincideTexto && coincideEstado;
      }).toList();
    });
  }

  @override
  void dispose() {
    _comprasSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 55,
            automaticallyImplyLeading: false,
            titleSpacing: 12,
            title: Theme(
              data: ThemeData(
                textSelectionTheme: const TextSelectionThemeData(
                  selectionColor: Color(0xFFFFC800),
                  cursorColor: Colors.black,
                  selectionHandleColor: Colors.black,
                ),
              ),
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color.fromARGB(255, 0, 0, 0),
                        child: Icon(
                          Iconsax.arrow_left,
                          size: 20,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: false,
                        onChanged: (query) {
                          _filtrarCompras();
                        },
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontFamily: 'Afacad',
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Buscar chat...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 17.0,
                            fontFamily: 'Afacad',
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchController.clear();
                            _filtrarCompras();
                          });
                        },
                        child: Icon(
                          Iconsax.close_circle,
                          size: 25,
                          color: theme.iconTheme.color,
                        ),
                      )
                    else
                      Icon(
                        Iconsax.search_normal,
                        size: 25,
                        color: theme.iconTheme.color,
                      ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              PedidoFiltroSelector(
                onFiltroSelected: (estado) {
                  estadoSeleccionado = estado;
                  _filtrarCompras();
                },
              ),
              Expanded(
                child: _isLoading
                    ? const RedactedChat()
                    : _comprasFiltradas.isEmpty
                        ? Center(
                            child: Text(
                              'No hay pedidos en este apartado',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(5),
                              itemCount: _comprasFiltradas.length,
                              itemBuilder: (context, index) {
                                final compra = _comprasFiltradas[index];
                                final fecha =
                                    (compra['fecha'] as Timestamp?)?.toDate();
                                final fechaFormateada = fecha != null
                                    ? timeago.format(fecha, locale: 'es')
                                    : 'Sin fecha';

                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 25,
                                      backgroundImage: (compra[
                                                      'profileImageUrl'] !=
                                                  null &&
                                              compra['profileImageUrl']
                                                  .isNotEmpty)
                                          ? NetworkImage(
                                              compra['profileImageUrl'])
                                          : const AssetImage(
                                                  'assets/images/empresa.png')
                                              as ImageProvider,
                                    ),
                                    title: Text(
                                      compra['username'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: Text('Fecha: $fechaFormateada'),
                                    trailing: TextButton(
                                      onPressed: () {
                                        /* if (estadoSeleccionado ==
                                            'No atendido') {
                                          final compraId = compra['compraId'];
                                          final usuarioId = compra['usuarioId'];
                                          if (usuarioId != null &&
                                              compraId != null) {
                                            navegarConSlideDerecha(
                                              context,
                                              VerificarCompraScreen(
                                                usuarioId: usuarioId,
                                                compraId: compraId,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'No se pudo cargar la verificación: faltan datos.')),
                                            );
                                          }
                                        } else if (estadoSeleccionado ==
                                            'Rechazado') {
                                          final compraId = compra['compraId'];
                                          final usuarioId = compra['usuarioId'];
                                          if (usuarioId != null &&
                                              compraId != null) {
                                            navegarConSlideDerecha(
                                              context,
                                              DetallePedidoRechazadoScreen(
                                                usuarioId: usuarioId,
                                                compraId: compraId,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'No se pudo cargar la verificación: faltan datos.')),
                                            );
                                          }
                                        } else {
                                      /*   navegarConSlideDerecha(
                                            context,
                                            EmpresaPedidosScreen(
                                              usuarioId: compra['usuarioId'],
                                              fecha:
                                                  (compra['fecha'] as Timestamp)
                                                      .toDate(),
                                            ),
                                          ); */
                                        }*/
                                        navegarConSlideDerecha(
                                          context,
                                          EmpresaPedidosScreen(
                                            usuarioId: compra['usuarioId'],
                                            fecha:
                                                (compra['fecha'] as Timestamp)
                                                    .toDate(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: isDark
                                            ? const Color(0xFF2D2D2D)
                                            : Colors.black,
                                        elevation: 5.0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                      ),
                                      child: Text(
                                        /* estadoSeleccionado == 'Rechazado'
                                            ? 'Ver'
                                            : estadoSeleccionado ==
                                                    'No atendido'
                                                ? 'Verificar'
                                                : */
                                        'Atender',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Afacad',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )),
              ),
            ],
          ),
        ));
  }
}
