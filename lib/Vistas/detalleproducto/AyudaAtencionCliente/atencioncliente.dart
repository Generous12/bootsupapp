import 'package:bootsup/widgets/SnackBar.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AtencionClienteScreen extends StatefulWidget {
  const AtencionClienteScreen({super.key});

  @override
  State<AtencionClienteScreen> createState() => _AtencionClienteScreenState();
}

class _AtencionClienteScreenState extends State<AtencionClienteScreen> {
  final TextEditingController _mensajeController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();

  final List<String> _motivos = [
    'Consulta general',
    'Problemas técnicos',
    'Información sobre planes',
    'Reportar un error',
    'Otro',
  ];

  String _motivoSeleccionado = 'Consulta general';
  bool _isSending = false;

  @override
  void dispose() {
    _mensajeController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _enviarMensaje() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSending = false;
    });

    SnackBarUtil.mostrarSnackBarPersonalizado(
      context: context,
      mensaje: 'Mensaje envido correctamente',
      icono: Icons.check_circle,
      colorFondo: const Color.fromARGB(255, 0, 0, 0),
    );

    _mensajeController.clear();
    _correoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            centerTitle: true,
            toolbarHeight: 48,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Iconsax.arrow_left,
                  color: theme.iconTheme.color, size: 25),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Atención al Cliente',
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿En qué podemos ayudarte?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Icon(Iconsax.call, color: theme.iconTheme.color),
                        SizedBox(height: 5),
                        Text("Llamar", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Iconsax.message, color: theme.iconTheme.color),
                        SizedBox(height: 5),
                        Text("Chat", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Iconsax.sms_tracking,
                            color: theme.iconTheme.color),
                        SizedBox(height: 5),
                        Text("Estado", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                DropdownButtonFormField2<String>(
                  value: _motivoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Selecciona el motivo',
                    labelStyle: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 16,
                      color: isDark
                          ? Colors.grey[300]
                          : const Color.fromARGB(255, 100, 100, 100),
                    ),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey.shade600 : Colors.black,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey.shade600 : Colors.black,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.orange : Colors.black,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                  ),
                  isExpanded: true,
                  items: _motivos.map((motivo) {
                    return DropdownMenuItem<String>(
                      value: motivo,
                      child: Text(
                        motivo,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _motivoSeleccionado = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Campo mensaje
                CustomTextField(
                  controller: _mensajeController,
                  hintText: 'Escribe tu mensaje aquí...',
                  maxLines: 7,
                  maxLength: 800,
                  label: "Mensaje",
                  showCounter: true,
                ),
                const SizedBox(height: 20),

                // Campo correo opcional
                CustomTextField(
                  controller: _correoController,
                  hintText: 'ejemplo@correo.com',
                  label: 'Tu correo (opcional)',
                  maxLines: 1,
                ),
                const SizedBox(height: 20),

                // Botón enviar
                _isSending
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFFFFAF00)),
                      )
                    : LoadingOverlayButton(
                        text: 'Enviar',
                        onPressedLogic: () async {
                          _enviarMensaje();
                        },
                      ),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),

                // Info adicional
                Center(
                  child: Text(
                    '¿Necesitas ayuda urgente?\nEscríbenos a soporte@tuapp.com',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
