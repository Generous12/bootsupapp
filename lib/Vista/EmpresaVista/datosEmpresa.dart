import 'dart:convert';

import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/FullScreenWidget.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/menuBotones/fullWidthButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

import 'dart:io';
import 'package:iconsax/iconsax.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class DatosEmpresa extends StatefulWidget {
  const DatosEmpresa({Key? key}) : super(key: key);

  @override
  _DatosEmpresaState createState() => _DatosEmpresaState();
}

class _DatosEmpresaState extends State<DatosEmpresa> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _telefonoEController = TextEditingController();
  final TextEditingController _direccionEController = TextEditingController();
  final TextEditingController _rucController = TextEditingController();

  File? _imageFile;
  User? _user = FirebaseAuth.instance.currentUser;
  String? _userId;
  String? _perfilEmpresaUrl;
  bool _isLoading1 = false;

  @override
  void initState() {
    super.initState();
    _getUserId();
    _getEmpresaData();
  }

  Future<void> _getUserId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint("No user is logged in.");
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint("El usuario no existe en la colección 'users'.");
        return;
      }

      if (!mounted) return;

      setState(() {
        _userId = user.uid;
      });

      await _getEmpresaData(); // Llama después de obtener _userId
    } catch (e, stack) {
      debugPrint('Error al obtener el ID del usuario: $e');
      debugPrint('$stack');
    }
  }

  Future<void> _getEmpresaData() async {
    if (_userId == null) return;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('empresa').doc(_userId);

      final docSnapshot =
          await docRef.get(const GetOptions(source: Source.serverAndCache));

      if (!docSnapshot.exists) {
        debugPrint("No se encontraron datos de la empresa.");
        return;
      }

      final data = docSnapshot.data();
      if (data == null || !mounted) return;

      setState(() {
        _nombreController.text = data['nombre']?.toString() ?? '';
        _descripcionController.text = data['descripcion']?.toString() ?? '';
        _direccionEController.text = data['direccionE']?.toString() ?? '';
        _telefonoEController.text = data['telefono']?.toString() ?? '';
        _rucController.text = data['ruc']?.toString() ?? '';
        _perfilEmpresaUrl = data['perfilEmpresa']?.toString() ?? '';
      });
    } catch (e, stack) {
      debugPrint('❌ Error al obtener los datos de la empresa: $e');
      debugPrint('$stack');
    }
  }

  Future<Uint8List> convertImageToWebP(File file, {int quality = 90}) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      format: CompressFormat.webp,
      quality: quality,
      minWidth: 1080,
      minHeight: 1080,
    );
    if (result == null) throw Exception('No se pudo convertir a WebP');
    return result;
  }

  Future<void> _uploadImage() async {
    if (_imageFile != null && _userId != null) {
      setState(() {
        _isLoading1 = true;
      });

      try {
        String storagePath = 'images/$_userId/Empresa/profile.webp';
        Reference storageReference =
            FirebaseStorage.instance.ref().child(storagePath);

        try {
          await storageReference.delete();
          print('Imagen anterior de empresa borrada.');
        } catch (e) {
          print('No se encontró imagen anterior para borrar o error: $e');
        }

        // 👉 Convertir imagen a WebP antes de subir
        final Uint8List webpBytes = await convertImageToWebP(_imageFile!);

        UploadTask uploadTask = storageReference.putData(
          webpBytes,
          SettableMetadata(contentType: 'image/webp'),
        );

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        DocumentReference empresaRef =
            FirebaseFirestore.instance.collection('empresa').doc(_userId);
        await empresaRef.set({
          'userid': _userId,
          'perfilEmpresa': downloadUrl,
        }, SetOptions(merge: true));

        print('Imagen subida y Firestore actualizado con éxito.');
      } catch (e) {
        print('Error al subir la imagen: $e');
      } finally {
        setState(() {
          _isLoading1 = false;
        });
      }
    } else {
      DocumentReference empresaRef =
          FirebaseFirestore.instance.collection('empresa').doc(_userId);
      await empresaRef.set({
        'userid': _userId,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _showFullScreenImageEmpresa({
    File? imageFile,
    String? firebaseUrl,
  }) async {
    final updatedImage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          initialImage: imageFile,
          firebaseImageUrl: firebaseUrl,
        ),
      ),
    );

    if (updatedImage != null && mounted) {
      setState(() {
        _imageFile = updatedImage;
        _perfilEmpresaUrl = null;
      });

      await _uploadImage();
    }
  }

  Future<bool> verificarDatosEmpresaCompletos(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('empresa')
        .doc(userId)
        .get();

    if (!doc.exists) return false;

    final data = doc.data();
    final direccionE = data?['direccionE'];
    final datosEmpresaCompletos = data != null &&
        data['userid'] != null &&
        data['nombre'] != null &&
        data['descripcion'] != null &&
        direccionE != null &&
        data['telefono'] != null &&
        data['perfilEmpresa'] != null &&
        data['ruc'] != null &&
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

    if (!datosEmpresaCompletos) return false;

    final metodoPagoSnapshot = await FirebaseFirestore.instance
        .collection('MetodoPago')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    final tieneMetodoPago = metodoPagoSnapshot.docs.isNotEmpty;

    return tieneMetodoPago;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
        onWillPop: () async {
          return !_isLoading1;
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 48,
            titleSpacing: 0,
            centerTitle: true,
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
                color: theme.iconTheme.color,
                size: 25,
              ),
              onPressed: () {
                if (!_isLoading1) {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              'Perfil de la Empresa',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 20,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      await _showFullScreenImageEmpresa(
                        imageFile: _imageFile,
                        firebaseUrl: _perfilEmpresaUrl,
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              child: _imageFile != null
                                  ? Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: FileImage(_imageFile!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : (_perfilEmpresaUrl != null &&
                                          _perfilEmpresaUrl!.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            _perfilEmpresaUrl!,
                                            width: 200,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return const Center(
                                                child: SizedBox(
                                                  width: 50,
                                                  height: 50,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Color(0xFFFFC800),
                                                    strokeWidth: 3,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/empresa.png',
                                                width: 200,
                                                height: 200,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: AssetImage(
                                                  'assets/images/empresa.png'),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )),
                            ),
                            if (_isLoading1)
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFFC800),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FullWidthMenuTile(
                  option: MenuOption(
                    title: 'Nombre de empresa',
                    description: 'Agrega el nombre de tu empresa',
                    icon: Iconsax.global_edit,
                    onTap: () {
                      showCupertinoModalBottomSheet(
                        context: context,
                        expand: false, // true si quieres pantalla completa
                        builder: (context) => NombreEmpresaScreen(
                            userId: _userId ?? '',
                            nombrecontroller: _nombreController),
                      );
                    },
                  ),
                ),
                FullWidthMenuTile(
                  option: MenuOption(
                    title: 'Descripción',
                    description:
                        'Breve resumen de lo que ofrece tu marca o empresa',
                    icon: Iconsax.building_4,
                    onTap: () {
                      showCupertinoModalBottomSheet(
                        context: context,
                        expand: false, // true si quieres pantalla completa
                        builder: (context) => DescripcionEmpresaScreen(
                          userId: _userId ?? '',
                          descripcionController: _descripcionController,
                        ),
                      );
                    },
                  ),
                ),
                FullWidthMenuTile(
                  option: MenuOption(
                    title: 'Ubicación manual',
                    description:
                        'Especifica dirección y localización de tu empresa',
                    icon: Iconsax.location,
                    onTap: () {
                      showCupertinoModalBottomSheet(
                        context: context,
                        expand: false,
                        builder: (context) =>
                            UbicacionEmpresaScreen(userId: _userId ?? ''),
                      );
                    },
                  ),
                ),
                FullWidthMenuTile(
                  option: MenuOption(
                    title: 'Número de contacto',
                    description: 'Agrega un número de teléfono de la empresa',
                    icon: Iconsax.call,
                    onTap: () {
                      showCupertinoModalBottomSheet(
                        context: context,
                        expand: false,
                        builder: (context) => TelefonoEmpresaScreen(
                          userId: _userId ?? '',
                          telefonoController: _telefonoEController,
                        ),
                      );
                    },
                  ),
                ),
                FullWidthMenuTile(
                  option: MenuOption(
                    title: 'Numero de RUC',
                    description: 'Agrega numero de RUC de tu empresa',
                    icon: Iconsax.notification_status,
                    onTap: () {
                      showCupertinoModalBottomSheet(
                        context: context,
                        builder: (context) => RucEmpresaInputScreen(
                          userId: _userId ?? '',
                          rucController: _rucController,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 20.0),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('empresa')
                          .doc(_user!.uid)
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
                            direccionE['distrito']
                                .toString()
                                .trim()
                                .isNotEmpty &&
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

                        if (datosCompletos) return const SizedBox();

                        final theme = Theme.of(context);
                        final isDark = theme.brightness == Brightness.dark;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline,
                                  color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Completa todos los campos y sube una imagen de perfil. Una vez finalizado, la empresa será visible para los usuarios.',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: theme.textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}

class NombreEmpresaScreen extends StatefulWidget {
  final String userId;
  final TextEditingController nombrecontroller;

  const NombreEmpresaScreen({
    super.key,
    required this.userId,
    required this.nombrecontroller,
  });

  @override
  State<NombreEmpresaScreen> createState() => _NombreEmpresaScreenState();
}

class _NombreEmpresaScreenState extends State<NombreEmpresaScreen> {
  bool _isLoading = false;

  Future<void> uploadDescripcion() async {
    if (widget.nombrecontroller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La descripción no puede estar vacía.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('empresa')
          .doc(widget.userId)
          .set({
        'nombre': widget.nombrecontroller.text.trim(),
        'estado': "No activo"
      }, SetOptions(merge: true));

      await showCustomDialog(
        context: context,
        title: 'Éxito',
        message: 'Descripción guardada correctamente.',
        confirmButtonText: 'Cerrar',
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error al guardar la descripción: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar: $e',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Agregar nombre a la empresa",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: widget.nombrecontroller,
                    hintText: 'Ingresa nombre de la empresa',
                    maxLines: 1,
                    maxLength: 20,
                    showCounter: true,
                    isNumeric: false,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: theme.brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                          ),
                          child: Text(
                            "Cancelar",
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : uploadDescripcion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Guardar",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DescripcionEmpresaScreen extends StatefulWidget {
  final String userId;
  final TextEditingController descripcionController;

  const DescripcionEmpresaScreen({
    super.key,
    required this.userId,
    required this.descripcionController,
  });

  @override
  State<DescripcionEmpresaScreen> createState() =>
      _DescripcionEmpresaScreenState();
}

class _DescripcionEmpresaScreenState extends State<DescripcionEmpresaScreen> {
  bool _isLoading = false;

  Future<void> uploadDescripcion() async {
    if (widget.descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La descripción no puede estar vacía.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('empresa')
          .doc(widget.userId)
          .set({
        'descripcion': widget.descripcionController.text.trim(),
      }, SetOptions(merge: true));

      await showCustomDialog(
        context: context,
        title: 'Éxito',
        message: 'Descripción guardada correctamente.',
        confirmButtonText: 'Cerrar',
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error al guardar la descripción: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar: $e',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Agregar descripción de la empresa",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: widget.descripcionController,
                    hintText: 'Describe brevemente tu empresa',
                    maxLines: 5,
                    maxLength: 150,
                    showCounter: true,
                    isNumeric: false,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: theme.brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                          ),
                          child: Text(
                            "Cancelar",
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : uploadDescripcion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Guardar",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UbicacionEmpresaScreen extends StatefulWidget {
  final String userId;

  const UbicacionEmpresaScreen({super.key, required this.userId});

  @override
  State<UbicacionEmpresaScreen> createState() => _UbicacionEmpresaScreenState();
}

class _UbicacionEmpresaScreenState extends State<UbicacionEmpresaScreen> {
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  final List<String> distritos = ['Ica', 'Chincha', 'Pisco', 'Nazca', 'Palpa'];
  final List<String> tiposLocales = [
    'Tienda',
    'Oficina',
    'Taller',
    'Local mixto'
  ];
  final List<String> horarios = [
    '8am - 5pm',
    '9am - 6pm',
    '10am - 8pm',
    '24/7'
  ];

  String? _selectedDistrito;
  String? _selectedTipoLocal;
  String? _selectedHorario;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final doc = await FirebaseFirestore.instance
        .collection('empresa')
        .doc(widget.userId)
        .get();

    if (doc.exists) {
      final data = doc.data();
      final descripcion = data?['direccionE'];

      if (descripcion != null && descripcion is Map<String, dynamic>) {
        _ubicacionController.text = descripcion['ubicacion'] ?? '';
        _referenciaController.text = descripcion['referencia'] ?? '';
        _selectedDistrito = descripcion['distrito'];
        _selectedTipoLocal = descripcion['tipo_local'];
        _selectedHorario = descripcion['horario_atencion'];
        setState(() {});
      }
    }
  }

  Future<void> _guardarUbicacion() async {
    final direccion = _ubicacionController.text.trim();

    if (direccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La dirección no puede estar vacía.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('empresa')
          .doc(widget.userId)
          .set({
        'direccionE': {
          'ubicacion': direccion,
          'referencia': _referenciaController.text.trim(),
          'distrito': _selectedDistrito,
          'tipo_local': _selectedTipoLocal,
          'horario_atencion': _selectedHorario,
        },
      }, SetOptions(merge: true)); // merge para no sobreescribir otros campos

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Ubicación guardada'),
          content: const Text('Se ha guardado correctamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error al guardar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ubicacion de la empresa",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _ubicacionController,
                    hintText: 'Ej: Av. Grau 123, Ica, Perú',
                    maxLines: 2,
                    label: 'Dirección completa',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _referenciaController,
                    hintText: 'Frente a Plaza Vea',
                    label: 'Referencia o punto cercano',
                  ),
                  const SizedBox(height: 16),
                  Text('Distrito o zona comercial',
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 1,
                    children: distritos.map((distrito) {
                      final isSelected = _selectedDistrito == distrito;
                      return ChoiceChip(
                        label: Text(distrito),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedDistrito = distrito),
                        selectedColor:
                            theme.colorScheme.primary.withOpacity(0.8),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : theme.textTheme.bodyMedium?.color,
                        ),
                        backgroundColor: theme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey.shade400,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Tipo de local', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 1,
                    children: tiposLocales.map((tipo) {
                      final isSelected = _selectedTipoLocal == tipo;
                      return ChoiceChip(
                        label: Text(tipo),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedTipoLocal = tipo),
                        selectedColor:
                            theme.colorScheme.primary.withOpacity(0.8),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : theme.textTheme.bodyMedium?.color,
                        ),
                        backgroundColor: theme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey.shade400,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Horario de atención', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 1,
                    children: horarios.map((horario) {
                      final isSelected = _selectedHorario == horario;
                      return ChoiceChip(
                        label: Text(horario),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedHorario = horario),
                        selectedColor:
                            theme.colorScheme.primary.withOpacity(0.8),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : theme.textTheme.bodyMedium?.color,
                        ),
                        backgroundColor: theme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey.shade400,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: theme.brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                          ),
                          child: Text(
                            "Cancelar",
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _guardarUbicacion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Guardar",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TelefonoEmpresaScreen extends StatefulWidget {
  final String userId;
  final TextEditingController telefonoController;

  const TelefonoEmpresaScreen({
    super.key,
    required this.userId,
    required this.telefonoController,
  });

  @override
  State<TelefonoEmpresaScreen> createState() => _TelefonoEmpresaScreenState();
}

class _TelefonoEmpresaScreenState extends State<TelefonoEmpresaScreen> {
  bool _isLoading = false;

  Future<void> guardarTelefono() async {
    final telefono = widget.telefonoController.text.trim();

    if (telefono.isEmpty || telefono.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número inválido')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('empresa')
          .doc(widget.userId)
          .set({'telefono': telefono}, SetOptions(merge: true));

      await showCustomDialog(
        context: context,
        title: 'Teléfono guardado',
        message: 'El número se guardó correctamente.',
        confirmButtonText: 'Cerrar',
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error guardando teléfono: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Número de contacto",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: widget.telefonoController,
                  hintText: 'Ej: 987654321',
                  label: 'Teléfono',
                  maxLength: 9,
                  isNumeric: true,
                  showCounter: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: theme.brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                        ),
                        child: Text(
                          "Cancelar",
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : guardarTelefono,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Guardar",
                                style: TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RucEmpresaInputScreen extends StatefulWidget {
  final String userId;
  final TextEditingController rucController;

  const RucEmpresaInputScreen({
    super.key,
    required this.userId,
    required this.rucController,
  });

  @override
  State<RucEmpresaInputScreen> createState() => _RucEmpresaInputScreenState();
}

class _RucEmpresaInputScreenState extends State<RucEmpresaInputScreen> {
  bool _isLoading = false;
  Future<void> guardarRUC() async {
    final ruc = widget.rucController.text.trim();

    if (ruc.isEmpty || ruc.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RUC inválido. Debe tener 11 dígitos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final token = 'sk_9430.gQKCaD0rLlm5Ktx13v8fKsLV29i602Mo';

    try {
      // Verificar si el RUC ya existe en otra empresa
      final duplicateCheck = await FirebaseFirestore.instance
          .collection('empresa')
          .where('ruc', isEqualTo: ruc)
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
        final existingUserId = duplicateCheck.docs.first.id;
        if (existingUserId != widget.userId) {
          await showCustomDialog(
            context: context,
            title: 'RUC ya registrado',
            message:
                'Este RUC ya está en uso por otra empresa. Si crees que es un error, contáctanos.',
            confirmButtonText: 'Cerrar',
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // Validar el RUC con la SUNAT
      final uri =
          Uri.parse('https://api.decolecta.com/v1/sunat/ruc/full?numero=$ruc');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data != null && data is Map && data.isNotEmpty) {
          // Guardar el RUC y opcionalmente más datos de la empresa
          await FirebaseFirestore.instance
              .collection('empresa')
              .doc(widget.userId)
              .set({
            'ruc': ruc,
            'razon_social': data['razon_social'] ?? '',
            'estado': data['estado'] ?? '',
          }, SetOptions(merge: true));

          await showCustomDialog(
            context: context,
            title: 'RUC válido',
            message: 'El número de RUC es válido y se ha guardado.',
            confirmButtonText: 'Cerrar',
          );

          Navigator.pop(context);
        } else {
          await showCustomDialog(
            context: context,
            title: 'RUC no encontrado',
            message:
                'El RUC ingresado no existe en SUNAT. Verifica e intenta nuevamente.',
            confirmButtonText: 'Cerrar',
          );
        }
      } else {
        await showCustomDialog(
          context: context,
          title: 'Error de búsqueda',
          message: 'No se pudo validar el RUC. Intenta más tarde.',
          confirmButtonText: 'Cerrar',
        );
      }
    } catch (e) {
      print('Error guardando RUC: $e');
      await showCustomDialog(
        context: context,
        title: 'Error de conexión',
        message: 'Ocurrió un error al conectar con SUNAT: $e',
        confirmButtonText: 'Cerrar',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Número de RUC",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: widget.rucController,
                  hintText: 'Ej: 20123456789',
                  label: 'RUC',
                  maxLength: 11,
                  isNumeric: true,
                  showCounter: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: theme.brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                        ),
                        child: Text(
                          "Cancelar",
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : guardarRUC,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Guardar",
                                style: TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0)),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
