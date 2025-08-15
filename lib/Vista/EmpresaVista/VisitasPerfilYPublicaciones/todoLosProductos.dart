import 'package:bootsup/Vista/EmpresaVista/VisitasPerfilYPublicaciones/todosProducos/filtro.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/Badges.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/carritoService.dart';
import 'package:bootsup/Vistas/detalleproducto/detalleProducto.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/BotonesSeleccionables.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class TodosLosProductosPage extends StatefulWidget {
  final String empresaUserId;
  final List<DocumentSnapshot>? productosPasados;
  final bool desdePerfildelaEmpresa;
  final bool desdePublicaciones;
  const TodosLosProductosPage({
    Key? key,
    required this.empresaUserId,
    this.desdePublicaciones = false,
    this.desdePerfildelaEmpresa = false,
    this.productosPasados,
  }) : super(key: key);

  @override
  State<TodosLosProductosPage> createState() => _TodosLosProductosPageState();
}

class _TodosLosProductosPageState extends State<TodosLosProductosPage> {
  String _categoriaSeleccionada = 'General';
  late Future<DocumentSnapshot> _empresaFuture;
  List<DocumentSnapshot> _productos = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  ScrollController _scrollController = ScrollController();
  int _itemsToShow = 4;
  bool _isLoadingMore = false;

  void _filtrarProductos({String? criterio}) async {
    Query query = FirebaseFirestore.instance
        .collection('productos')
        .where('userid', isEqualTo: widget.empresaUserId);

    if (_categoriaSeleccionada != 'General') {
      query = query.where('categoria', isEqualTo: _categoriaSeleccionada);
    }

    if (criterio == 'recientes') {
      query = query.orderBy('fecha', descending: true);
    }

    if (criterio == 'precioMenor') {
      query = query.orderBy('precio');
    } else if (criterio == 'precioMayor') {
      query = query.orderBy('precio', descending: true);
    }

    final snapshot = await query.get();

    if (criterio == 'rating') {
      final productosConRating = await Future.wait(
        snapshot.docs.map((doc) async {
          final comentariosSnap =
              await doc.reference.collection('comentarios').get();
          final comentarios = comentariosSnap.docs;

          double promedio = 0;
          if (comentarios.isNotEmpty) {
            final total = comentarios
                .map((c) => (c['rating'] ?? 0).toDouble())
                .reduce((a, b) => a + b);
            promedio = total / comentarios.length;
          }

          return {
            'doc': doc,
            'promedioRating': promedio,
          };
        }),
      );
      productosConRating.sort((a, b) => (b['promedioRating'] as double)
          .compareTo(a['promedioRating'] as double));

      setState(() {
        _productos = productosConRating
            .map((e) => e['doc'] as DocumentSnapshot)
            .toList();
      });
    } else if (criterio == 'comentarios') {
      final productosConComentarios = await Future.wait(
        snapshot.docs.map((doc) async {
          final comentarios =
              await doc.reference.collection('comentarios').get();
          return {
            'doc': doc,
            'comentarios': comentarios.size,
          };
        }),
      );

      productosConComentarios.sort((a, b) =>
          (b['comentarios'] as int).compareTo(a['comentarios'] as int));

      setState(() {
        _productos = productosConComentarios
            .map((e) => e['doc'] as DocumentSnapshot)
            .toList();
      });
    } else if (criterio != 'rating') {
      setState(() {
        _productos = snapshot.docs;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _itemsToShow < _productos.length) {
        setState(() {
          _isLoadingMore = true;
        });
        Future.delayed(Duration(milliseconds: 500), () {
          setState(() {
            _itemsToShow += 4;
            if (_itemsToShow > _productos.length) {
              _itemsToShow = _productos.length;
            }
            _isLoadingMore = false;
          });
        });
      }
    });
    if (widget.productosPasados != null) {
      _productos = widget.productosPasados!
          .where((producto) =>
              producto['userid'] == widget.empresaUserId &&
              (_categoriaSeleccionada == 'General' ||
                  (producto['categoria'] ?? '') == _categoriaSeleccionada))
          .toList();
      _itemsToShow = (_productos.length < 4) ? _productos.length : 4;
      _isLoadingMore = false;
    } else {
      _filtrarProductos();
    }

    _empresaFuture = FirebaseFirestore.instance
        .collection('empresa')
        .doc(widget.empresaUserId)
        .get();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (widget.desdePerfildelaEmpresa) {
            return true;
          }

          final carritoService =
              Provider.of<CarritoService>(context, listen: false);

          if (carritoService.obtenerCarrito().isEmpty) {
            return true;
          }

          final bool? confirmed = await showCustomDialog(
            context: context,
            title: 'Eliminar carrito',
            message:
                '¿Estás seguro? Si sales ahora, se eliminará tu carrito de compras.',
            confirmButtonText: 'Sí, salir',
            cancelButtonText: 'No',
            confirmButtonColor: Colors.red,
            cancelButtonColor: const Color.fromARGB(255, 0, 0, 0),
          );

          if (confirmed == true) {
            carritoService.limpiarCarrito();
            return true;
          } else {
            return false;
          }
        },
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _isSearching = false;
          },
          behavior: HitTestBehavior.translucent,
          child: Scaffold(
            body: FutureBuilder<DocumentSnapshot>(
              future: _empresaFuture,
              builder: (context, empresaSnapshot) {
                if (empresaSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: Color(0xFFFFAF00),
                      size: 40,
                    ),
                  );
                }

                if (!empresaSnapshot.hasData || !empresaSnapshot.data!.exists) {
                  return const Center(child: Text('Empresa no encontrada.'));
                }

                final empresa =
                    empresaSnapshot.data!.data() as Map<String, dynamic>;
                final nombreEmpresa = empresa['nombre'] ?? 'Empresa';
                final fotoEmpresa = empresa['perfilEmpresa'] ?? '';
                final estado = empresa['estado'] ?? '';

                return SafeArea(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (widget.desdePerfildelaEmpresa) {
                                  Navigator.pop(context);
                                  return;
                                }

                                final carritoService =
                                    Provider.of<CarritoService>(context,
                                        listen: false);

                                if (carritoService.obtenerCarrito().isEmpty) {
                                  Navigator.pop(context);
                                  return;
                                }

                                final bool? confirmed = await showCustomDialog(
                                  context: context,
                                  title: 'Eliminar carrito',
                                  message:
                                      '¿Estás seguro? Si sales ahora, se eliminará tu carrito de compras.',
                                  confirmButtonText: 'Sí, salir',
                                  cancelButtonText: 'No',
                                  confirmButtonColor: Colors.red,
                                  cancelButtonColor:
                                      const Color.fromARGB(255, 0, 0, 0),
                                );

                                if (confirmed == true) {
                                  carritoService.limpiarCarrito();
                                  Navigator.pop(context);
                                }
                              },
                              child: Icon(Iconsax.arrow_left, size: 25),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: _isSearching
                                  ? Theme(
                                      data: ThemeData(
                                        textSelectionTheme:
                                            const TextSelectionThemeData(
                                          selectionColor: Color(0xFFFFC800),
                                          cursorColor: Colors.black,
                                          selectionHandleColor: Colors.black,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        autofocus: true,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontFamily: 'Afacad',
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Buscar productos...',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 10),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _productos = widget
                                                .productosPasados!
                                                .where((producto) {
                                              final nombre =
                                                  (producto['nombreProducto'] ??
                                                          '')
                                                      .toString()
                                                      .toLowerCase();
                                              final coincideBusqueda =
                                                  nombre.contains(
                                                      value.toLowerCase());

                                              final coincideCategoria =
                                                  _categoriaSeleccionada ==
                                                          'General' ||
                                                      (producto['categoria'] ??
                                                              '') ==
                                                          _categoriaSeleccionada;

                                              final esDeEmpresa =
                                                  producto['userid'] ==
                                                      widget.empresaUserId;

                                              return coincideBusqueda &&
                                                  coincideCategoria &&
                                                  esDeEmpresa;
                                            }).toList();
                                          });
                                        },
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(35),
                                          child: fotoEmpresa.isNotEmpty
                                              ? Image.network(
                                                  fotoEmpresa,
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Image.asset(
                                                    'assets/images/empresa.png',
                                                    width: 40,
                                                    height: 40,
                                                  ),
                                                )
                                              : Image.asset(
                                                  'assets/images/empresa.png',
                                                  width: 40,
                                                  height: 40,
                                                ),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    nombreEmpresa,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      color: estado == 'Activo'
                                                          ? Colors.green
                                                          : Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  )
                                                ],
                                              ),
                                              const Text(
                                                'Ofreciendo productos únicos',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isSearching
                                    ? Iconsax.close_circle
                                    : Iconsax.search_normal,
                                color: const Color.fromARGB(255, 0, 0, 0),
                                size: 25,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_isSearching) {
                                    _searchController.clear();
                                    _productos = widget.productosPasados!
                                        .where((producto) =>
                                            producto['userid'] ==
                                                widget.empresaUserId &&
                                            (_categoriaSeleccionada ==
                                                    'General' ||
                                                (producto['categoria'] ?? '') ==
                                                    _categoriaSeleccionada))
                                        .toList();
                                  }
                                  _isSearching = !_isSearching;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0),
                        child: CategoriaSelector(
                          onCategoriaSelected: (value) {
                            _categoriaSeleccionada = value;
                            _itemsToShow = 4;
                            _isLoadingMore = false;
                            _filtrarProductos();
                            _isSearching = false;
                          },
                        ),
                      ),
                      SizedBox(height: 5),
                      Expanded(
                        child: _productos.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    'No hay productos disponibles.',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                ),
                              )
                            : _buildGrid(_productos),
                      ),
                    ],
                  ),
                );
              },
            ),
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Consumer<CarritoService>(
                  builder: (context, carritoService, _) {
                    if (carritoService.obtenerCarrito().isEmpty) {
                      return const SizedBox.shrink();
                    } else {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: FloatingActionButton(
                          heroTag: 'carrito_btn',
                          onPressed: () {},
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: IconoCarritoConBadge(
                            usarEstiloBoton: false,
                            altura: 48,
                            iconSize: 24,
                            fondoColor: Colors.white,
                            iconColor: Colors.black,
                            borderRadius: 30,
                          ),
                        ),
                      );
                    }
                  },
                ),
                FloatingActionButton(
                  heroTag: 'categorias_btn',
                  onPressed: () {
                    showMaterialModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      builder: (context) => FiltrosAdicionalesSheet(
                        onFiltroSeleccionado: (criterio) {
                          Navigator.pop(context);
                          _filtrarProductos(criterio: criterio);
                        },
                      ),
                    );
                  },
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: const Icon(Iconsax.category,
                      color: Color.fromARGB(255, 255, 255, 255)),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildGrid(List<DocumentSnapshot> productosDocs) {
    final theme = Theme.of(context);

    _productos = productosDocs;
    final showLoader = _isLoadingMore && _itemsToShow < productosDocs.length;

    return Column(children: [
      Expanded(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: GridView.builder(
          controller: _scrollController,
          itemCount: (_itemsToShow < productosDocs.length)
              ? _itemsToShow
              : productosDocs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.55,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final productoDoc = productosDocs[index];
            final producto = productoDoc.data() as Map<String, dynamic>;
            producto['id'] = productoDoc.id;
            final imagenes = List<String>.from(producto['imagenes'] ?? []);
            final double precioOriginal =
                double.tryParse(producto['precio'].toString()) ?? 0.0;
            final double descuento =
                double.tryParse(producto['descuento']?.toString() ?? '0') ??
                    0.0;
            final bool hayDescuento = descuento > 0;

            return GestureDetector(
              onTap: () {
                navegarConSlideIzquierda(
                  context,
                  DetalleProductoPage(
                    producto: producto,
                    desdeVisitaperfilScreen: true,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 232, 232, 232)
                          .withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                        child: (imagenes.isNotEmpty && imagenes[0].isNotEmpty
                            ? Image.network(
                                imagenes[0],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/empresa.png',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/images/empresa.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto['nombreProducto'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                (() {
                                  final desc = producto['descripcion'] ?? '';
                                  final trimmed = desc.length > 40
                                      ? '${desc.substring(0, 40)}...'
                                      : desc;
                                  return trimmed;
                                })(),
                                style: const TextStyle(
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (hayDescuento)
                                      Text(
                                        'S/ ${precioOriginal.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    Text(
                                      'S/ ${(hayDescuento ? (precioOriginal * (1 - descuento / 100)) : precioOriginal).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(width: 30),
                                if (hayDescuento)
                                  Text(
                                    '${descuento.toStringAsFixed(0)}% OFF',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.error,
                                    ),
                                  )
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      )),
      if (showLoader)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(
            color: Color(0xFFFFC800),
          ),
        ),
    ]);
  }
}
