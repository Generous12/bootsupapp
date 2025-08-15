import 'dart:async';
import 'package:bootsup/Clases/Publicacion.dart';
import 'package:bootsup/Vista/EmpresaVista/menuPerfilEmpresa/Productos.dart';
import 'package:bootsup/Vista/EmpresaVista/menuPerfilEmpresa/Publicaciones.dart';
import 'package:bootsup/Vista/EmpresaVista/menuPerfilEmpresa/ReelsVideo/Reels.dart';
import 'package:bootsup/Vista/EmpresaVista/datosEmpresa.dart';
import 'package:bootsup/Vista/EmpresaVista/VisitasPerfilYPublicaciones/PublicacionVist.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/Badges.dart';
import 'package:bootsup/Vistas/detalleproducto/detalleProducto.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:redacted/redacted.dart';

class EmpresaProfileScreen extends StatefulWidget {
  const EmpresaProfileScreen({Key? key}) : super(key: key);

  @override
  _EmpresaProfileScreenState createState() => _EmpresaProfileScreenState();
}

class _EmpresaProfileScreenState extends State<EmpresaProfileScreen> {
  String _empresaNombre = 'Cargando...';
  String _empresaDescripcion = 'Cargando...';
  String? _empresaImagenUrl;

  User? _user = FirebaseAuth.instance.currentUser;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  int _selectedIndex = 0;
  bool _isLoading = false;
  List<DocumentSnapshot> _allProductos = [];
  List<Publicacion> _publicaciones = [];
  bool _isRedacted = true;
  int publicacionesCount = 0;
  int seguidorescount = 0;
  int productosCount = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _fetchPerfilEmpresaCompleto();
    cargarContenido();
  }

  Future<void> _fetchPerfilEmpresaCompleto() async {
    if (!mounted || _user == null) return;

    setState(() {
      _isRedacted = true;
    });

    try {
      final stopwatch = Stopwatch()..start();

      final uid = _user!.uid;
      final resultados = await Future.wait([
        FirebaseFirestore.instance
            .collection('empresa')
            .where('userid', isEqualTo: uid)
            .limit(1)
            .get(),
        FirebaseFirestore.instance
            .collection('publicaciones')
            .where('publicacionDeEmpresa', isEqualTo: uid)
            .get(),
        FirebaseFirestore.instance
            .collection('productos')
            .where('userid', isEqualTo: uid)
            .get(),
        FirebaseFirestore.instance
            .collection('seguidores')
            .where('idempresasiguiendo', isEqualTo: uid)
            .get(),
        FirebaseFirestore.instance
            .collection('publicaciones')
            .where('publicacionDeEmpresa', isEqualTo: uid)
            .get(),
      ]);

      final empresaSnapshot = resultados[0] as QuerySnapshot;
      final publicacionesSnapshot = resultados[1] as QuerySnapshot;
      final productosSnapshot = resultados[2] as QuerySnapshot;
      final seguidoresSnapshot = resultados[3] as QuerySnapshot;
      final publicacionesCountSnapshot = resultados[4] as QuerySnapshot;

      final empresaDoc =
          empresaSnapshot.docs.isNotEmpty ? empresaSnapshot.docs.first : null;
      final data = empresaDoc?.data() as Map<String, dynamic>?;

      if (!mounted) return;

      setState(() {
        _empresaNombre = data?['nombre']?.toString() ?? 'Agregar un nombre';
        _empresaDescripcion = data?['descripcion']?.toString() ??
            'Agrega una descripcion breve de los productos o servicios que tu empresa ofrece.';
        _empresaImagenUrl = data?['perfilEmpresa']?.toString();
        _publicaciones = publicacionesSnapshot.docs
            .map((doc) => Publicacion.fromDocument(doc))
            .toList();

        _allProductos = productosSnapshot.docs;
        _productos1 = productosSnapshot.docs;

        seguidorescount = seguidoresSnapshot.size;
        publicacionesCount = publicacionesCountSnapshot.size;
        productosCount = productosSnapshot.size;
      });

      // Mínimo tiempo visible de carga (opcional)
      final elapsed = stopwatch.elapsed;
      const minDuration = Duration(seconds: 0);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _empresaNombre = 'Error al cargar nombre';
          _empresaDescripcion = 'Error al cargar descripción';
          _empresaImagenUrl = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRedacted = false;
        });
      }
    }
  }

  Future<void> cargarContenido() async {
    setState(() {
      _isLoading = true;
    });

    await _fetchPerfilEmpresaCompleto();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          _isSearching = false;
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
              leading: IconButton(
                icon: Icon(
                  Iconsax.arrow_left,
                  color: theme.iconTheme.color,
                  size: 25,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1.0),
                child: Container(
                  height: 1.0,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[300],
                ),
              ),
              title: _isSearching
                  ? Theme(
                      data: ThemeData(
                        textSelectionTheme: const TextSelectionThemeData(
                          selectionColor: Color(0xFFFFAF00),
                          cursorColor: Colors.black,
                          selectionHandleColor: Colors.black,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (query) {
                          if (!mounted) return;
                          setState(() {
                            String q = query.toLowerCase();
                            if (q.isEmpty) {
                              _productos1 = List.from(_allProductos);
                            } else {
                              _productos1 = _allProductos.where((doc) {
                                final producto =
                                    doc.data() as Map<String, dynamic>;
                                final nombre = producto['nombreProducto']
                                    ?.toString()
                                    .toLowerCase();
                                return nombre != null && nombre.contains(q);
                              }).toList();
                            }
                          });
                        },
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                          fontFamily: 'Afacad',
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
                  : Row(mainAxisSize: MainAxisSize.min, children: [
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
              actions: [
                if (_selectedIndex == 1)
                  IconButton(
                    icon: Icon(
                      _isSearching
                          ? Iconsax.close_circle
                          : Iconsax.search_normal,
                      color: theme.iconTheme.color,
                      size: 30,
                    ),
                    onPressed: _isRedacted
                        ? null // Bloquear si está redactado
                        : () {
                            if (!mounted) return;
                            setState(() {
                              if (_isSearching) {
                                _searchController.clear();
                                _productos1 = List.from(_allProductos);
                              }
                              _isSearching = !_isSearching;
                            });
                          },
                  ),
                if (!_isSearching)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('empresa')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox();
                      }

                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      if (data == null) return const SizedBox();

                      final direccionE = data['direccionE'];

                      final datosCompletos = data['userid'] != null &&
                          data['nombre'] != null &&
                          data['descripcion'] != null &&
                          direccionE != null &&
                          data['telefono'] != null &&
                          data['ruc'] != null &&
                          data['perfilEmpresa'] != null &&
                          data['nombre'].toString().trim().isNotEmpty &&
                          data['descripcion'].toString().trim().isNotEmpty &&
                          direccionE['ubicacion'] != null &&
                          direccionE['ubicacion']
                              .toString()
                              .trim()
                              .isNotEmpty &&
                          direccionE['referencia'] != null &&
                          direccionE['referencia']
                              .toString()
                              .trim()
                              .isNotEmpty &&
                          direccionE['distrito'] != null &&
                          direccionE['distrito'].toString().trim().isNotEmpty &&
                          direccionE['tipo_local'] != null &&
                          direccionE['tipo_local']
                              .toString()
                              .trim()
                              .isNotEmpty &&
                          direccionE['horario_atencion'] != null &&
                          direccionE['horario_atencion']
                              .toString()
                              .trim()
                              .isNotEmpty &&
                          data['telefono'].toString().trim().isNotEmpty &&
                          data['ruc'].toString().trim().isNotEmpty &&
                          data['perfilEmpresa'].toString().trim().isNotEmpty;

                      if (!datosCompletos) return const SizedBox();

                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('MetodoPago')
                            .where('userId', isEqualTo: userId)
                            .limit(1)
                            .get(),
                        builder: (context, metodoPagoSnapshot) {
                          if (metodoPagoSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          final tieneMetodoPago =
                              metodoPagoSnapshot.data?.docs.isNotEmpty ?? false;

                          if (!tieneMetodoPago) return const SizedBox();
                          return IgnorePointer(
                            ignoring: _isRedacted,
                            child: Opacity(
                              opacity: _isRedacted ? 0.5 : 1,
                              child: PopupMenuButton<String>(
                                icon: Icon(
                                  Iconsax.more,
                                  color: Theme.of(context).iconTheme.color,
                                  size: 25,
                                ),
                                color: Colors.white,
                                position: PopupMenuPosition.under,
                                itemBuilder: (BuildContext context) {
                                  return [
                                    const PopupMenuItem<String>(
                                      value: 'Publicaciones',
                                      child: Text(
                                        'Publicaciones',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 18),
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Productos',
                                      child: Text(
                                        'Productos',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 18),
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Reels',
                                      child: Text(
                                        'Reels',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 18),
                                      ),
                                    ),
                                  ];
                                },
                                onSelected: (String value) {
                                  if (!context.mounted || _isRedacted) return;
                                  switch (value) {
                                    case 'Publicaciones':
                                      navegarConSlideDerecha(
                                          context, PublicacionesPage());
                                      break;
                                    case 'Productos':
                                      navegarConSlideDerecha(
                                          context, CrearProductoScreen());
                                      break;
                                    case 'Reels':
                                      navegarConSlideDerecha(
                                          context, VideoEditorPage());
                                      break;
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
              ]),
          body: RefreshIndicator(
              color: const Color(0xFFFFAF00),
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              onRefresh: () async {
                await cargarContenido();
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 18, 0, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(0, 255, 255, 255),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
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
                                          borderRadius: BorderRadius.circular(
                                              15), // Igual que el contenedor
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
                                            Text(
                                              _empresaNombre,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: theme
                                                    .textTheme.bodyLarge?.color,
                                              ),
                                            ).redacted(
                                                context: context,
                                                redact: _isRedacted),
                                            const SizedBox(height: 15),
                                            Row(
                                              children: [
                                                buildContadorStream(
                                                  collection: 'publicaciones',
                                                  whereField:
                                                      'publicacionDeEmpresa',
                                                  equalTo: _user?.uid ?? '',
                                                  label: 'Publicaciones',
                                                ),
                                                const SizedBox(width: 10),
                                                buildContadorStream(
                                                  collection: 'seguidores',
                                                  whereField:
                                                      'idempresasiguiendo',
                                                  equalTo: _user?.uid ?? '',
                                                  label: 'Seguidores',
                                                ),
                                                const SizedBox(width: 10),
                                                buildContadorStream(
                                                  collection: 'productos',
                                                  whereField: 'userid',
                                                  equalTo: _user?.uid ?? '',
                                                  label: 'Productos',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(
                                        left: 22, right: 22),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          0, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      _empresaDescripcion,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 15.1,
                                      ),
                                      textAlign: TextAlign.start,
                                    ).redacted(
                                      context: context,
                                      redact: _isRedacted,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  if (!_isRedacted)
                                    StreamBuilder<DocumentSnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('empresa')
                                          .doc(_user!.uid)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        final theme = Theme.of(context);
                                        final isDark =
                                            theme.brightness == Brightness.dark;

                                        if (!snapshot.hasData ||
                                            !snapshot.data!.exists) {
                                          return const SizedBox();
                                        }

                                        final data = snapshot.data!.data()
                                            as Map<String, dynamic>?;
                                        if (data == null)
                                          return const SizedBox();

                                        final direccionE = data['direccionE'];

                                        final datosCompletos = data['userid'] !=
                                                null &&
                                            data['nombre'] != null &&
                                            data['descripcion'] != null &&
                                            direccionE != null &&
                                            data['telefono'] != null &&
                                            data['perfilEmpresa'] != null &&
                                            data['nombre']
                                                .toString()
                                                .trim()
                                                .isNotEmpty &&
                                            data['descripcion']
                                                .toString()
                                                .trim()
                                                .isNotEmpty &&
                                            direccionE['ubicacion'] != null &&
                                            direccionE['ubicacion']
                                                .toString()
                                                .trim()
                                                .isNotEmpty &&
                                            direccionE['referencia'] != null &&
                                            direccionE['referencia']
                                                .toString()
                                                .trim()
                                                .isNotEmpty &&
                                            direccionE['distrito'] != null &&
                                            direccionE['distrito']
                                                .toString()
                                                .trim()
                                                .isNotEmpty &&
                                            direccionE['tipo_local'] != null &&
                                            direccionE['tipo_local']
                                                .toString()
                                                .trim()
                                                .isNotEmpty &&
                                            direccionE['horario_atencion'] !=
                                                null &&
                                            direccionE['horario_atencion']
                                                .toString()
                                                .trim()
                                                .isNotEmpty &&
                                            data['telefono']
                                                .toString()
                                                .trim()
                                                .isNotEmpty &&
                                            data['ruc']
                                                .toString()
                                                .trim()
                                                .isNotEmpty &&
                                            data['perfilEmpresa']
                                                .toString()
                                                .trim()
                                                .isNotEmpty;

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                    height: 45,
                                                    child: TextButton.icon(
                                                      onPressed: () {
                                                        navegarConSlideDerecha(
                                                            context,
                                                            DatosEmpresa());
                                                      },
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor: isDark
                                                            ? Colors
                                                                .grey.shade800
                                                            : Colors
                                                                .grey.shade200,
                                                        foregroundColor: theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.color,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 14,
                                                                vertical: 10),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  12), // esquinas suaves
                                                        ),
                                                        elevation:
                                                            0, // sin sombra
                                                      ),
                                                      icon: Icon(
                                                        Iconsax.edit,
                                                        size: 20,
                                                        color: theme
                                                            .iconTheme.color,
                                                      ),
                                                      label: Text(
                                                        'Editar perfil',
                                                        style: theme.textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    )),
                                              ),
                                              if (datosCompletos)
                                                const SizedBox(width: 10),
                                              if (datosCompletos)
                                                SizedBox(
                                                    width: 170,
                                                    height: 45,
                                                    child: TextButton.icon(
                                                      onPressed: () async {
                                                        final estado =
                                                            data['estado'] ??
                                                                'No activo';
                                                        final nuevoEstado =
                                                            estado == 'Activo'
                                                                ? 'No activo'
                                                                : 'Activo';

                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'empresa')
                                                            .doc(_user!.uid)
                                                            .update({
                                                          'estado': nuevoEstado
                                                        });
                                                      },
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor: isDark
                                                            ? Colors
                                                                .grey.shade800
                                                            : Colors
                                                                .grey.shade200,
                                                        foregroundColor: theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.color,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 14,
                                                                vertical: 10),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  12), // esquinas suaves
                                                        ),
                                                        elevation:
                                                            0, // sin sombra
                                                      ),
                                                      icon: Icon(
                                                        Icons.circle,
                                                        size: 10,
                                                        color: data['estado'] ==
                                                                'Activo'
                                                            ? Colors.green
                                                            : Colors.red,
                                                      ),
                                                      label: Text(
                                                        data['estado'] ==
                                                                'Activo'
                                                            ? 'Activo'
                                                            : 'No activo',
                                                        style: theme.textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontFamily: 'Afacad',
                                                        ),
                                                      ),
                                                    )),
                                            ],
                                          ).redacted(
                                            context: context,
                                            redact: _isRedacted,
                                          ),
                                        );
                                      },
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
                                                      _isSearching = false;
                                                    }),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        border: Border(),
                                                      ),
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
                                                                      ? const Color(
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
                                                                      ? const Color(
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
                                                                SizedBox(
                                                                    height:
                                                                        150),
                                                                Text(
                                                                  'Sube algunos de tus publicaciones',
                                                                  style: theme
                                                                      .textTheme
                                                                      .titleMedium
                                                                      ?.copyWith(
                                                                    fontSize:
                                                                        14,
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
                                                                SizedBox(
                                                                    height:
                                                                        150),
                                                                Text(
                                                                  'Sube algunos de tus productos',
                                                                  style: theme
                                                                      .textTheme
                                                                      .titleMedium
                                                                      ?.copyWith(
                                                                    fontSize:
                                                                        14,
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
              )),
          floatingActionButton: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('empresa')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data == null) return const SizedBox();

              final direccionE = data['direccionE'];

              final datosCompletos = data['userid'] != null &&
                  data['nombre'] != null &&
                  data['descripcion'] != null &&
                  direccionE != null &&
                  data['telefono'] != null &&
                  data['ruc'] != null &&
                  data['perfilEmpresa'] != null &&
                  data['nombre'].toString().trim().isNotEmpty &&
                  data['descripcion'].toString().trim().isNotEmpty &&
                  direccionE['ubicacion'] != null &&
                  direccionE['ubicacion'].toString().trim().isNotEmpty &&
                  direccionE['referencia'] != null &&
                  direccionE['referencia'].toString().trim().isNotEmpty &&
                  direccionE['distrito'] != null &&
                  direccionE['distrito'].toString().trim().isNotEmpty &&
                  direccionE['tipo_local'] != null &&
                  direccionE['tipo_local'].toString().trim().isNotEmpty &&
                  direccionE['horario_atencion'] != null &&
                  direccionE['horario_atencion'].toString().trim().isNotEmpty &&
                  data['telefono'].toString().trim().isNotEmpty &&
                  data['ruc'].toString().trim().isNotEmpty &&
                  data['perfilEmpresa'].toString().trim().isNotEmpty;

              if (!datosCompletos) {
                return BotonFlotanteConBadge(
                  mostrarBadge: true,
                  fondoColor: const Color(0xFFFFAF00),
                  iconColor: const Color.fromARGB(255, 0, 0, 0),
                  iconSize: 26,
                );
              }
              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('MetodoPago')
                    .where('userId', isEqualTo: userId)
                    .limit(1)
                    .get(),
                builder: (context, metodoPagoSnapshot) {
                  if (metodoPagoSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SizedBox();
                  }

                  final tieneMetodoPago =
                      metodoPagoSnapshot.data?.docs.isNotEmpty ?? false;
                  if (!tieneMetodoPago) {
                    return BotonFlotanteConBadge(
                      mostrarBadge: true,
                      fondoColor: const Color(0xFFFFAF00),
                      iconColor: const Color.fromARGB(255, 0, 0, 0),
                      iconSize: 26,
                    );
                  }
                  return const SizedBox();
                },
              );
            },
          ),
        ));
  }

  List<DocumentSnapshot> _productos1 = [];
  Widget _gridDeProductos(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _productos1.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: _isRedacted ? 0.63 : 0.54,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          var productoDoc = _productos1[index];
          final producto = _productos1[index].data() as Map<String, dynamic>;
          producto['id'] = productoDoc.id;
          final imagenes = List<String>.from(producto['imagenes'] ?? []);
          final double precioOriginal =
              double.tryParse(producto['precio'].toString()) ?? 0.0;
          final double descuento =
              double.tryParse(producto['descuento']?.toString() ?? '0') ?? 0.0;
          final bool hayDescuento = descuento > 0;
          final double precioConDescuento =
              precioOriginal * (1 - descuento / 100);

          return GestureDetector(
            onTap: () {
              navegarConSlideDerecha(
                context,
                DetalleProductoPage(
                  producto: producto,
                  desdeVisitaperfilScreen: true,
                  desdeVisitaperfilEmpresa: true,
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFFFFF).withOpacity(0.1),
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
                          BorderRadius.vertical(top: Radius.circular(12)),
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
                          SizedBox(height: 4),
                          if (!_isRedacted)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                (() {
                                  final desc = producto['descripcion'] ?? '';
                                  final trimmed = desc.length > 40
                                      ? desc.substring(0, 40) + '...'
                                      : desc;
                                  return trimmed;
                                })(),
                                style: theme.textTheme.titleMedium?.copyWith(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'S/ ${precioOriginal.toStringAsFixed(2)}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 13,
                                        decoration: TextDecoration.lineThrough,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ).redacted(
                                      context: context,
                                      redact: _isRedacted,
                                    ),
                                    Text(
                                      'S/ ${precioConDescuento.toStringAsFixed(2)}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              if (!hayDescuento)
                                Text(
                                  'S/ ${precioOriginal.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
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
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
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
    );
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
}
