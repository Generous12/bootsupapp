import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:bootsup/widgets/BotonesSeleccionables.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/dropdownbutton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pro_image_editor/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/core/models/editor_configs/pro_image_editor_configs.dart';
import 'package:pro_image_editor/features/main_editor/main_editor.dart';

class CrearProductoScreen extends StatefulWidget {
  @override
  _CrearProductoScreenState createState() => _CrearProductoScreenState();
}

class _CrearProductoScreenState extends State<CrearProductoScreen> {
  bool _isLoading = false;
  String? _categoriaSeleccionada;
  String? selectedGenero = '';
  String? selectedtipoprenda = '';
  List<String> _tayaSeleccionados = [];
  List<String> _tamanosSeleccionados = [];
  final ImagePicker _picker = ImagePicker();
  File? _mainImage;
  List<File> _selectedImages = [];
  User? _user = FirebaseAuth.instance.currentUser;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _descuentosController = TextEditingController();
  final TextEditingController _MarcaTecnologia = TextEditingController();
  final TextEditingController _ProveedorJuguete = TextEditingController();

  final List<String> categorias = [
    'Ropa',
    'Calzado',
    'Tecnologias',
    'Limpieza',
    'Muebles',
    'Juguetes',
  ];

  final List<String> tipoprenda = [
    'Parte superior',
    'Parte inferior',
  ];
  final List<String> genero = [
    'Hombre',
    'Mujer',
  ];
  void _handleTallsPantalones(List<String> tallasPSeleccionados) {
    setState(() {
      _tayaSeleccionados = tallasPSeleccionados;
    });
  }

  void _handleTamanoSelected(List<String> tamanosSeleccionados) {
    setState(() {
      _tamanosSeleccionados = tamanosSeleccionados;
    });
  }

  void limpiarCampos() {
    setState(() {
      _nombreController.clear();
      _descripcionController.clear();
      _precioController.clear();
      _cantidadController.clear();
      _descuentosController.clear();
      _MarcaTecnologia.clear();
      selectedGenero = '';
      selectedtipoprenda = '';
    });
  }

  Future<File> _convertBytesToFile(Uint8List bytes) async {
    final directory = await Directory.systemTemp.createTemp();
    final filePath = '${directory.path}/edited_image.png';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
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

  void _showFullScreenImage(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    color:
                        const ui.Color.fromARGB(255, 0, 0, 0).withOpacity(0.7),
                  ),
                ),
              ),
              Center(child: Image.file(imageFile)),

              // Botón cerrar
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
                    child: Icon(LucideIcons.minimize,
                        color: Colors.white, size: 24),
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
                              aspectRatio:
                                  const CropAspectRatio(ratioX: 1, ratioY: 1),
                              uiSettings: [
                                AndroidUiSettings(
                                  toolbarTitle: 'Cropper',
                                  toolbarColor: const Color(0xFFFFAF00),
                                  toolbarWidgetColor: Colors.white,
                                  lockAspectRatio: true,
                                  hideBottomControls: true,
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

  Future<bool> _isImageSquare(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    return image.width == image.height;
  }

  Future<void> _uploadProductImages(String _userId) async {
    String categoria = _categoriaSeleccionada?.trim() ?? '';
    if (categoria == 'Ropa') {
      List<String> errores = [];

      if (_descripcionController.text.isEmpty ||
          _nombreController.text.isEmpty ||
          _precioController.text.isEmpty) {
        errores.add('Completa todos los campos obligatorios.');
      }

      if (selectedtipoprenda == null || selectedtipoprenda!.isEmpty) {
        errores.add('Selecciona el tipo de prenda.');
      }

      if (selectedGenero == null || selectedGenero!.isEmpty) {
        errores.add('Selecciona el género.');
      }

      if (_selectedImages.isEmpty) {
        errores.add('Selecciona al menos una imagen.');
      } else {
        for (File imageFile in _selectedImages) {
          bool isSquare = await _isImageSquare(imageFile);
          if (!isSquare) {
            errores.add('Todas las imágenes deben tener proporción 1:1.');
            break;
          }
        }
      }

      if (selectedtipoprenda == 'Parte inferior') {
        if (_tayaSeleccionados.isEmpty) {
          errores.add('Selecciona al menos una talla para pantalón.');
        }
      } else if (selectedtipoprenda == 'Parte superior') {
        if (_tamanosSeleccionados.isEmpty) {
          errores.add(
              'Selecciona al menos una talla  (S, M, L...) para esta prenda.');
        }
      }

      if (errores.isNotEmpty) {
        await showCustomDialog(
          context: context,
          title: 'Formulario incompleto',
          message: errores.join('\n'),
          confirmButtonText: 'Cerrar',
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        String categoria = 'Ropa';
        String nombre = _nombreController.text.trim();
        String descripcion = _descripcionController.text.trim();
        int cantidad = int.tryParse(_cantidadController.text.trim()) ?? 1;
        String? genero = selectedGenero;
        double precio = double.parse(_precioController.text.trim());
        String descuentos = _descuentosController.text.trim();
        List<String> tallas = _tamanosSeleccionados;
        List<String> tallaPantalones = _tayaSeleccionados;
        String? tipoprenda = selectedtipoprenda;

        List<String> downloadUrls = [];
        for (File imageFile in _selectedImages) {
          final Uint8List webpBytes =
              await convertImageToWebP(imageFile, quality: 90);

          String storagePath =
              'images/$_userId/Empresa/productos/${DateTime.now().millisecondsSinceEpoch}.webp';

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
            FirebaseFirestore.instance.collection('productos').doc();

        // Construir el mapa dinámicamente para evitar campos vacíos o nulos
        Map<String, dynamic> dataToSave = {
          'userid': _userId,
          'imagenes': downloadUrls,
          'fecha': FieldValue.serverTimestamp(),
          'nombreProducto': nombre,
          'descripcion': descripcion,
          'cantidad': cantidad,
          'precio': precio,
          'descuento': descuentos,
          'categoria': categoria,
          'genero': genero,
          'tipoPrenda': tipoprenda,
          'tallaPantalon': tallaPantalones,
        };

        if (tallas.isNotEmpty) {
          dataToSave['talla'] = tallas;
        }

        await publicationRef.set(dataToSave);
        await showCustomDialog(
          context: context,
          title: 'Exito',
          message: 'Producto subido con exito',
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
    } else if (_categoriaSeleccionada == 'Calzado') {
      // Validaciones combinadas
      List<String> errores = [];

      if (_descripcionController.text.isEmpty ||
          _nombreController.text.isEmpty ||
          _precioController.text.isEmpty) {
        errores.add('Completa todos los campos obligatorios.');
      }

      if (_selectedImages.isEmpty) {
        errores.add('Selecciona al menos una imagen.');
      } else {
        for (File imageFile in _selectedImages) {
          bool isSquare = await _isImageSquare(imageFile);
          if (!isSquare) {
            errores.add('Todas las imágenes deben tener proporción 1:1.');
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
        String nombre = _nombreController.text.trim();
        String descripcion = _descripcionController.text.trim();
        int cantidad = int.tryParse(_cantidadController.text.trim()) ?? 1;
        double precio = double.parse(_precioController.text.trim());
        String descuentos = _descuentosController.text.trim();
        String? categoria = 'Calzado';
        List<String> tallas = _tamanosSeleccionados;

        List<String> downloadUrls = [];

        for (File imageFile in _selectedImages.take(4)) {
          final Uint8List webpBytes =
              await convertImageToWebP(imageFile, quality: 90);

          String storagePath =
              'images/$_userId/Empresa/productos/${DateTime.now().millisecondsSinceEpoch}.webp';

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
            FirebaseFirestore.instance.collection('productos').doc();

        await publicationRef.set({
          'userid': _userId,
          'imagenes': downloadUrls,
          'fecha': FieldValue.serverTimestamp(),
          'nombreProducto': nombre,
          'descripcion': descripcion,
          'cantidad': cantidad,
          'precio': precio,
          'descuento': descuentos,
          'categoria': categoria,
          'talla': tallas,
        });
        await showCustomDialog(
          context: context,
          title: 'Exito',
          message: 'Producto subido con exito',
          confirmButtonText: 'Cerrar',
        );
        Navigator.pop(context);
      } catch (e) {
        print("Error al subir: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir el calzado.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (_categoriaSeleccionada == 'Tecnologias') {
      List<String> errores = [];

      if (_descripcionController.text.isEmpty ||
          _nombreController.text.isEmpty ||
          _precioController.text.isEmpty ||
          _MarcaTecnologia.text.isEmpty) {
        errores.add('Completa todos los campos obligatorios.');
      }

      if (_selectedImages.isEmpty) {
        errores.add('Selecciona al menos una imagen.');
      } else {
        for (File imageFile in _selectedImages) {
          bool isSquare = await _isImageSquare(imageFile);
          if (!isSquare) {
            errores.add('Todas las imágenes deben tener proporción 1:1.');
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
        int cantidad = int.tryParse(_cantidadController.text.trim()) ?? 1;
        String nombre = _nombreController.text.trim();
        String descripcion = _descripcionController.text.trim();
        double precio = double.parse(_precioController.text.trim());
        String descuentos = _descuentosController.text.trim();
        String? categoria = 'Tecnologias';
        String? marca = _MarcaTecnologia.text.trim();

        List<String> downloadUrls = [];

        for (File imageFile in _selectedImages.take(4)) {
          final Uint8List webpBytes =
              await convertImageToWebP(imageFile, quality: 90);

          String storagePath =
              'images/$_userId/Empresa/productos/${DateTime.now().millisecondsSinceEpoch}.webp';

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
            FirebaseFirestore.instance.collection('productos').doc();

        await publicationRef.set({
          'userid': _userId,
          'imagenes': downloadUrls,
          'fecha': FieldValue.serverTimestamp(),
          'nombreProducto': nombre,
          'descripcion': descripcion,
          'cantidad': cantidad,
          'precio': precio,
          'descuento': descuentos,
          'categoria': categoria,
          'marca': marca,
        });

        await showCustomDialog(
          context: context,
          title: 'Exito',
          message: 'Producto subido con exito',
          confirmButtonText: 'Cerrar',
        );
        Navigator.pop(context);
      } catch (e) {
        print("Error al subir: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir el producto.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (_categoriaSeleccionada == 'Limpieza') {
      List<String> errores = [];

      if (_descripcionController.text.isEmpty ||
          _nombreController.text.isEmpty ||
          _precioController.text.isEmpty) {
        errores.add('Completa todos los campos obligatorios.');
      }

      if (_selectedImages.isEmpty) {
        errores.add('Selecciona al menos una imagen.');
      } else {
        for (File imageFile in _selectedImages) {
          bool isSquare = await _isImageSquare(imageFile);
          if (!isSquare) {
            errores.add('Todas las imágenes deben tener proporción 1:1.');
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
        int cantidad = int.tryParse(_cantidadController.text.trim()) ?? 1;
        String nombre = _nombreController.text.trim();
        String descripcion = _descripcionController.text.trim();
        double precio = double.parse(_precioController.text.trim());
        String descuentos = _descuentosController.text.trim();
        String? categoria = 'Limpieza';

        List<String> downloadUrls = [];

        for (File imageFile in _selectedImages.take(4)) {
          final Uint8List webpBytes =
              await convertImageToWebP(imageFile, quality: 90);

          String storagePath =
              'images/$_userId/Empresa/productos/${DateTime.now().millisecondsSinceEpoch}.webp';

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
            FirebaseFirestore.instance.collection('productos').doc();

        await publicationRef.set({
          'userid': _userId,
          'imagenes': downloadUrls,
          'fecha': FieldValue.serverTimestamp(),
          'nombreProducto': nombre,
          'descripcion': descripcion,
          'cantidad': cantidad,
          'precio': precio,
          'descuento': descuentos,
          'categoria': categoria,
        });

        await showCustomDialog(
          context: context,
          title: 'Exito',
          message: 'Producto subido con exito',
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
    } else if (_categoriaSeleccionada == 'Muebles') {
      List<String> errores = [];

      if (_descripcionController.text.isEmpty ||
          _nombreController.text.isEmpty ||
          _precioController.text.isEmpty) {
        errores.add('Completa todos los campos obligatorios.');
      }

      if (_selectedImages.isEmpty) {
        errores.add('Selecciona al menos una imagen.');
      } else {
        for (File imageFile in _selectedImages) {
          bool isSquare = await _isImageSquare(imageFile);
          if (!isSquare) {
            errores.add('Todas las imágenes deben tener proporción 1:1.');
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
        int cantidad = int.tryParse(_cantidadController.text.trim()) ?? 1;
        String categoria = 'Muebles';
        String nombre = _nombreController.text.trim();
        String descripcion = _descripcionController.text.trim();
        double precio = double.parse(_precioController.text.trim());
        String descuentos = _descuentosController.text.trim();

        List<String> downloadUrls = [];

        for (File imageFile in _selectedImages.take(4)) {
          final Uint8List webpBytes =
              await convertImageToWebP(imageFile, quality: 90);

          String storagePath =
              'images/$_userId/Empresa/productos/${DateTime.now().millisecondsSinceEpoch}.webp';

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
            FirebaseFirestore.instance.collection('productos').doc();

        await publicationRef.set({
          'userid': _userId,
          'imagenes': downloadUrls,
          'fecha': FieldValue.serverTimestamp(),
          'nombreProducto': nombre,
          'descripcion': descripcion,
          'cantidad': cantidad,
          'precio': precio,
          'descuento': descuentos,
          'categoria': categoria,
        });

        await showCustomDialog(
          context: context,
          title: 'Exito',
          message: 'Producto subido con exito',
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
    } else if (_categoriaSeleccionada == 'Juguetes') {
      List<String> errores = [];

      if (_descripcionController.text.isEmpty ||
          _nombreController.text.isEmpty ||
          _precioController.text.isEmpty ||
          _ProveedorJuguete.text.isEmpty) {
        errores.add('Completa todos los campos obligatorios.');
      }

      if (_selectedImages.isEmpty) {
        errores.add('Selecciona al menos una imagen.');
      } else {
        for (File imageFile in _selectedImages) {
          bool isSquare = await _isImageSquare(imageFile);
          if (!isSquare) {
            errores.add('Todas las imágenes deben tener proporción 1:1.');
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
        String categoria = 'Juguetes';
        String nombre = _nombreController.text.trim();
        String proveedor = _ProveedorJuguete.text.trim();
        String descripcion = _descripcionController.text.trim();
        int cantidad = int.tryParse(_cantidadController.text.trim()) ?? 1;
        double precio = double.parse(_precioController.text.trim());

        String descuentos = _descuentosController.text.trim();

        List<String> downloadUrls = [];

        for (File imageFile in _selectedImages.take(4)) {
          final Uint8List webpBytes =
              await convertImageToWebP(imageFile, quality: 90);

          String storagePath =
              'images/$_userId/Empresa/productos/${DateTime.now().millisecondsSinceEpoch}.webp';

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
            FirebaseFirestore.instance.collection('productos').doc();

        await publicationRef.set({
          'userid': _userId,
          'imagenes': downloadUrls,
          'fecha': FieldValue.serverTimestamp(),
          'nombreProducto': nombre,
          'proveedor': proveedor,
          'descripcion': descripcion,
          'cantidad': cantidad,
          'precio': precio,
          'descuento': descuentos,
          'categoria': categoria,
        });

        await showCustomDialog(
          context: context,
          title: 'Exito',
          message: 'Producto subido con exito',
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
          final haynombre = _nombreController.text.trim().isNotEmpty;
          final hayImagenPrincipal = _mainImage != null;
          final hayImagenesSeleccionadas = _selectedImages.isNotEmpty;

          if (hayDescripcion ||
              haynombre ||
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
                    if (_isLoading) return;

                    final hayDescripcion =
                        _descripcionController.text.trim().isNotEmpty;
                    final haynombre = _nombreController.text.trim().isNotEmpty;
                    final hayImagenPrincipal = _mainImage != null;
                    final hayImagenesSeleccionadas = _selectedImages.isNotEmpty;

                    final hayAlgo = hayDescripcion ||
                        haynombre ||
                        hayImagenPrincipal ||
                        hayImagenesSeleccionadas;

                    if (hayAlgo) {
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

                      if (result == true && mounted) {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                      }
                    } else {
                      // 🔓 Si no hay nada, simplemente salir sin diálogo
                      if (mounted) {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
                title: Text('Crear producto', style: TextStyle(fontSize: 20)),
                actions: [
                  ElevatedButton(
                    onPressed: () async {
                      bool? confirmed = await showCustomDialog(
                        context: context,
                        title: 'Confirmar acción',
                        message: '¿Estás seguro que deseas continuar?',
                        confirmButtonText: 'Sí',
                        cancelButtonText: 'No',
                        confirmButtonColor: Colors.red,
                      );

                      if (confirmed != null && confirmed) {
                        _uploadProductImages(_user!.uid);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading
                          ? Color.fromARGB(255, 185, 185, 185)
                          : Color(0xFFFFAF00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 5),
                    ),
                    child: SizedBox(
                      width: 50,
                      height: 35,
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.fromARGB(255, 115, 115, 115)),
                              )
                            : const Text(
                                'Subir',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  )
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomDropdownSelector(
                      labelText: 'Categoría',
                      hintText: 'Selecciona una categoría',
                      value: _categoriaSeleccionada,
                      items: categorias,
                      onChanged: (value) {
                        setState(() {
                          _categoriaSeleccionada = value;
                        });
                      },
                      itemActions: {
                        'Tecnologias': () {
                          limpiarCampos();
                        },
                        'Ropa': () {
                          limpiarCampos();
                        },
                        'Calzado': () {
                          limpiarCampos();
                        },
                        'Limpieza': () {
                          limpiarCampos();
                        },
                        'Muebles': () {
                          limpiarCampos();
                        },
                        'Juguetes': () {
                          limpiarCampos();
                        },
                      },
                    ),
                    _categoriaSeleccionada != null &&
                            _categoriaSeleccionada!.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _categoriaSeleccionada == 'Ropa'
                                  ? Column(
                                      children: [
                                        SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CustomDropdownSelector(
                                                labelText: 'Tipo de prenda',
                                                hintText: 'Seleccione',
                                                value: selectedtipoprenda,
                                                items: tipoprenda,
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedtipoprenda = value;
                                                  });
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 5),
                                            Expanded(
                                              child: CustomDropdownSelector(
                                                labelText: 'Genero',
                                                hintText: 'Seleccione',
                                                value: selectedGenero,
                                                items: ['Hombre', 'Mujer'],
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    selectedGenero = newValue;
                                                  });
                                                },
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                          ],
                                        )
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                              SizedBox(height: 15),
                              CustomTextField(
                                controller: _nombreController,
                                label: "Nombre del producto",
                                hintText: "Escribe el nombre del producto...",
                                maxLength: 30,
                                showCounter: true,
                              ),
                              SizedBox(height: 10),
                              CustomTextField(
                                controller: _descripcionController,
                                label: "Descripción",
                                hintText: "Escribe una descripción...",
                                maxLines: 5,
                                maxLength: 300,
                                showCounter: true,
                              ),
                              _categoriaSeleccionada == 'Juguetes'
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 10),
                                        CustomTextField(
                                          controller: _ProveedorJuguete,
                                          label: "Proveedor ",
                                          hintText: "Escribe el proveedor...",
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                              Column(
                                children: [
                                  _categoriaSeleccionada == 'Calzado'
                                      ? TallaZapatoSelector(
                                          onTallasSelected:
                                              _handleTamanoSelected,
                                        )
                                      : const SizedBox.shrink(),
                                  const SizedBox(height: 10),
                                  _categoriaSeleccionada == 'Tecnologias'
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CustomTextField(
                                              controller: _MarcaTecnologia,
                                              label: "Marca",
                                              hintText: "Escribe la marca...",
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(height: 10),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _cantidadController,
                                      label: "Cantidad",
                                      hintText: "Cantidad",
                                      isNumeric: true,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _precioController,
                                      label: "Precio",
                                      hintText: "Precio",
                                      isNumeric: true,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _descuentosController,
                                      label: "Descuento",
                                      hintText: "Descuento",
                                      isNumeric: true,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              _categoriaSeleccionada == 'Ropa'
                                  ? (selectedtipoprenda == 'Parte inferior'
                                      ? SelectorTallaPantalonPeru(
                                          onTallasSeleccionadas:
                                              _handleTallsPantalones)
                                      : selectedtipoprenda == 'Parte superior'
                                          ? TamanoSelector(
                                              onTamanosSelected:
                                                  _handleTamanoSelected)
                                          : const SizedBox.shrink())
                                  : const SizedBox.shrink(),
                              SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(1),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Column(
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Iconsax.image,
                                            size: 20, color: Colors.black87),
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
                                          final isSelected =
                                              image == _mainImage;

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
                                              if (isSelected)
                                                const Positioned(
                                                  top: 6,
                                                  right: 6,
                                                  child: Icon(
                                                      Iconsax.tick_circle,
                                                      color: ui.Color.fromARGB(
                                                          255, 255, 255, 255),
                                                      size: 20),
                                                ),
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
                                                  child: const Icon(
                                                      Iconsax.trash,
                                                      color: ui.Color.fromARGB(
                                                          255, 189, 0, 0),
                                                      size: 22),
                                                ),
                                              ),
                                            ],
                                          );
                                        } else {
                                          return GestureDetector(
                                            onTap: _selectImageSource,
                                            child: Container(
                                              height: 100,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.6),
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
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              )),
        ));
  }
}
