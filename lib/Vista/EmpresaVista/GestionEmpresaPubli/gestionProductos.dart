import 'package:bootsup/Vista/EmpresaVista/GestionEmpresaPubli/actualizarProductos.dart';
import 'package:bootsup/widgets/BotonesSeleccionables.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Gestionproductos extends StatefulWidget {
  @override
  _GestionproductosState createState() => _GestionproductosState();
}

class _GestionproductosState extends State<Gestionproductos> {
  bool _isUploading = false;
  String? _categoriaSeleccionada = 'General';

  List<DocumentSnapshot> _productos = [];
  List<DocumentSnapshot> _allProductos = [];
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();

  int _productosPorPagina = 6;
  DocumentSnapshot? _ultimoDocumento;
  bool _isCargandoMas = false;
  bool _todosCargados = false;

  @override
  void initState() {
    super.initState();

    _categoriaSeleccionada = 'General';

    cargarContenido1();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isCargandoMas &&
          !_todosCargados) {
        _fetchProductosPaginados(categoria: _categoriaSeleccionada);
      }
    });
    _searchController.addListener(() {
      String query = _searchController.text.toLowerCase();
      setState(() {
        if (query.isEmpty) {
          _productos = List.from(_allProductos);
        } else {
          _productos = _allProductos
              .where((producto) => producto['nombreProducto']
                  .toString()
                  .toLowerCase()
                  .contains(query))
              .toList();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> cargarContenido1() async {
    if (!mounted) return;
    setState(() {
      _isUploading = true;
    });

    await _fetchProductosPaginados(
        categoria: _categoriaSeleccionada, reiniciar: true);

    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _isUploading = false;
    });
  }

  Future<void> _fetchProductosPaginados(
      {String? categoria, bool reiniciar = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ✅ Reiniciar banderas correctamente al cambiar de categoría o hacer refresh
    if (reiniciar) {
      _ultimoDocumento = null;
      _todosCargados = false;
      _isCargandoMas = false;
    }

    // ⛔️ Este check debe venir después del reinicio
    if (_todosCargados || _isCargandoMas) return;

    setState(() {
      _isCargandoMas = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('productos')
          .where('userid', isEqualTo: user.uid);

      if (categoria != null && categoria != 'General') {
        query = query.where('categoria', isEqualTo: categoria);
      }

      if (_ultimoDocumento != null) {
        query = query.startAfterDocument(_ultimoDocumento!);
      }

      query = query.limit(_productosPorPagina);

      final snapshot = await query.get();
      if (!mounted) return;
      if (snapshot.docs.isNotEmpty) {
        _ultimoDocumento = snapshot.docs.last;
        setState(() {
          if (reiniciar) {
            _productos = snapshot.docs;
          } else {
            _productos.addAll(snapshot.docs);
          }
          _allProductos = List.from(_productos);
        });
      } else {
        if (reiniciar) {
          if (!mounted) return;
          setState(() {
            _productos = [];
            _allProductos = [];
          });
        }
        _todosCargados = true;
      }
    } catch (e) {
      print("Error en paginación: $e");
    }

    setState(() {
      _isCargandoMas = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          titleSpacing: 0,
          toolbarHeight: 48,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Iconsax.arrow_left,
              color: theme.iconTheme.color,
              size: 25,
            ),
            onPressed: () {
              if (!_isUploading) {
                Navigator.pop(context);
              }
            },
          ),
          title: _isSearching
              ? Theme(
                  data: ThemeData(
                    textSelectionTheme: const TextSelectionThemeData(
                      selectionColor: Color(0xFFFFC800),
                      cursorColor: Colors.black,
                      selectionHandleColor: Colors.black,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (query) {
                      setState(() {
                        String q = query.toLowerCase();
                        if (q.isEmpty) {
                          _productos = List.from(_allProductos);
                        } else {
                          _productos = _allProductos
                              .where((producto) => producto['nombreProducto']
                                  .toString()
                                  .toLowerCase()
                                  .contains(q))
                              .toList();
                        }
                      });
                    },
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontFamily: 'Afacad',
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 16.0,
                        fontFamily: 'Afacad',
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                )
              : Text(
                  'Gestiona tus productos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(
                _isSearching ? Iconsax.close_circle : Iconsax.search_normal,
                color: theme.iconTheme.color,
                size: 25,
              ),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _searchController.clear();
                    _fetchProductosPaginados(
                        categoria: _categoriaSeleccionada, reiniciar: true);
                  }
                  _isSearching = !_isSearching;
                });
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              height: 1.0,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[300],
            ),
          ),
        ),
        body: _isUploading
            ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                color: Color(0xFFFFAF00),
                size: 50,
              ))
            : RefreshIndicator(
                color: Colors.amber,
                backgroundColor: Colors.black,
                onRefresh: () async {
                  await cargarContenido1();
                },
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      child: CategoriaSelector(
                        onCategoriaSelected: (value) {
                          setState(() {
                            _categoriaSeleccionada = value;
                          });
                          _fetchProductosPaginados(
                              categoria: value, reiniciar: true);
                        },
                      ),
                    ),
                    Expanded(
                      child: _productos.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 20),
                                    Image.asset(
                                      'assets/images/noproducto.png',
                                      height: 200,
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No hay productos aún',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Cuando se agregue contenido aparecerá aquí.',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 14,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.all(12),
                              itemCount: _productos.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                                childAspectRatio: 0.55,
                              ),
                              itemBuilder: (context, index) {
                                var productoDoc = _productos[index];
                                var producto =
                                    productoDoc.data() as Map<String, dynamic>;
                                producto['id'] = productoDoc.id;

                                var imagenes = List<String>.from(
                                    producto['imagenes'] ?? []);
                                final double precioOriginal = double.tryParse(
                                        producto['precio'].toString()) ??
                                    0.0;
                                final double descuento = double.tryParse(
                                        producto['descuento']?.toString() ??
                                            '0') ??
                                    0.0;
                                final bool hayDescuento = descuento > 0;
                                final double precioConDescuento =
                                    precioOriginal * (1 - descuento / 100);
                                return Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ActualizarProductoPage(
                                              producto: producto,
                                              heroTag:
                                                  'producto_${producto['id']}',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: theme.cardColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color.fromARGB(
                                                      255, 232, 232, 232)
                                                  .withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Hero(
                                              tag:
                                                  'producto_${producto['id']}_$index',
                                              child: AspectRatio(
                                                aspectRatio: 1,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      const BorderRadius
                                                          .vertical(
                                                          top: Radius.circular(
                                                              12)),
                                                  child: (imagenes.isNotEmpty &&
                                                          imagenes[0]
                                                              .isNotEmpty)
                                                      ? Image.network(
                                                          imagenes[0],
                                                          fit: BoxFit.cover,
                                                          width:
                                                              double.infinity,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Image.asset(
                                                              'assets/images/empresa.png',
                                                              fit: BoxFit.cover,
                                                              width: double
                                                                  .infinity,
                                                            );
                                                          },
                                                        )
                                                      : Image.asset(
                                                          'assets/images/empresa.png',
                                                          fit: BoxFit.cover,
                                                          width:
                                                              double.infinity,
                                                        ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      producto[
                                                              'nombreProducto'] ??
                                                          '',
                                                      style: theme
                                                          .textTheme.titleMedium
                                                          ?.copyWith(
                                                        fontSize: 16,
                                                        color: theme.textTheme
                                                            .bodyLarge?.color,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: 3),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8),
                                                      child: Text(
                                                        (() {
                                                          final desc = producto[
                                                                  'descripcion'] ??
                                                              '';
                                                          final trimmed = desc
                                                                      .length >
                                                                  40
                                                              ? desc.substring(
                                                                      0, 40) +
                                                                  '...'
                                                              : desc;
                                                          return trimmed;
                                                        })(),
                                                        style: theme.textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                          fontSize: 12,
                                                          color: theme.textTheme
                                                              .bodyLarge?.color,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    Spacer(),
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if (hayDescuento)
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'S/ ${precioOriginal.toStringAsFixed(2)}',
                                                                style: theme
                                                                    .textTheme
                                                                    .titleMedium
                                                                    ?.copyWith(
                                                                  fontSize: 13,
                                                                  decoration:
                                                                      TextDecoration
                                                                          .lineThrough,
                                                                  color: theme
                                                                      .textTheme
                                                                      .bodyLarge
                                                                      ?.color,
                                                                ),
                                                              ),
                                                              Text(
                                                                'S/ ${precioConDescuento.toStringAsFixed(2)}',
                                                                style: theme
                                                                    .textTheme
                                                                    .titleMedium
                                                                    ?.copyWith(
                                                                  fontSize: 19,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: theme
                                                                      .textTheme
                                                                      .bodyLarge
                                                                      ?.color,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        if (!hayDescuento)
                                                          Text(
                                                            'S/ ${precioOriginal.toStringAsFixed(2)}',
                                                            style: theme
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: theme
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.color,
                                                            ),
                                                          ),
                                                        if (hayDescuento)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 8.0,
                                                                    top: 2.0),
                                                            child: Text(
                                                              '${descuento.toStringAsFixed(0)}% OFF',
                                                              style: theme
                                                                  .textTheme
                                                                  .titleMedium
                                                                  ?.copyWith(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: theme
                                                                    .colorScheme
                                                                    .error,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.close,
                                              color: Colors.white, size: 24),
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                          onPressed: () async {
                                            await showCustomDialog(
                                              context: context,
                                              title:
                                                  'Eliminar producto seleccionado',
                                              message:
                                                  '¿Estás seguro que deseas continuar?',
                                              confirmButtonText: 'Sí',
                                              cancelButtonText: 'No',
                                              confirmButtonColor: Colors.red,
                                              cancelButtonColor: Colors.blue,
                                            ).then((confirmed) {
                                              if (confirmed != null &&
                                                  confirmed) {
                                                setState(() {
                                                  _eliminarProducto(index);
                                                });
                                              }
                                              return null;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ));
  }

  Future<void> _eliminarProducto(int index) async {
    final productoDoc = _productos[index];
    final productoId = productoDoc.id;
    final productoData = productoDoc.data() as Map<String, dynamic>?;

    if (productoData == null) return;

    final List<dynamic>? imagenes = productoData['imagenes'];

    setState(() {
      _isUploading = true;
    });

    try {
      if (imagenes != null) {
        final deleteFutures = imagenes.cast<String>().map((url) async {
          try {
            final ref = FirebaseStorage.instance.refFromURL(url);
            await ref.delete();
          } catch (e) {
            print("Error eliminando imagen $url: $e");
          }
        }).toList();

        await Future.wait(deleteFutures);
      }

      await FirebaseFirestore.instance
          .collection('productos')
          .doc(productoId)
          .delete();

      await showCustomDialog(
        context: context,
        title: 'Éxito',
        message: 'Producto eliminado con éxito',
        confirmButtonText: 'Cerrar',
      );

      setState(() {
        _productos.removeAt(index);
      });
    } catch (e) {
      print('Error al eliminar producto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar producto.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
