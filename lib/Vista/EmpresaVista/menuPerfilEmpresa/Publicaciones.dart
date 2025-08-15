import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:bootsup/widgets/BotonesSeleccionables.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:flutter/material.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:pro_image_editor/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/core/models/editor_configs/pro_image_editor_configs.dart';
import 'package:pro_image_editor/features/main_editor/main_editor.dart';

class PublicacionesPage extends StatefulWidget {
  @override
  _PublicacionesPageState createState() => _PublicacionesPageState();
}

class CropAspectRatioPresetCustom4x5 implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (4, 5); // relación 4:5 exacta

  @override
  String get name => '4x5';
}

class CropAspectRatioPresetCustom3x4 implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (3, 4); // relación 4:5 exacta

  @override
  String get name => '3x4';
}

class _PublicacionesPageState extends State<PublicacionesPage> {
  TextEditingController _descripcionController = TextEditingController();
  User? _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  double _aspectX = 1;
  double _aspectY = 1;

  final ImagePicker _picker = ImagePicker();
  File? _mainImage;
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File newImage = File(pickedFile.path);
      setState(() {
        _selectedImages.insert(0, newImage);
        _mainImage = newImage;
      });
    }
  }

  Future<void> _selectImageSource() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Iconsax.camera, color: Color(0xFFFFAF00)),
                title: const Text("Cámara"),
                onTap: () => Navigator.pop(ctx, true),
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery, color: Color(0xFFFFAF00)),
                title: const Text("Galería"),
                onTap: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      await _pickImage(result ? ImageSource.camera : ImageSource.gallery);
    }
  }

  Future<File> _convertBytesToFile(Uint8List bytes) async {
    final directory = await Directory.systemTemp.createTemp();
    final filePath = '${directory.path}/edited_image.png';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }

  void _showFullScreenImage(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // 💫 FILTRO DIFUSO (esto desenfoca lo anterior)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    color:
                        const ui.Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
                  ),
                ),
              ),
              Center(child: Image.file(imageFile)),

              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      LucideIcons.minimize,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: const ui.Color.fromARGB(255, 0, 0, 0),
                      radius: 30,
                      child: IconButton(
                        icon: Icon(Iconsax.edit,
                            color: const ui.Color(0xFFFFAF00)),
                        onPressed: () async {
                          final bytes = await imageFile.readAsBytes();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProImageEditor.memory(
                                bytes,
                                configs: const ProImageEditorConfigs(
                                  cropRotateEditor: CropRotateEditorConfigs(
                                    enabled: false,
                                  ),
                                  i18n: I18n(
                                    various: I18nVarious(
                                      closeEditorWarningTitle: "Advertencia",
                                      closeEditorWarningMessage:
                                          "¿Desea descartar los cambios realizados?",
                                      loadingDialogMsg: "Aplicando cambios",
                                    ),
                                  ),
                                ),
                                callbacks: ProImageEditorCallbacks(
                                  onImageEditingComplete:
                                      (Uint8List editedImage) async {
                                    File editedFile =
                                        await _convertBytesToFile(editedImage);
                                    setState(() {
                                      int index =
                                          _selectedImages.indexOf(imageFile);
                                      if (index != -1) {
                                        _selectedImages[index] = editedFile;
                                      }
                                      if (_mainImage?.path == imageFile.path) {
                                        _mainImage = editedFile;
                                      }
                                    });
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 30),
                    CircleAvatar(
                      backgroundColor: const ui.Color.fromARGB(255, 0, 0, 0),
                      radius: 30,
                      child: IconButton(
                        icon: Icon(Iconsax.crop,
                            color: const ui.Color(0xFFFFAF00)),
                        onPressed: () async {
                          try {
                            final croppedFile = await ImageCropper().cropImage(
                              sourcePath: imageFile.path,
                              compressFormat: ImageCompressFormat.jpg,
                              compressQuality: 100,
                              aspectRatio: CropAspectRatio(
                                ratioX: _aspectX,
                                ratioY: _aspectY,
                              ),
                              uiSettings: [
                                AndroidUiSettings(
                                  toolbarTitle: 'Cropper',
                                  toolbarColor: const Color(0xFFFFAF00),
                                  toolbarWidgetColor: Colors.white,
                                  lockAspectRatio: true,
                                  hideBottomControls: false,
                                  showCropGrid: true,
                                  initAspectRatio:
                                      CropAspectRatioPreset.original,
                                  aspectRatioPresets: [
                                    CropAspectRatioPreset.square,
                                    CropAspectRatioPreset.original,
                                    CropAspectRatioPresetCustom4x5(),
                                    CropAspectRatioPresetCustom3x4(), // Aquí usas tu preset personalizado
                                  ],
                                ),
                              ],
                            );

                            if (croppedFile != null) {
                              final File newImageFile = File(croppedFile.path);

                              setState(() {
                                int index = _selectedImages.indexOf(imageFile);
                                if (index != -1) {
                                  _selectedImages[index] = newImageFile;
                                }

                                if (_mainImage?.path == imageFile.path) {
                                  _mainImage = File(newImageFile.path);
                                }
                              });

                              Navigator.pop(context);
                            }
                          } catch (e) {
                            print("Error al recortar imagen: $e");
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<bool> _isImageAspectRatioValid(
      File imageFile, double aspectX, double aspectY) async {
    final bytes = await imageFile.readAsBytes();
    final image = await decodeImageFromList(bytes);
    final width = image.width;
    final height = image.height;

    double imageAspectRatio = width / height;
    double targetAspectRatio = aspectX / aspectY;

    const double tolerance = 0.05; // permite un margen de error del 5%

    return (imageAspectRatio - targetAspectRatio).abs() <= tolerance;
  }

  Future<void> _uploadPublicationImages(String _userId) async {
    List<String> errores = [];

    if (_descripcionController.text.isEmpty) {
      errores.add('Completa todos los campos obligatorios.');
    }

    if (_selectedImages.isEmpty) {
      errores.add('Selecciona al menos una imagen.');
    } else {
      for (File imageFile in _selectedImages) {
        bool isValid = await _isImageAspectRatioValid(
          imageFile,
          _aspectX,
          _aspectY,
        );
        if (!isValid) {
          errores.add(
              'Todas las imágenes deben tener proporción $_aspectX:$_aspectY.');
          break;
        }
      }
    }

    if (errores.isNotEmpty) {
      await showCustomDialog(
        context: context,
        title: 'Revisa tu formulario',
        message: errores.join('\n'),
        confirmButtonText: 'Cerrar',
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      String descripcion = _descripcionController.text;
      List<String> downloadUrls = [];

      for (File imageFile in _selectedImages.take(4)) {
        final Uint8List webpBytes =
            await convertImageToWebP(imageFile, quality: 90);

        String storagePath =
            'images/$_userId/Empresa/publicaciones/${DateTime.now().millisecondsSinceEpoch}.webp';

        Reference storageReference =
            FirebaseStorage.instance.ref().child(storagePath);

        UploadTask uploadTask = storageReference.putData(
          webpBytes,
          SettableMetadata(contentType: 'image/webp'),
        );

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      DocumentReference publicationRef =
          FirebaseFirestore.instance.collection('publicaciones').doc();

      await publicationRef.set({
        'publicacionDeEmpresa': _userId,
        'imagenes': downloadUrls,
        'descripcion': descripcion,
        'fecha': FieldValue.serverTimestamp(),
        'megusta': null,
        'Comentarios': null,
        'imageRatio': {
          'width': _aspectX,
          'height': _aspectY,
        },
      });

      await showCustomDialog(
        context: context,
        title: 'Éxito',
        message: 'Publicación subida con éxito',
        confirmButtonText: 'Cerrar',
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error al subir: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir la publicación.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void verificarYMostrarDialogo() async {
    final hayDescripcion = _descripcionController.text.trim().isNotEmpty;
    final hayImagenPrincipal = _mainImage != null;
    final hayImagenesSeleccionadas = _selectedImages.isNotEmpty;

    if (hayDescripcion || hayImagenPrincipal || hayImagenesSeleccionadas) {
      bool? result = await showCustomDialog(
        context: context,
        title: 'Aviso',
        message: '¿Estás seguro? Si sales ahora, perderás tu progreso.',
        confirmButtonText: 'Sí, salir',
        cancelButtonText: 'No',
        confirmButtonColor: Colors.red,
        cancelButtonColor: const Color.fromARGB(255, 0, 0, 0),
      );

      if (result == true) {
        if (mounted) {
          Navigator.pop(context); // Salir de la pantalla
        }
      }
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
        onWillPop: () async {
          if (_isLoading) {
            return false;
          }
          final hayDescripcion = _descripcionController.text.trim().isNotEmpty;
          final hayImagenPrincipal = _mainImage != null;
          final hayImagenesSeleccionadas = _selectedImages.isNotEmpty;

          if (hayDescripcion ||
              hayImagenPrincipal ||
              hayImagenesSeleccionadas) {
            bool? result = await showCustomDialog(
              context: context,
              title: 'Aviso',
              message: '¿Estás seguro? Si sales ahora, perderás tu progreso.',
              confirmButtonText: 'Sí, salir',
              cancelButtonText: 'No',
              confirmButtonColor: Colors.red,
              cancelButtonColor: const Color.fromARGB(255, 0, 0, 0),
            );

            if (result == true) {
              if (mounted) {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              }
            }

            return false;
          }

          return true;
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
                leading: IconButton(
                  icon: Icon(
                    Iconsax.arrow_left,
                    size: 25,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () async {
                    if (!_isLoading) {
                      final hayDescripcion =
                          _descripcionController.text.trim().isNotEmpty;
                      final hayImagenPrincipal = _mainImage != null;
                      final hayImagenesSeleccionadas =
                          _selectedImages.isNotEmpty;

                      if (hayDescripcion ||
                          hayImagenPrincipal ||
                          hayImagenesSeleccionadas) {
                        bool? result = await showCustomDialog(
                          context: context,
                          title: 'Aviso',
                          message:
                              '¿Estás seguro? Si sales ahora, perderás tu progreso.',
                          confirmButtonText: 'Sí, salir',
                          cancelButtonText: 'No',
                          confirmButtonColor: Colors.red,
                          cancelButtonColor: const Color.fromARGB(255, 0, 0, 0),
                        );

                        if (result == true) {
                          if (mounted) {
                            FocusScope.of(context).unfocus();
                            Navigator.pop(context);
                          }
                        }
                      } else {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
                title: Text(
                  'Publicaciones',
                  style: TextStyle(fontSize: 20),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      if (_descripcionController.text.isEmpty) {
                        showCustomDialog(
                          context: context,
                          title: 'Campos vacios',
                          message: 'Cajas de texto vacias',
                          confirmButtonText: 'Cerrar',
                        );
                      } else {
                        _uploadPublicationImages(_user!.uid);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoading
                            ? const Color.fromARGB(255, 185, 185, 185)
                            : const ui.Color(0xFFFFAF00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 8)),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromARGB(255, 115, 115, 115),
                              ),
                            ),
                          )
                        : Text(
                            'Publicar',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                  )
                ],
              ),
              body: Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: _descripcionController,
                              label: "Descripcion de la publicacion",
                              hintText:
                                  "Agrega una descripcion a tu prublicacion",
                              isNumeric: false,
                              maxLength: 300,
                              showCounter: false,
                              maxLines: 5,
                            ),
                            SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text(
                                    'Selecciona el tamaño de tu imagen',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text(
                                    'Esto determinará cómo se mostrará tu publicación (ideal para redes sociales o productos).',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 13,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ImageRatioSelector(
                                  onRatioSelected: (double x, double y) {
                                    setState(() {
                                      _aspectX = x;
                                      _aspectY = y;
                                    });
                                  },
                                  isDisabled: _mainImage != null,
                                ),
                              ],
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 0),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Iconsax.image,
                                          size: 20,
                                          color: theme.iconTheme.color),
                                      SizedBox(width: 6),
                                      Text(
                                        'Imágenes seleccionadas',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  MasonryGridView.count(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _selectedImages.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index < _selectedImages.length) {
                                        final image = _selectedImages[index];
                                        final isSelected = image == _mainImage;

                                        return Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _mainImage = image;
                                                });
                                                _showFullScreenImage(image);
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.file(
                                                  image,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            // Indicador de imagen seleccionada
                                            if (isSelected)
                                              const Positioned(
                                                top: 6,
                                                right: 6,
                                                child: Icon(Iconsax.tick_circle,
                                                    color: ui.Color.fromARGB(
                                                        255, 255, 255, 255),
                                                    size: 20),
                                              ),
                                            // Botón eliminar
                                            Positioned(
                                              top: 6,
                                              left: 6,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    setState(() {
                                                      _selectedImages
                                                          .removeAt(index);

                                                      if (_selectedImages
                                                          .isEmpty) {
                                                        _mainImage = null;
                                                      } else if (_mainImage ==
                                                          image) {
                                                        _mainImage =
                                                            _selectedImages
                                                                .first;
                                                      }
                                                    });
                                                  });
                                                },
                                                child: const Icon(Iconsax.trash,
                                                    color: ui.Color.fromARGB(
                                                        255, 189, 0, 0),
                                                    size: 22),
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        // Botón agregar imagen
                                        return GestureDetector(
                                          onTap: _selectImageSource,
                                          child: Container(
                                            height: 100,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.6),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color:
                                                      const ui.Color.fromARGB(
                                                          255, 0, 0, 0)),
                                            ),
                                            child: const Center(
                                              child: Icon(Iconsax.add_circle,
                                                  color: Colors.black87,
                                                  size: 30),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )));
  }
}
