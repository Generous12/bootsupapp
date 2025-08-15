import 'dart:io';
import 'package:bootsup/Vista/EmpresaVista/menuPerfilEmpresa/ReelsVideo/Trimmer.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class VideoEditorPage extends StatefulWidget {
  const VideoEditorPage({Key? key}) : super(key: key);

  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  File? _videoFile;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo({required bool fromCamera}) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    _videoPlayerController = VideoPlayerController.file(file);
    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
    );

    setState(() {
      _videoFile = file;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _videoFile == null
          ? Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Builder(
                      builder: (context) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        final naranja = const Color(0xFFFFAF00);
                        final grisClaro = const Color(0xFFFAFAFA);
                        final textColor = isDark ? grisClaro : Colors.black;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: naranja.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Iconsax.video,
                                size: 80,
                                color: naranja,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Título
                            Text(
                              "Crea tu contenido",
                              style: TextStyle(
                                fontFamily: 'Afacad',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Subtítulo
                            Text(
                              "Graba un nuevo video o selecciona uno de tu galería.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Afacad',
                                fontSize: 15,
                                color: textColor.withOpacity(0.7),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Botón grabar video
                            ElevatedButton.icon(
                              icon: const Icon(Iconsax.video,
                                  size: 22, color: Colors.white),
                              label: const Text(
                                'Grabar video',
                                style: TextStyle(
                                  fontFamily: 'Afacad',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              onPressed: () => _pickVideo(fromCamera: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: naranja,
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                                shadowColor: naranja.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Botón seleccionar video
                            ElevatedButton.icon(
                              icon: Icon(Iconsax.gallery,
                                  size: 22, color: naranja),
                              label: Text(
                                'Seleccionar video',
                                style: TextStyle(
                                  fontFamily: 'Afacad',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: naranja,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              onPressed: () => _pickVideo(fromCamera: false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: naranja.withOpacity(0.08),
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: Builder(
                    builder: (context) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final textColor =
                          isDark ? const Color(0xFFFAFAFA) : Colors.black;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Iconsax.arrow_left,
                              size: 24,
                              color: textColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : const Center(child: CircularProgressIndicator()),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _videoFile = null;
                          _videoPlayerController?.dispose();
                          _chewieController?.dispose();
                          _videoPlayerController = null;
                          _chewieController = null;
                        });
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.content_cut, color: Colors.white),
                      onPressed: () async {
                        final File? trimmedVideo = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VideoTrimmerPage(videoFile: _videoFile!),
                          ),
                        );

                        if (trimmedVideo != null) {
                          // Liberar controladores anteriores
                          _videoPlayerController?.dispose();
                          _chewieController?.dispose();

                          // Configurar con el video recortado
                          _videoPlayerController =
                              VideoPlayerController.file(trimmedVideo);
                          await _videoPlayerController!.initialize();

                          _chewieController = ChewieController(
                            videoPlayerController: _videoPlayerController!,
                            autoPlay: false,
                            looping: false,
                          );

                          setState(() {
                            _videoFile = trimmedVideo;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
