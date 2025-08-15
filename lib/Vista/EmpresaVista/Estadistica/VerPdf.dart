import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';

class VerBoletaScreen extends StatelessWidget {
  final String filePath;

  const VerBoletaScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final backgroundColor = isDarkMode ? Colors.black : const Color(0xFFFAFAFA);
    final iconColor = isDarkMode ? Colors.white : Colors.black;
    final borderColor = isDarkMode
        ? Colors.grey.shade800
        : const Color.fromARGB(255, 237, 237, 237);
    final pdfViewerBgColor = isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 40,
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: iconColor,
            size: 25,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        iconTheme: IconThemeData(color: iconColor),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: iconColor),
            onPressed: () async {
              try {
                final file = File(filePath);
                if (await file.exists()) {
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: 'Te envío esta boleta PDF 📄',
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Archivo no encontrado')),
                  );
                }
              } catch (e) {
                print('Error al compartir archivo: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo compartir el archivo'),
                  ),
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            color: borderColor,
          ),
        ),
      ),
      body: Container(
        color: backgroundColor,
        width: double.infinity,
        height: double.infinity,
        child: SfPdfViewerTheme(
          data: SfPdfViewerThemeData(
            progressBarColor: const Color.fromARGB(255, 255, 174, 0),
            backgroundColor: pdfViewerBgColor,
          ),
          child: SfPdfViewer.file(File(filePath)),
        ),
      ),
    );
  }
}
