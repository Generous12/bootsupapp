import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/SnackBar.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class GestionMetodosPagoScreen extends StatefulWidget {
  @override
  _GestionMetodosPagoScreenState createState() =>
      _GestionMetodosPagoScreenState();
}

class _GestionMetodosPagoScreenState extends State<GestionMetodosPagoScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  File? _archivoAdjunto;
  String? archivoNombre;
  String? archivoUrl;
  bool _abriendoArchivo = false;
  bool _isSaving = false;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  String? tipoArchivo;
  bool _datosInicializados = false;

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

  Future<List<Map<String, dynamic>>> _obtenerMetodoPagoUsuario() async {
    if (userId == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('MetodoPago')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> _guardarMetodoPago() async {
    final nombre = _nombreController.text.trim();
    final numero = _numeroController.text.trim();

    if (nombre.isEmpty || numero.isEmpty) {
      if (!mounted) return;
      showCustomDialog(
        context: context,
        title: 'Campo vacío',
        message: 'Completa los campos vacíos',
        confirmButtonText: 'Cerrar',
      );
      return;
    }

    if (_archivoAdjunto == null && archivoUrl == null) {
      if (!mounted) return;
      showCustomDialog(
        context: context,
        title: 'Archivo requerido',
        message: 'Debes seleccionar una imagen o documento antes de guardar.',
        confirmButtonText: 'Cerrar',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    String? nuevoArchivoUrl = archivoUrl;
    String? nuevoTipoArchivo = tipoArchivo;
    if (_archivoAdjunto != null && userId != null) {
      try {
        final String extension =
            _archivoAdjunto!.path.split('.').last.toLowerCase();
        final String fileName = 'metodopago.$extension';
        final String storagePath = 'images/$userId/Empresa/$fileName';
        final Reference storageRef =
            FirebaseStorage.instance.ref().child(storagePath);

        UploadTask uploadTask;

        if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
          final Uint8List webpBytes =
              await convertImageToWebP(_archivoAdjunto!);
          final String webpPath = 'images/$userId/Empresa/metodopago.webp';
          final Reference webpRef =
              FirebaseStorage.instance.ref().child(webpPath);

          uploadTask = webpRef.putData(
            webpBytes,
            SettableMetadata(contentType: 'image/webp'),
          );
          nuevoTipoArchivo = 'imagen';
        } else if (extension == 'webp') {
          uploadTask = storageRef.putFile(
            _archivoAdjunto!,
            SettableMetadata(contentType: 'image/webp'),
          );
          nuevoTipoArchivo = 'imagen';
        } else if (extension == 'pdf') {
          uploadTask = storageRef.putFile(
            _archivoAdjunto!,
            SettableMetadata(contentType: 'application/pdf'),
          );
          nuevoTipoArchivo = 'pdf';
        } else {
          throw Exception('Formato de archivo no permitido');
        }

        final TaskSnapshot snapshot = await uploadTask;
        nuevoArchivoUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        print('Error subiendo archivo: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error subiendo archivo: $e')),
          );
        }
      }
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('MetodoPago')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;

        // 🔧 Solo actualiza los campos modificados
        final Map<String, dynamic> datosActualizados = {
          'nombre': nombre,
          'numero': numero,
          'fechaActualizacion': FieldValue.serverTimestamp(),
        };

        if (_archivoAdjunto != null) {
          datosActualizados['archivoUrl'] = nuevoArchivoUrl;
          datosActualizados['tipoArchivo'] = nuevoTipoArchivo;
        }

        await FirebaseFirestore.instance
            .collection('MetodoPago')
            .doc(docId)
            .update(datosActualizados);

        if (mounted) {
          SnackBarUtil.mostrarSnackBarPersonalizado(
            context: context,
            mensaje: 'Método de pago actualizado correctamente',
            icono: Icons.check_circle,
            colorFondo: Colors.green.shade800,
          );
        }
      } else {
        // 🔨 Crear nuevo documento si no existe
        await FirebaseFirestore.instance.collection('MetodoPago').add({
          'nombre': nombre,
          'numero': numero,
          'archivoUrl': nuevoArchivoUrl,
          'tipoArchivo': nuevoTipoArchivo,
          'userId': userId,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          SnackBarUtil.mostrarSnackBarPersonalizado(
            context: context,
            mensaje: 'Método de pago guardado correctamente',
            icono: Icons.check_circle,
            colorFondo: const Color.fromARGB(255, 0, 0, 0),
          );
        }
      }

      if (mounted) {
        setState(() {
          _archivoAdjunto = null;
          archivoNombre = null;
          _isSaving = false;
          _datosInicializados = false;
        });
      }
    } catch (e) {
      print('Error guardando en Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar método de pago')),
        );
      }
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _esPdf() {
    final path = _archivoAdjunto?.path ?? archivoUrl ?? '';

    // Extraer la extensión ignorando parámetros de URL (como ?alt=media)
    final uri = Uri.tryParse(path);
    final cleanPath = uri?.path ?? path;
    final extension = cleanPath.split('.').last.toLowerCase();

    return extension == 'pdf';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
        onWillPop: () async {
          if (_isSaving) {
            return false;
          }
          final haytelefono = _numeroController.text.trim().isNotEmpty;
          final haynombre = _nombreController.text.trim().isNotEmpty;
          final hayImagenPrincipal = _archivoAdjunto != null;

          if (haytelefono || haynombre || hayImagenPrincipal) {
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
                  centerTitle: true,
                  titleSpacing: 0,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  toolbarHeight: 48,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon: Icon(Iconsax.arrow_left,
                        color: theme.iconTheme.color, size: 25),
                    onPressed: () {
                      if (!_isSaving) {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                      }
                    },
                  ),
                  title: Text(
                    'Método de Pago',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(1.0),
                    child: Container(
                      height: 1.0,
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                    ),
                  ),
                ),
                body: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _obtenerMetodoPagoUsuario(),
                    builder: (context, snapshot) {
                      final metodos = snapshot.data ?? [];
                      final metodo = metodos.isNotEmpty ? metodos.first : null;

                      if (metodo != null && !_datosInicializados) {
                        _nombreController.text = metodo['nombre'] ?? '';
                        _numeroController.text = metodo['numero'] ?? '';
                        archivoUrl = metodo['archivoUrl'];
                        tipoArchivo = metodo['tipoArchivo'];

                        _datosInicializados = true;
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Métodos de pago aceptados',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Actualmente solo se aceptan pagos mediante Yape o Plin. Asegúrate de ingresar correctamente el nombre completo del receptor y el número asociado.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontSize: 15.5,
                                              height: 1.45,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color
                                                  ?.withOpacity(0.9),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            CustomTextField(
                              controller: _nombreController,
                              label: "Nombre del receptor completo",
                              hintText: "Agregar nombres y apellidos completos",
                              prefixIcon: Iconsax.user,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _numeroController,
                              label: "Número de teléfono disponible",
                              hintText: "Ej. 987654321",
                              prefixIcon: Iconsax.call,
                              maxLength: 9,
                              isNumeric: true,
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Subir QR o documento (opcional)",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _mostrarOpcionesAdjunto(context),
                              child: Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: (_archivoAdjunto != null ||
                                        archivoUrl != null)
                                    ? Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _esPdf()
                                                  ? Icons.picture_as_pdf
                                                  : Icons.image,
                                              color: _esPdf()
                                                  ? Colors.red
                                                  : Colors.blue,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _esPdf()
                                                  ? "Documento seleccionado"
                                                  : "Imagen seleccionada",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(width: 10),
                                            GestureDetector(
                                              onTap: _abriendoArchivo
                                                  ? null
                                                  : () async {
                                                      setState(() =>
                                                          _abriendoArchivo =
                                                              true);

                                                      try {
                                                        if (_archivoAdjunto !=
                                                            null) {
                                                          await OpenFile.open(
                                                              _archivoAdjunto!
                                                                  .path);
                                                        } else if (archivoUrl !=
                                                            null) {
                                                          await descargarYAbrirArchivo(
                                                              context,
                                                              archivoUrl!);
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'No hay archivo para abrir.'),
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        debugPrint(
                                                            "Error al abrir archivo: $e");
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                                'Error al abrir archivo.'),
                                                          ),
                                                        );
                                                      } finally {
                                                        if (mounted)
                                                          setState(() =>
                                                              _abriendoArchivo =
                                                                  false);
                                                      }
                                                    },
                                              child: _abriendoArchivo
                                                  ? const SizedBox(
                                                      height: 16,
                                                      width: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    )
                                                  : Text(
                                                      "Ver",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Iconsax.document_upload,
                                              size: 30,
                                              color: Colors.grey.shade600),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Toca para subir imagen o PDF",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: LoadingOverlayButton(
                                text: metodo != null
                                    ? 'Actualizar método de pago'
                                    : 'Guardar método de pago',
                                onPressedLogic: _isSaving
                                    ? () async {}
                                    : _guardarMetodoPago,
                              ),
                            ),
                            if (metodo != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: LoadingOverlayButton(
                                  text: 'Eliminar método de pago',
                                  backgroundColor: Colors.red,
                                  onPressedLogic: _isSaving
                                      ? () async {}
                                      : eliminarMetodoPago,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }))));
  }

  Future<void> descargarYAbrirArchivo(BuildContext context, String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();

        // Detectar el nombre real del archivo desde la URL o usar un timestamp
        final extension = url.split('.').last.toLowerCase().split('?').first;
        final fileName =
            'archivo_${DateTime.now().millisecondsSinceEpoch}.$extension';

        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        final result = await OpenFile.open(file.path);

        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No se pudo abrir el archivo.")),
          );
        }
      } else {
        throw Exception(
            'Error al descargar el archivo (código ${response.statusCode})');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir archivo: $e')),
      );
    }
  }

  void _mostrarOpcionesAdjunto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Iconsax.image, color: Colors.blue),
                title: Text('Seleccionar imagen'),
                onTap: () async {
                  Navigator.pop(context);
                  await _seleccionarImagen();
                },
              ),
              ListTile(
                leading: Icon(Iconsax.document, color: Colors.green),
                title: Text('Seleccionar documento'),
                onTap: () async {
                  Navigator.pop(context);
                  await _seleccionarDocumento();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _archivoAdjunto = File(pickedFile.path);
        archivoNombre = pickedFile.name;
      });
    }
  }

  Future<void> _seleccionarDocumento() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _archivoAdjunto = File(result.files.single.path!);
        archivoNombre = result.files.single.name;
      });
    }
  }

  Future<void> eliminarMetodoPago() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('MetodoPago')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('No se encontró método de pago');
      }

      final metodoDoc = snapshot.docs.first;
      final tipoArchivo = metodoDoc['tipoArchivo'] ?? '';
      // ignore: unused_local_variable
      final archivoUrl = metodoDoc['archivoUrl'] ?? '';

      // Eliminar archivo desde Firebase Storage
      try {
        final storage = FirebaseStorage.instance;
        final String fileName =
            tipoArchivo == 'imagen' ? 'metodopago.webp' : 'metodopago.pdf';
        final String path = 'images/$userId/Empresa/$fileName';

        final fileRef = storage.ref().child(path);
        await fileRef.delete();
        print('Archivo $fileName eliminado correctamente');
      } catch (e) {
        print('Error al eliminar archivo en Storage: $e');
      }

      // Eliminar documento en Firestore
      await metodoDoc.reference.delete();

      if (!mounted) return;

      setState(() {
        _nombreController.clear();
        _numeroController.clear();
        _archivoAdjunto = null;
        archivoNombre = null;
      });

      SnackBarUtil.mostrarSnackBarPersonalizado(
        context: context,
        mensaje: 'Método de pago eliminado correctamente',
        icono: Icons.check_circle,
        colorFondo: const Color.fromARGB(255, 0, 0, 0),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar: $e")),
      );
    }
  }
}
