import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:redacted/redacted.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;

class Gestionpublicaciones extends StatefulWidget {
  @override
  _GestionpublicacionesState createState() => _GestionpublicacionesState();
}

class _GestionpublicacionesState extends State<Gestionpublicaciones> {
  List<Map<String, dynamic>> _publicaciones = [];
  List<Map<String, String>> _empresas = []; // Lista para almacenar las empresas
  bool _isRedacted = true;
  bool _isUploading = false;
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _fetchAndRedactPublicaciones();
  }

  Future<void> _eliminarPublicacion(int index) async {
    final publicacion = _publicaciones[index];

    final String? publicacionId = publicacion['id'];
    final List<dynamic>? imagenes = publicacion['imagenes'];
    if (!mounted) return;
    if (publicacionId == null) {
      print('No se pudo obtener el ID de la publicación.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _isUploading = true;
    });

    try {
      if (imagenes != null && imagenes.isNotEmpty) {
        await Future.wait(imagenes.cast<String>().map((url) async {
          try {
            final ref = FirebaseStorage.instance.refFromURL(url);
            await ref.delete();
          } catch (e) {
            print("Error eliminando imagen $url: $e");
          }
        }));
      }

      // Eliminar documento Firestore
      await FirebaseFirestore.instance
          .collection('publicaciones')
          .doc(publicacionId)
          .delete();

      await showCustomDialog(
        context: context,
        title: 'Éxito',
        message: 'Publicación eliminada con éxito',
        confirmButtonText: 'Cerrar',
      );

      if (!mounted) return;
      setState(() {
        _publicaciones.removeAt(index);
      });
    } catch (e) {
      print('Error al eliminar publicación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar publicación.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _fetchPublicacionesDelUsuarioActual() async {
    try {
      QuerySnapshot empresasSnapshot = await FirebaseFirestore.instance
          .collection('empresa')
          .where('userid', isEqualTo: _currentUserId)
          .get();

      List<String> empresaIds =
          empresasSnapshot.docs.map((doc) => doc.id).toList();
      if (!mounted) return;
      if (empresaIds.isEmpty) {
        setState(() {
          _publicaciones = [];
        });
        print('No se encontraron empresas para el usuario actual.');
        return;
      }

      List<Map<String, dynamic>> publicacionesTotales = [];
      const int chunkSize = 10;

      for (var i = 0; i < empresaIds.length; i += chunkSize) {
        var chunk = empresaIds.sublist(
            i,
            i + chunkSize > empresaIds.length
                ? empresaIds.length
                : i + chunkSize);

        QuerySnapshot publicacionesSnapshot = await FirebaseFirestore.instance
            .collection('publicaciones')
            .where('publicacionDeEmpresa', whereIn: chunk)
            .get();

        publicacionesTotales.addAll(publicacionesSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'publicacion': data['publicacionDeEmpresa']?.toString() ??
                'Publicación sin empresa asociada',
            'descripcion': data['descripcion']?.toString() ?? '',
            'imagenes': data['imagenes'] ?? [],
            'fecha': data['fecha'] != null
                ? (data['fecha'] as Timestamp).toDate()
                : null,
            'imageRatio': data['imageRatio'] != null
                ? {
                    'width': (data['imageRatio']['width'] ?? 1.0).toDouble(),
                    'height': (data['imageRatio']['height'] ?? 1.0).toDouble(),
                  }
                : {'width': 1.0, 'height': 1.0},
          };
        }).toList());
      }
      if (!mounted) return;
      setState(() {
        _publicaciones = publicacionesTotales;
      });

      print('Publicaciones del usuario cargadas: ${_publicaciones.length}');
    } catch (e) {
      print('Error al cargar publicaciones: $e');
    }
  }

  Future<void> _fetchEmpresas() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('empresa').get();
      if (!mounted) return;
      setState(() {
        _empresas = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'userid':
                data.containsKey('userid') ? data['userid'].toString() : '',
            'nombre': data.containsKey('nombre')
                ? data['nombre'].toString()
                : 'Nombre no disponible',
            'perfilEmpresa': data.containsKey('perfilEmpresa')
                ? data['perfilEmpresa'].toString()
                : '',
          };
        }).toList();
      });

      print('Empresas cargadas: ${_empresas.length}');
    } catch (e) {
      print('Error al cargar empresas: $e');
    }
  }

  void _fetchAndRedactPublicaciones() async {
    if (!mounted) return;
    setState(() {
      _isRedacted = true;
      _isUploading = true;
    });

    final stopwatch = Stopwatch()..start();

    await Future.wait([
      _fetchPublicacionesDelUsuarioActual(),
      _fetchEmpresas(),
    ]);

    final elapsed = stopwatch.elapsed;
    const minDuration = Duration(seconds: 1);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }
    if (!mounted) return;
    setState(() {
      _isRedacted = false;
      _isUploading = false;
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
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 48,
        centerTitle: true,
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
        title: Text(
          'Gestiona tus publicaciones',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            color: theme.textTheme.bodyLarge?.color,
          ),
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
      ),
      body: _isUploading
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
              color: Color(0xFFFFAF00),
              size: 50,
            ))
          : _publicaciones.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/nopublicacion.png', // Asegúrate de tener esta imagen
                          height: 200,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No hay publicaciones aún',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Cuando se publique contenido aparecerá aquí.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _publicaciones.length,
                  itemBuilder: (context, index) {
                    final publicacion = _publicaciones[index];

                    final empresa = _empresas.firstWhere(
                      (e) => e['id'] == publicacion['publicacionDeEmpresa'],
                      orElse: () => {
                        'nombre': 'Empresa desconocida',
                        'perfilEmpresa': '',
                      },
                    );

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            0), // Puedes cambiar 16 por lo que desees
                      ),
                      color: theme.cardColor,
                      margin:
                          EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                      child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 15),
                            Stack(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor: const Color(0xFFFAFAFA),
                                      child: ClipOval(
                                        child: (empresa['perfilEmpresa'] !=
                                                    null &&
                                                empresa['perfilEmpresa']!
                                                    .toString()
                                                    .isNotEmpty)
                                            ? Image.network(
                                                empresa['perfilEmpresa']!,
                                                fit: BoxFit.cover,
                                                width: 50,
                                                height: 50,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
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
                                                      strokeWidth: 2.0,
                                                      color: Color(0xFFFFAF00),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/empresa.png',
                                                    fit: BoxFit.cover,
                                                    width: 50,
                                                    height: 50,
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
                                                width: 50,
                                                height: 50,
                                              ).redacted(
                                                context: context,
                                                redact: _isRedacted,
                                              ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              empresa['nombre'] ?? 'Empresa',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontSize: 16,
                                                color: theme
                                                    .textTheme.bodyLarge?.color,
                                              ),
                                            ).redacted(
                                              context: context,
                                              redact: _isRedacted,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              publicacion['fecha'] != null
                                                  ? timeago.format(
                                                      publicacion['fecha'],
                                                      locale: 'es')
                                                  : 'Sin fecha',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontSize: 12,
                                                color: theme
                                                    .textTheme.bodyLarge?.color,
                                              ),
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
                                Positioned(
                                  top: 0,
                                  right: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 0, 0, 0)
                                          .withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.close,
                                          color: Colors.white, size: 30),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      onPressed: () async {
                                        await showCustomDialog(
                                          context: context,
                                          title: 'Eliminar publicacion',
                                          message:
                                              '¿Estás seguro que deseas continuar?',
                                          confirmButtonText: 'Sí',
                                          cancelButtonText: 'No',
                                          confirmButtonColor: Colors.red,
                                          cancelButtonColor: Colors.blue,
                                        ).then((confirmed) {
                                          if (confirmed != null && confirmed) {
                                            setState(() {
                                              _eliminarPublicacion(index);
                                            });
                                          }
                                          return null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 18),
                            Text(
                              publicacion['descripcion'] ?? '',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 14,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                              textAlign: TextAlign.justify,
                            ).redacted(
                              context: context,
                              redact: _isRedacted,
                            ),
                            SizedBox(height: 12),
                            if (publicacion['imagenes'] != null &&
                                publicacion['imagenes'] is List &&
                                (publicacion['imagenes'] as List).isNotEmpty)
                              Builder(
                                builder: (context) {
                                  final List imagenes = publicacion['imagenes'];
                                  final PageController _pageController =
                                      PageController();
                                  final ratio = publicacion['imageRatio'] ??
                                      {'width': 1.0, 'height': 1.0};
                                  final aspectRatio = (ratio['width'] ?? 1.0) /
                                      (ratio['height'] ?? 1.0);
                                  return Column(
                                    children: [
                                      AspectRatio(
                                        aspectRatio: aspectRatio,
                                        child: PageView.builder(
                                          controller: _pageController,
                                          itemCount: imagenes.length,
                                          itemBuilder: (context, imgIndex) {
                                            final String imageUrl =
                                                imagenes[imgIndex];

                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(0),
                                              child: imageUrl.isNotEmpty
                                                  ? Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) return child;
                                                        return Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            color: Color(
                                                                0xFFFFAF00),
                                                            strokeWidth: 2.5,
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Image.asset(
                                                          'assets/images/empresa.png',
                                                          fit: BoxFit.cover,
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
                                                    ).redacted(
                                                      context: context,
                                                      redact: _isRedacted,
                                                    ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SmoothPageIndicator(
                                        controller: _pageController,
                                        count: imagenes.length,
                                        effect: ScaleEffect(
                                          activeDotColor: Color(0xFFFFAF00),
                                          dotColor: Colors.grey.shade400,
                                          dotHeight: 8,
                                          dotWidth: 8,
                                          spacing: 6,
                                          scale: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
