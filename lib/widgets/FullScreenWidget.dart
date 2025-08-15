import 'dart:io';
import 'dart:ui' as ui;
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeline_tile/timeline_tile.dart';

class _BackgroundDesignPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20); // nivel de blur

    paint.color = Colors.orangeAccent.withOpacity(0.3);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 100, paint);

    paint.color = Colors.deepPurpleAccent.withOpacity(0.3);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 150, paint);

    paint.color = Colors.blueAccent.withOpacity(0.2);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 200, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class FullScreenImageViewer extends StatefulWidget {
  final File? initialImage;
  final String? firebaseImageUrl;

  const FullScreenImageViewer({
    Key? key,
    this.initialImage,
    this.firebaseImageUrl,
  }) : super(key: key);

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  File? _currentImage;
  bool _isLoading = false; // Indicador de carga

  @override
  void initState() {
    super.initState();
    _currentImage = widget.initialImage;
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true; // Iniciar carga
    });

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _currentImage = File(pickedFile.path);
        _isLoading = false; // Detener carga
      });
    } else {
      setState(() {
        _isLoading = false; // Detener carga si no se seleccionó ninguna imagen
      });
    }
  }

  Future<void> _cropImage() async {
    if (_currentImage == null ||
        _currentImage!.path == 'assets/images/empresa.png') {
      await showCustomDialog(
        context: context,
        title: 'Imagen no seleccionada',
        message: 'Seleccione una nueva imagen para continuar',
        confirmButtonText: 'Cerrar',
      );
      return;
    }

    setState(() {
      _isLoading = true; // Iniciar carga mientras recortamos
    });

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _currentImage!.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar imagen',
          toolbarColor: const Color(0xFFFFC800),
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _currentImage = File(croppedFile.path);
      });
    }

    setState(() {
      _isLoading = false; // Detener carga después del recorte
    });
  }

  Future<bool> _isImageSquare(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    return image.width == image.height;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFEF6C00).withOpacity(0.4), // Naranja oscuro
                    Color(0xFFFFC107)
                        .withOpacity(0.4), // Amarillo cálido (Amber)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomPaint(
                painter: _BackgroundDesignPainter(), // Tu diseño personalizado
              ),
            ),
          ),

          // 💫 FILTRO DIFUSO (esto desenfoca lo anterior)
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.6),
              ),
            ),
          ),
          Center(
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Color(0xFFFFC800),
                  )
                : _currentImage != null
                    ? Image.file(_currentImage!)
                    : (widget.firebaseImageUrl != null
                        ? Image.network(
                            widget.firebaseImageUrl!,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                width: 60,
                                height: 60,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFFC800),
                                    strokeWidth: 3,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              LucideIcons.image,
                              size: 100,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.image_not_supported,
                            size: 100,
                            color: Colors.white,
                          )),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () async {
                if (_currentImage != null) {
                  bool isSquare = await _isImageSquare(_currentImage!);
                  if (!isSquare) {
                    await showCustomDialog(
                      context: context,
                      title: 'Imagen no seleccionada',
                      message: 'La imagen debe tener 1x1 para subir',
                      confirmButtonText: 'Cerrar',
                    );
                    return;
                  }
                }
                Navigator.pop(context, _currentImage);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(8),
                child: Icon(Icons.check, color: Colors.white, size: 24),
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
                _circleButton(
                    Icons.camera_alt, () => _pickImage(ImageSource.camera)),
                SizedBox(width: 30),
                _circleButton(
                    Icons.photo_library, () => _pickImage(ImageSource.gallery)),
                SizedBox(width: 30),
                _circleButton(Icons.crop, _cropImage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onPressed) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      radius: 30,
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: onPressed,
      ),
    );
  }
}

class SeguimientoEnvio extends StatelessWidget {
  final String estado;

  SeguimientoEnvio({required this.estado});

  final List<String> estados = [
    'No atendido',
    'Recibidos',
    'Preparación',
    'Enviado',
  ];

  final List<IconData> iconos = [
    Icons.inbox,
    Icons.download_done,
    Icons.kitchen,
    Icons.local_shipping,
  ];

  int _estadoToIndex(String estado) {
    return estados.indexWhere((e) => e.toLowerCase() == estado.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final index = _estadoToIndex(estado);
    return SizedBox(
      height: 100,
      child: Row(
        children: List.generate(estados.length * 2 - 1, (i) {
          final isTile = i.isEven;
          final idx = i ~/ 2;

          if (isTile) {
            final isActive = idx <= index;
            return Expanded(
              flex: 1,
              child: TimelineTile(
                axis: TimelineAxis.horizontal,
                alignment: TimelineAlign.center,
                isFirst: idx == 0,
                isLast: idx == estados.length - 1,
                beforeLineStyle: LineStyle(
                  color: isActive ? Colors.orange : Colors.grey.shade300,
                  thickness: 4,
                ),
                afterLineStyle: LineStyle(
                  color: idx < index
                      ? const Color(0xFFFF9800)
                      : Colors.grey.shade300,
                  thickness: 4,
                ),
                indicatorStyle: IndicatorStyle(
                  width: 30,
                  height: 30,
                  indicatorXY: 0.5,
                  color: isActive ? Colors.orange : Colors.grey.shade300,
                  iconStyle: IconStyle(
                    iconData: iconos[idx],
                    color: Colors.white,
                  ),
                ),
                startChild: idx == 0 ? Container() : null,
                endChild: idx == estados.length - 1 ? Container() : null,
              ),
            );
          } else {
            return const SizedBox(width: 4);
          }
        }),
      ),
    );
  }
}

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consejos'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            TipTile(
              icon: Iconsax.tick_circle,
              title: 'Verifica bien los datos',
              description:
                  'Asegúrate de que la información ingresada sea correcta antes de aprobar o rechazar.',
            ),
            TipTile(
              icon: Iconsax.document,
              title: 'Revisa el comprobante',
              description:
                  'Observa claramente la imagen del comprobante antes de tomar una decisión.',
            ),
            TipTile(
              icon: Iconsax.warning_2,
              title: 'Observaciones claras',
              description:
                  'Si rechazas un comprobante, indica el motivo claramente para que el usuario lo entienda.',
            ),
          ],
        ),
      ),
    );
  }
}

class TipTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const TipTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final Color borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Icono dentro de círculo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFAF00).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFFAF00),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          /// Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
