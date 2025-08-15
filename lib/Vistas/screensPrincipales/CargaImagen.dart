import 'dart:io';

import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/FullScreenWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CargaImagenPage extends StatefulWidget {
  final String imageUrl;

  const CargaImagenPage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  _CargaImagenPageState createState() => _CargaImagenPageState();
}

class WaveClipperImagenes extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Define radio y centro del círculo
    double radius = size.shortestSide / 2;
    Offset center = Offset(size.width / 2, size.height / 2);

    // Dibuja una ola suave en la parte superior
    path.moveTo(0, center.dy - radius);
    path.quadraticBezierTo(
      size.width * 0.25,
      center.dy - radius - 1, // ola suave
      size.width * 0.5,
      center.dy - radius,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      center.dy - radius + 20,
      size.width,
      center.dy - radius,
    );

    // Suaviza la parte inferior y aumenta la altura de la curva
    path.lineTo(size.width, center.dy + radius - 30); // Aumenta la altura

    // Ajusta las curvas inferiores para que sean simétricas
    path.quadraticBezierTo(
      size.width * 2,
      center.dy + radius + 30, // Suaviza y hace simétrica la curva
      size.width / 3,
      center.dy + radius + 30, // Suaviza y hace simétrica la curva
    );

    path.quadraticBezierTo(
      0,
      center.dy + radius + 60, // Asegura que la curva sea simétrica
      0,
      center.dy + radius - 10, // Ajuste para que sea parejo
    );

    // Cierra el path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _CargaImagenPageState extends State<CargaImagenPage> {
  User? _user = FirebaseAuth.instance.currentUser;
  String? _firestoreProfileImageUrl;
  File? _imageFile;
  String _firestoreUsername = "";
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchFirestoreData();
  }

  Future<void> _fetchFirestoreData() async {
    if (_user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _firestoreProfileImageUrl = userDoc['profileImageUrl'];
            _firestoreUsername = userDoc['username'];
          });
        }
      } catch (e) {
        print("Error al obtener los datos de Firestore: $e");
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      return showCustomDialog(
        context: context,
        title: 'Imagen no seleccionada',
        message: 'Seleccione una imagen para continuar',
        confirmButtonText: 'Cerrar',
      );
    }

    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('images/${_user!.uid}/profile.png');

    try {
      // Borrar imagen previa (ignorar si no existe)
      await storageRef.delete().catchError((e) {
        debugPrint('No se encontró imagen anterior para borrar: $e');
      });

      // Subir imagen nueva
      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask;

      // Obtener URL pública
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Actualizar Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'profileImageUrl': downloadUrl,
        'updatedAt':
            FieldValue.serverTimestamp(), // opcional: tracking de actualización
      });

      // Mostrar éxito
      await showCustomDialog(
        context: context,
        title: 'Éxito',
        message: 'Imagen subida con éxito',
        confirmButtonText: 'Cerrar',
      );

      // Recargar datos
      _fetchFirestoreData();
    } on FirebaseException catch (e) {
      // Errores específicos de Firebase
      debugPrint('Firebase error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen: ${e.message}')),
      );
    } catch (e, stack) {
      // Otros errores
      debugPrint('Error inesperado: $e\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error inesperado.')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _showFullScreenImage(File? imageFile) async {
    final updatedImage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          initialImage: imageFile,
          firebaseImageUrl: _firestoreProfileImageUrl,
        ),
      ),
    );

    if (updatedImage != null && mounted) {
      setState(() {
        _imageFile = updatedImage;
      });
      await _uploadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isUploading,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          toolbarHeight: 40,
          backgroundColor: const Color(0xFFFAFAFA),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              Iconsax.arrow_left,
              color: Color.fromARGB(255, 0, 0, 0),
              size: 25,
            ),
            onPressed: () {
              if (!_isUploading) {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            '',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              height: 1.0,
              color: const Color.fromARGB(255, 237, 237, 237),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Fondo curvo inferior
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipPath(
                clipper: WaveClipperImagenes(),
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 255, 255, 255),
                        Color(0xFFFFAF00),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            Center(
              child: Container(
                width: 300,
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showFullScreenImage(_imageFile),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(25),
                              image: _imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_firestoreProfileImageUrl != null &&
                                          _firestoreProfileImageUrl!
                                              .trim()
                                              .isNotEmpty)
                                      ? DecorationImage(
                                          image: CachedNetworkImageProvider(
                                              _firestoreProfileImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                              color: Colors.grey[200],
                              border:
                                  Border.all(color: Colors.black, width: 1.5),
                            ),
                            child: _imageFile == null &&
                                    (_firestoreProfileImageUrl == null ||
                                        _firestoreProfileImageUrl!
                                            .trim()
                                            .isEmpty)
                                ? const Center(
                                    child: Icon(
                                      LucideIcons.user2,
                                      size: 100,
                                      color: Colors.black,
                                    ),
                                  )
                                : null,
                          ),
                          if (_isUploading)
                            Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.4),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFFAF00),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Iconsax.edit,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Toca la imagen para editar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 2,
                      width: double.infinity,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _firestoreUsername,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
