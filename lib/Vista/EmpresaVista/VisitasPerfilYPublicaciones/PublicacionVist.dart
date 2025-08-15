import 'package:bootsup/Modulos/ModuloPublicaciones/Moduloinicio.dart';
import 'package:bootsup/Vista/EmpresaVista/VisitasPerfilYPublicaciones/todoLosProductos.dart';
import 'package:bootsup/Vistas/detalleproducto/ComentariosScreen/Comentarios.dart';
import 'package:bootsup/Vistas/screensPrincipales/inicio.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;

class PublicacionVista extends StatefulWidget {
  final Map<String, dynamic> publicacionData;

  const PublicacionVista({Key? key, required this.publicacionData})
      : super(key: key);

  @override
  State<PublicacionVista> createState() => _PublicacionVistaState();
}

class _PublicacionVistaState extends State<PublicacionVista> {
  List<Map<String, dynamic>> _otrasPublicaciones = [];
  Map<String, dynamic>? _empresaData;
  final _firestoreService = FirestoreService();
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _fetchEmpresaData();
    _fetchAndRedactPublicacionesDelUsuario();
  }

  List<DocumentSnapshot> _productos = [];

  Future<void> _fetchEmpresaData() async {
    final String idUserEmpresa =
        widget.publicacionData['publicacionDeEmpresa'] ?? '';

    print('idUserEmpresa: $idUserEmpresa');
    if (idUserEmpresa.isEmpty) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('empresa')
          .where('userid', isEqualTo: idUserEmpresa)
          .limit(1)
          .get();
      print('Docs encontrados: ${querySnapshot.docs.length}');
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _empresaData = querySnapshot.docs.first.data();
        });
      }
    } catch (e) {
      print('Error al cargar datos de empresa: $e');
    }
  }

  Future<void> _fetchAndRedactPublicacionesDelUsuario() async {
    if (!mounted) return;

    final String idEmpresa =
        widget.publicacionData['publicacionDeEmpresa'] ?? '';
    final userId = FirebaseAuth.instance.currentUser!.uid;

    if (idEmpresa.isEmpty) return;

    try {
      // 🔹 Actualizar la publicación seleccionada
      try {
        final String? publicacionId = widget.publicacionData['docRef']?.id ??
            widget.publicacionData['id'];

        if (publicacionId != null && userId.isNotEmpty) {
          final docRef = FirebaseFirestore.instance
              .collection('publicaciones')
              .doc(publicacionId);

          final List<dynamic> resultados = await Future.wait([
            docRef.collection('meGustas').get(),
            docRef.collection('comentarios').get(),
            docRef.collection('meGustas').doc(userId).get(),
          ]);

          final QuerySnapshot meGustasSnap = resultados[0] as QuerySnapshot;
          final QuerySnapshot comentariosSnap = resultados[1] as QuerySnapshot;
          final DocumentSnapshot dioLikeSnap =
              resultados[2] as DocumentSnapshot;

          widget.publicacionData['cantidadMeGustas'] = meGustasSnap.size;
          widget.publicacionData['cantidadComentarios'] = comentariosSnap.size;
          widget.publicacionData['dioLike'] = dioLikeSnap.exists;
          widget.publicacionData['docRef'] = docRef;
        }
      } catch (e) {
        print('❌ Error al cargar datos de la publicación seleccionada: $e');
      }

      // 🔹 Obtener publicaciones de la empresa
      final snapshot = await FirebaseFirestore.instance
          .collection('publicaciones')
          .where('publicacionDeEmpresa', isEqualTo: idEmpresa)
          .get();

      List<Future<Map<String, dynamic>>> tareas = [];

      for (var doc in snapshot.docs) {
        tareas.add(() async {
          final data = doc.data();

          final List<dynamic> resultados = await Future.wait([
            doc.reference.collection('meGustas').get(),
            doc.reference.collection('comentarios').get(),
            doc.reference.collection('meGustas').doc(userId).get(),
          ]);

          final QuerySnapshot meGustasSnap = resultados[0] as QuerySnapshot;
          final QuerySnapshot comentariosSnap = resultados[1] as QuerySnapshot;
          final DocumentSnapshot dioLikeSnap =
              resultados[2] as DocumentSnapshot;

          return {
            'titulo': data['titulo'] ?? 'Sin título',
            'descripcion': data['descripcion'] ?? '',
            'imagenes': data['imagenes'] ?? [],
            'fecha': data['fecha'] != null
                ? (data['fecha'] as Timestamp).toDate()
                : null,
            'userid': data['userid'] ?? '',
            'fotoEmpresa': data['fotoEmpresa'] ?? '',
            'nombreEmpresa': data['nombreEmpresa'] ?? 'Empresa',
            'imageRatio': data['imageRatio'] != null
                ? Map<String, dynamic>.from(data['imageRatio'])
                : {},
            'cantidadMeGustas': meGustasSnap.size,
            'cantidadComentarios': comentariosSnap.size,
            'dioLike': dioLikeSnap.exists,
            'docRef': doc,
          };
        }());
      }

      final publicaciones = await Future.wait(tareas);

      if (!mounted) return;
      setState(() {
        _otrasPublicaciones = publicaciones
            .where((pub) =>
                pub['descripcion'] != widget.publicacionData['descripcion'])
            .toList();
        _productos = _productos;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar publicaciones de la empresa: $e');
    }
  }

  Widget _buildPublicacionCard(Map<String, dynamic> publicacion) {
    final theme = Theme.of(context);

    if (_empresaData == null) {
      return const SizedBox.shrink();
    }
    final String? publicacionId = publicacion['docRef']?.id;
    final String nombre = _empresaData?['nombre'] ?? 'Empresa';
    final String foto = _empresaData?['perfilEmpresa'] ?? '';
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    DateTime? fecha;
    try {
      fecha = publicacion['fecha'] is DateTime
          ? publicacion['fecha']
          : (publicacion['fecha'] != null
              ? DateTime.parse(publicacion['fecha'].toString())
              : null);
    } catch (_) {
      fecha = null;
    }

    final List<dynamic> imagenes =
        (publicacion['imagenes'] is List) ? publicacion['imagenes'] : [];

    final PageController _pageController = PageController();
    return Card(
        elevation: 0,
        color: theme.scaffoldBackgroundColor,
        margin: const EdgeInsets.symmetric(vertical: 15),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        child: ClipOval(
                          child: (foto.isNotEmpty)
                              ? Image.network(
                                  foto,
                                  width: 50,
                                  height: 50,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2.0,
                                        color: const Color(0xFFFFC800),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/empresa.png',
                                      fit: BoxFit.cover,
                                      width: 50,
                                      height: 50,
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/images/empresa.png',
                                  fit: BoxFit.cover,
                                  width: 50,
                                  height: 50,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fecha != null
                                  ? timeago.format(fecha, locale: 'es')
                                  : 'Sin fecha',
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    publicacion['descripcion'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (imagenes.isNotEmpty)
                    Column(
                      children: [
                        Builder(builder: (context) {
                          final Map<String, dynamic> imageRatio =
                              (publicacion['imageRatio']
                                      is Map<String, dynamic>)
                                  ? Map<String, dynamic>.from(
                                      publicacion['imageRatio'])
                                  : {'width': 1.0, 'height': 1.0};

                          final double screenWidth =
                              MediaQuery.of(context).size.width;

                          final double widthRatio =
                              (imageRatio['width'] ?? 1.0).toDouble();
                          final double heightRatio =
                              (imageRatio['height'] ?? 1.0).toDouble();

                          final double imageHeight =
                              screenWidth * (heightRatio / widthRatio);

                          return SizedBox(
                            width: screenWidth,
                            height: imageHeight,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: imagenes.length,
                              itemBuilder: (context, imgIndex) {
                                final String imageUrl = imagenes[imgIndex];

                                return SizedBox(
                                  width: screenWidth,
                                  height: imageHeight,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(0),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color:
                                                      const Color(0xFFFFC800),
                                                  strokeWidth: 2.5,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/empresa.png',
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            'assets/images/empresa.png',
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  const SizedBox(height: 5),
                  Material(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (userId == null || publicacionId == null)
                                return;

                              final dioLikeActual = await _firestoreService
                                  .haDadoMeGusta(publicacionId, userId);

                              if (dioLikeActual) {
                                await _firestoreService.quitarMeGusta(
                                    publicacionId, userId);
                                publicacion['cantidadMeGustas'] =
                                    (publicacion['cantidadMeGustas'] ?? 1) - 1;
                                publicacion['dioLike'] = false;
                              } else {
                                await _firestoreService.darMeGusta(
                                    publicacionId, userId);
                                publicacion['cantidadMeGustas'] =
                                    (publicacion['cantidadMeGustas'] ?? 0) + 1;
                                publicacion['dioLike'] = true;
                              }

                              setState(() {});
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.flash,
                                  size: 28,
                                  color: publicacion['dioLike'] == true
                                      ? Color(0xFFFFAF00)
                                      : theme.iconTheme.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (publicacion['cantidadMeGustas'] ?? 0)
                                      .toString(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          GestureDetector(
                            onTap: () {
                              showBarModalBottomSheet(
                                context: context,
                                expand: true,
                                builder: (context) => ComentariosScreen(
                                  publicacionId: publicacionId!,
                                  userId: userId!,
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(LucideIcons.messageCircle, size: 28),
                                const SizedBox(width: 6),
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('publicaciones')
                                      .doc(publicacionId)
                                      .collection('comentarios')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Text(
                                        '...',
                                        style: TextStyle(fontSize: 16),
                                      );
                                    }

                                    final cantidadComentarios =
                                        snapshot.data!.docs.length;

                                    return Text(
                                      cantidadComentarios.toString(),
                                      style: const TextStyle(fontSize: 16),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          GestureDetector(
                            onTap: () {
                              navegarConSlideDerecha(
                                context,
                                TodosLosProductosPage(
                                  empresaUserId: _empresaData!['userid'],
                                  productosPasados: _productos,
                                  desdePublicaciones: true,
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(Iconsax.box, size: 28),
                                const SizedBox(width: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: imagenes.length,
                  effect: JumpingDotEffect(
                    activeDotColor: Color(0xFFFFAF00),
                    dotColor: Color.fromARGB(255, 126, 126, 126),
                    dotHeight: 8,
                    dotWidth: 8,
                    spacing: 6,
                    jumpScale: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final publicacion = widget.publicacionData;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
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
          icon: Icon(Iconsax.arrow_left, size: 25),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Publicaciones'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Publicación principal
            _buildPublicacionCard(publicacion),

            // Título para otras publicaciones
            if (!_isLoading && _otrasPublicaciones.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Otras publicaciones de este usuario',
                  style: TextStyle(fontSize: 18),
                ),
              ),

            // Mostrar carga o lista
            if (_isLoading)
              Column(
                children: const [
                  RedactedPublicacion(),
                  SizedBox(height: 12),
                  RedactedPublicacion(),
                  SizedBox(height: 12),
                  RedactedPublicacion(),
                ],
              )
            else
              Column(
                children: _otrasPublicaciones
                    .map((pub) => _buildPublicacionCard(pub))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
