import 'dart:async';
import 'dart:ui';
import 'package:bootsup/Clases/Publicacion.dart';
import 'package:bootsup/Modulos/ModuloSeguidores/SeguidoresService.dart';
import 'package:bootsup/Vista/EmpresaVista/VisitasPerfilYPublicaciones/todoLosProductos.dart';
import 'package:bootsup/Vista/EmpresaVista/VisitasPerfilYPublicaciones/PublicacionVist.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/Badges.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/ChatsCliente/ChatContacto.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/carritoService.dart';
import 'package:bootsup/Vistas/detalleproducto/detalleProducto.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:redacted/redacted.dart';

class VisitaperfilScreem extends StatefulWidget {
  final Map<String, dynamic> empresa;

  const VisitaperfilScreem({Key? key, required this.empresa}) : super(key: key);

  @override
  _VisitaperfilScreemState createState() => _VisitaperfilScreemState();
}

class _VisitaperfilScreemState extends State<VisitaperfilScreem> {
  String _empresaNombre = 'Cargando...';
  String _empresaestado = '';
  String _empresaDescripcion = 'Cargando...';
  String? _empresaImagenUrl;
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<DocumentSnapshot> _productos1 = [];
  List<Publicacion> _publicaciones = [];
  bool _isRedacted = true;

  String? selectedCategoria;

  bool _siguiendo = false;

  List<DocumentSnapshot> _allProductos = [];
  late String empresaUserId;
  final SeguidorService _seguidorService = SeguidorService();

  Future<void> _cargarDatosEmpresaCompleta(String userId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // ← IMPORTANTE
    });

    try {
      final resultados = await Future.wait([
        FirebaseFirestore.instance
            .collection('productos')
            .where('userid', isEqualTo: userId)
            .get(),
        FirebaseFirestore.instance
            .collection('publicaciones')
            .where('publicacionDeEmpresa', isEqualTo: userId)
            .limit(20)
            .get(),
        FirebaseFirestore.instance
            .collection('productos')
            .where('userid', isEqualTo: userId)
            .get(),
        FirebaseFirestore.instance
            .collection('publicaciones')
            .where('publicacionDeEmpresa', isEqualTo: userId)
            .get(),
        FirebaseFirestore.instance
            .collection('empresa')
            .where('userid', isEqualTo: userId)
            .limit(1)
            .get(),
        _seguidorService.fetchEmpresaDataSeguir(userId)
      ]);

      final productosSnapshot = resultados[0] as QuerySnapshot;
      final publicacionesSnapshot = resultados[1] as QuerySnapshot;

      final empresaSnapshot = resultados[4] as QuerySnapshot;

      final productosDocs = productosSnapshot.docs;
      final publicacionesDocs = publicacionesSnapshot.docs;

      if (!mounted) return;
      setState(() {
        _allProductos = productosDocs;
        _allProductos.shuffle();

        _productos1 = List.from(_allProductos);

        _publicaciones = publicacionesDocs
            .map((doc) => Publicacion.fromDocument(doc))
            // ignore: unnecessary_null_comparison
            .where((p) => p != null)
            .toList();
        if (empresaSnapshot.docs.isNotEmpty) {
          final empresa =
              empresaSnapshot.docs.first.data() as Map<String, dynamic>;
          _empresaNombre =
              empresa['nombre'] ?? 'Nombre de la empresa no disponible';
          _empresaDescripcion =
              empresa['descripcion'] ?? 'Descripción no disponible';
          _empresaImagenUrl = empresa['perfilEmpresa'];
          _empresaestado =
              empresa['estado'] ?? 'Nombre de la empresa no disponible';
        } else {
          _empresaNombre = 'Agregar un nombre';
          _empresaDescripcion =
              'Agrega una descripcion breve de los productos o servicios que tu empresa ofrece.';
          _empresaImagenUrl = null;
        }

        print("Productos cargados: ${_productos1.length}");
        print("UserID usado: $userId");
      });
    } catch (e) {
      print("Error al cargar datos completos de la empresa: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fetchAndRedactPerfilEmpresa(String userId) async {
    if (!mounted) return;
    setState(() {
      _isRedacted = true;
    });
    _cargarDatosEmpresaCompleta(userId);

    final stopwatch = Stopwatch()..start();

    await Future.wait([]);

    final elapsed = stopwatch.elapsed;
    const minDuration = Duration(seconds: 1);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }
    if (!mounted) return;
    setState(() {
      _isRedacted = false;
    });
  }

  @override
  void initState() {
    super.initState();

    final userId = widget.empresa['userid'];
    empresaUserId = widget.empresa['userid'];
    _fetchAndRedactPerfilEmpresa(userId);
    _verificarSeguidor(userId);
  }

  void _verificarSeguidor(String userId) async {
    final empresaData = await _seguidorService.fetchEmpresaDataSeguir(userId);
    if (empresaData != null && empresaData['id'] != null) {
      final sigue =
          await _seguidorService.verificarSiSigueEmpresa(empresaData['id']);
      if (mounted) {
        setState(() {
          _siguiendo = sigue;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return WillPopScope(
        onWillPop: () async {
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
            },
            behavior: HitTestBehavior.translucent,
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                toolbarHeight: 48,
                titleSpacing: 0,
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(1.0),
                  child: Container(
                    height: 1.0,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                  ),
                ),
                leading: IconButton(
                  icon: Icon(
                    Iconsax.arrow_left,
                    size: 25,
                    color: theme.iconTheme.color,
                  ),
                  color: Color.fromARGB(255, 0, 0, 0),
                  onPressed: () async {
                    final carritoService =
                        Provider.of<CarritoService>(context, listen: false);
                    if (carritoService.obtenerCarrito().isEmpty) {
                      Provider.of<CarritoService>(
                        context,
                        listen: false,
                      );
                      carritoService.limpiardescripcion();
                      Navigator.pop(context);
                      return;
                    }

                    // ignore: unused_local_variable
                    bool? result = await showCustomDialog(
                      context: context,
                      title: 'Eliminar carrito',
                      message:
                          '¿Estás seguro?, Si sales ahora, se eliminará tu carrito de compras.',
                      confirmButtonText: 'Sí, salir',
                      cancelButtonText: 'No',
                      confirmButtonColor: Colors.red,
                      cancelButtonColor: const Color.fromARGB(255, 0, 0, 0),
                    ).then((confirmed) {
                      if (confirmed != null && confirmed) {
                        setState(() {
                          carritoService.limpiarCarrito();
                          carritoService.limpiardescripcion();
                          Navigator.pop(context);
                        });
                      }
                      return null;
                    });
                  },
                ),
                title: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    _empresaNombre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).redacted(
                    context: context,
                    redact: _isRedacted,
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/veri.png',
                    width: 24,
                    height: 24,
                  ).redacted(
                    context: context,
                    redact: _isRedacted,
                  ),
                ]),
              ),
              body: SingleChildScrollView(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 18, 0, 0),
                            child: Container(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(width: 20),
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: _empresaImagenUrl != null
                                              ? Image.network(
                                                  _empresaImagenUrl!,
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                Color(
                                                                    0xFFFFAF00)),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Image.asset(
                                                      'assets/images/empresa.png',
                                                      fit: BoxFit.cover,
                                                      width: 100,
                                                      height: 100,
                                                    ).redacted(
                                                      context: context,
                                                      redact: _isRedacted,
                                                    );
                                                  },
                                                ).redacted(
                                                  context: context,
                                                  redact: _isRedacted)
                                              : Image.asset(
                                                  'assets/images/empresa.png',
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                ).redacted(
                                                  context: context,
                                                  redact: _isRedacted),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  _empresaNombre,
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w700,
                                                    color: theme.textTheme
                                                        .bodyLarge?.color,
                                                  ),
                                                  textAlign: TextAlign.start,
                                                ).redacted(
                                                  context: context,
                                                  redact: _isRedacted,
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: _empresaestado ==
                                                            'Activo'
                                                        ? Colors.green
                                                        : Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ).redacted(
                                                  context: context,
                                                  redact: _isRedacted,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                buildContadorStream(
                                                  collection: 'publicaciones',
                                                  whereField:
                                                      'publicacionDeEmpresa',
                                                  equalTo: empresaUserId,
                                                  label: 'Publicaciones',
                                                ),
                                                SizedBox(width: 10),
                                                buildContadorStream(
                                                  collection: 'seguidores',
                                                  whereField:
                                                      'idempresasiguiendo',
                                                  equalTo: empresaUserId,
                                                  label: 'Seguidores',
                                                ),
                                                SizedBox(width: 10),
                                                buildContadorStream(
                                                  collection: 'productos',
                                                  whereField: 'userid',
                                                  equalTo: empresaUserId,
                                                  label: 'Productos',
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(
                                        left: 22, right: 20),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          0, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      _empresaDescripcion,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 15,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                      textAlign: TextAlign.start,
                                    ).redacted(
                                      context: context,
                                      redact: _isRedacted,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  if (!_isRedacted)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                  child: SizedBox(
                                                      height: 45,
                                                      child:
                                                          ElevatedButton.icon(
                                                        onPressed: () async {
                                                          final String userId =
                                                              widget.empresa[
                                                                  'userid'];
                                                          final empresaData =
                                                              await _seguidorService
                                                                  .fetchEmpresaDataSeguir(
                                                                      userId);

                                                          if (empresaData !=
                                                              null) {
                                                            final idEmpresa =
                                                                empresaData[
                                                                    'id'];
                                                            bool resultado =
                                                                false;
                                                            if (_siguiendo) {
                                                              resultado = await _seguidorService
                                                                  .dejarDeSeguirEmpresa(
                                                                      idEmpresa);
                                                            } else {
                                                              resultado = await _seguidorService
                                                                  .seguirEmpresa(
                                                                      idEmpresa);
                                                            }
                                                            if (mounted &&
                                                                resultado) {
                                                              setState(() {
                                                                _siguiendo =
                                                                    !_siguiendo;
                                                              });
                                                            }
                                                          }
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor: _siguiendo
                                                              ? theme
                                                                  .colorScheme
                                                                  .primary
                                                              : (isDark
                                                                  ? Colors.grey
                                                                      .shade800
                                                                  : Colors.grey
                                                                      .shade200),
                                                          foregroundColor:
                                                              _siguiendo
                                                                  ? Colors.white
                                                                  : theme
                                                                      .textTheme
                                                                      .bodyMedium
                                                                      ?.color,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      14,
                                                                  vertical: 10),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          elevation: 0,
                                                        ),
                                                        icon: Icon(
                                                          _siguiendo
                                                              ? Iconsax
                                                                  .user_tick
                                                              : Iconsax
                                                                  .user_add,
                                                          color: _siguiendo
                                                              ? Colors.white
                                                              : theme.iconTheme
                                                                  .color,
                                                          size: 20,
                                                        ),
                                                        label: Text(
                                                          _siguiendo
                                                              ? 'Siguiendo'
                                                              : 'Seguir',
                                                          style: theme.textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: _siguiendo
                                                                ? Colors.white
                                                                : null,
                                                          ),
                                                        ),
                                                      ))),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                  child: SizedBox(
                                                      height: 45,
                                                      child:
                                                          ElevatedButton.icon(
                                                        onPressed: () async {
                                                          final userIdVisitante =
                                                              FirebaseAuth
                                                                  .instance
                                                                  .currentUser
                                                                  ?.uid;
                                                          if (userIdVisitante ==
                                                              null) {
                                                            print(
                                                                "Usuario no autenticado.");
                                                            return;
                                                          }
                                                          navegarConSlideDerecha(
                                                            context,
                                                            ContactoEmpresaS(
                                                              userIdVisitante:
                                                                  userIdVisitante,
                                                              empresaUserId:
                                                                  empresaUserId,
                                                            ),
                                                          );
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              isDark
                                                                  ? Colors.grey
                                                                      .shade800
                                                                  : Colors.grey
                                                                      .shade200,
                                                          foregroundColor: theme
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.color,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      14,
                                                                  vertical: 10),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          elevation: 0,
                                                        ),
                                                        icon: Icon(
                                                          Iconsax.message_text,
                                                          color: theme
                                                              .iconTheme.color,
                                                          size: 20,
                                                        ),
                                                        label: Text(
                                                          'Contactar',
                                                          style: theme.textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      )))
                                            ],
                                          ).redacted(
                                            context: context,
                                            redact: _isRedacted,
                                          ),
                                        )
                                      ],
                                    ),
                                  Column(
                                    children: [
                                      SizedBox(height: 45),
                                      Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  theme.scaffoldBackgroundColor,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () => setState(() {
                                                      _selectedIndex = 0;
                                                    }),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 10),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Iconsax.gallery,
                                                                size: 18,
                                                                color: _selectedIndex ==
                                                                        0
                                                                    ? const Color(
                                                                        0xFFFFAF00)
                                                                    : theme
                                                                        .iconTheme
                                                                        .color,
                                                              ),
                                                              const SizedBox(
                                                                  width: 6),
                                                              Text(
                                                                'Publicaciones',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: _selectedIndex ==
                                                                          0
                                                                      ? Color(
                                                                          0xFFFFAF00)
                                                                      : theme
                                                                          .textTheme
                                                                          .bodyMedium
                                                                          ?.color,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () => setState(() =>
                                                        _selectedIndex = 1),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 10),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Iconsax.box,
                                                                size: 18,
                                                                color: _selectedIndex ==
                                                                        1
                                                                    ? const Color(
                                                                        0xFFFFAF00)
                                                                    : theme
                                                                        .iconTheme
                                                                        .color,
                                                              ),
                                                              const SizedBox(
                                                                  width: 6),
                                                              Text(
                                                                'Productos',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: _selectedIndex ==
                                                                          1
                                                                      ? Color(
                                                                          0xFFFFAF00)
                                                                      : theme
                                                                          .iconTheme
                                                                          .color,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                      if (_selectedIndex == 0)
                                        Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Divider(
                                                height: 1,
                                                thickness: 1,
                                                color: Colors
                                                    .grey, // o usa theme.dividerColor si deseas
                                              ),
                                              Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .scaffoldBackgroundColor,
                                                ),
                                                child: Center(
                                                  child: _isLoading
                                                      ? LoadingAnimationWidget
                                                          .staggeredDotsWave(
                                                          color:
                                                              Color(0xFFFFAF00),
                                                          size: 50,
                                                        )
                                                      : _publicaciones.isEmpty
                                                          ? Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Text(
                                                                  '',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                ),
                                                              ],
                                                            )
                                                          : GridView.builder(
                                                              shrinkWrap: true,
                                                              physics:
                                                                  NeverScrollableScrollPhysics(),
                                                              gridDelegate:
                                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                                crossAxisCount:
                                                                    3,
                                                                crossAxisSpacing:
                                                                    2,
                                                                mainAxisSpacing:
                                                                    2,
                                                              ),
                                                              itemCount:
                                                                  _publicaciones
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                final publicacion =
                                                                    _publicaciones[
                                                                        index];
                                                                final imagenes =
                                                                    publicacion
                                                                        .imagenes;
                                                                final primeraImagen =
                                                                    imagenes.isNotEmpty
                                                                        ? imagenes[
                                                                            0]
                                                                        : null;
                                                                final cantidad =
                                                                    imagenes
                                                                        .length;

                                                                return GestureDetector(
                                                                  onTap: () {
                                                                    if (primeraImagen !=
                                                                        null) {
                                                                      imagenesEnCuadros(
                                                                          context,
                                                                          publicacion
                                                                              .imagenes,
                                                                          0,
                                                                          publicacion);
                                                                    }
                                                                  },
                                                                  child: Stack(
                                                                    children: [
                                                                      Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          image: primeraImagen != null
                                                                              ? DecorationImage(
                                                                                  image: NetworkImage(primeraImagen),
                                                                                  fit: BoxFit.cover,
                                                                                )
                                                                              : null,
                                                                          color:
                                                                              const Color(0xFFFAFAFA),
                                                                        ),
                                                                        child: primeraImagen ==
                                                                                null
                                                                            ? Center(child: Text("Sin imagen"))
                                                                            : null,
                                                                      ).redacted(
                                                                        context:
                                                                            context,
                                                                        redact:
                                                                            _isRedacted,
                                                                      ),
                                                                      if (cantidad >
                                                                          1)
                                                                        Positioned(
                                                                          right:
                                                                              4,
                                                                          bottom:
                                                                              4,
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                EdgeInsets.all(4),
                                                                            child:
                                                                                Image.asset(
                                                                              'assets/iconos/galeria.png',
                                                                              width: 20,
                                                                              height: 20,
                                                                              color: const Color(0xFFFFAF00),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ).redacted(
                                                                  context:
                                                                      context,
                                                                  redact:
                                                                      _isRedacted,
                                                                );
                                                              },
                                                            ),
                                                ),
                                              )
                                            ])
                                      else if (_selectedIndex == 1)
                                        Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Divider(
                                                height: 1,
                                                thickness: 1,
                                                color: Colors
                                                    .grey, // o usa theme.dividerColor si deseas
                                              ),
                                              Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .scaffoldBackgroundColor,
                                                ),
                                                child: Center(
                                                  child: _isLoading
                                                      ? LoadingAnimationWidget
                                                          .staggeredDotsWave(
                                                          color:
                                                              Color(0xFFFFAF00),
                                                          size: 50,
                                                        )
                                                      : _productos1.isEmpty
                                                          ? Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Text(
                                                                  '',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                ),
                                                              ],
                                                            )
                                                          : _gridDeProductos(
                                                              context),
                                                ),
                                              ),
                                            ])
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              floatingActionButton: Consumer<CarritoService>(
                builder: (context, carritoService, _) {
                  if (carritoService.obtenerCarrito().isEmpty) {
                    return const SizedBox.shrink();
                  } else {
                    return FloatingActionButton(
                      heroTag: 'fab_carrito',
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
                    );
                  }
                },
              ),
            )));
  }

  Widget buildContadorStream({
    required String collection,
    required String whereField,
    required String equalTo,
    required String label,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where(whereField, isEqualTo: equalTo)
          .snapshots(),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final count = snapshot.data?.size ?? 0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ).redacted(
              context: context,
              redact: _isRedacted,
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ).redacted(
              context: context,
              redact: _isRedacted,
            ),
          ],
        );
      },
    );
  }

  void imagenesEnCuadros(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
    dynamic item,
  ) {
    if (item is Publicacion) {
      navegarConSlideIzquierda(
        context,
        PublicacionVista(
          publicacionData: {
            'id': item.id,
            'descripcion': item.descripcion,
            'fecha': item.fecha.toIso8601String(),
            'imagenes': item.imagenes,
            'userid': item.userid,
            'publicacionDeEmpresa': item.publicacionDeEmpresa,
            'imageRatio': item.imageRatio,
          },
        ),
      );
    }
  }

  Widget _gridDeProductos(BuildContext context) {
    final productosLimitados = _productos1.take(4).toList();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: productosLimitados.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: _isRedacted ? 0.63 : 0.55,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              var productoDoc = productosLimitados[index];
              final producto = productoDoc.data() as Map<String, dynamic>;
              producto['id'] = productoDoc.id;
              final imagenes = List<String>.from(producto['imagenes'] ?? []);
              final double precioOriginal =
                  double.tryParse(producto['precio'].toString()) ?? 0.0;
              final double descuento =
                  double.tryParse(producto['descuento']?.toString() ?? '0') ??
                      0.0;
              final bool hayDescuento = descuento > 0;
              final double precioConDescuento =
                  precioOriginal * (1 - descuento / 100);

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
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 255, 255, 255)
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
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(14)),
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
                                    ).redacted(
                                      context: context,
                                      redact: _isRedacted,
                                    );
                                  },
                                ).redacted(
                                  context: context,
                                  redact: _isRedacted,
                                )
                              : Image.asset(
                                  'assets/images/empresa.png',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ).redacted(
                                  context: context,
                                  redact: _isRedacted,
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ).redacted(
                                context: context,
                                redact: _isRedacted,
                              ),
                              if (!_isRedacted)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    (() {
                                      final desc =
                                          producto['descripcion'] ?? '';
                                      final trimmed = desc.length > 40
                                          ? desc.substring(0, 40) + '...'
                                          : desc;
                                      return trimmed;
                                    })(),
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 13,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              Spacer(),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hayDescuento)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'S/ ${precioOriginal.toStringAsFixed(2)}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontSize: 13,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: theme
                                                .textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        Text(
                                          'S/ ${precioConDescuento.toStringAsFixed(2)}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            color: theme
                                                .textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (!hayDescuento)
                                    Text(
                                      'S/ ${precioOriginal.toStringAsFixed(2)}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  if (hayDescuento)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0, top: 2.0),
                                      child: Text(
                                        '${descuento.toStringAsFixed(0)}% OFF',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                ],
                              ).redacted(
                                context: context,
                                redact: _isRedacted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              navegarConSlideDerecha(
                context,
                TodosLosProductosPage(
                  empresaUserId: empresaUserId,
                  productosPasados: _productos1,
                  desdePerfildelaEmpresa: true,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver tienda',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 20,
                    color: theme.iconTheme.color,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
