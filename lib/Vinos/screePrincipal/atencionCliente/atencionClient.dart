// ignore_for_file: unused_field

import 'package:bootsup/ModulosVinos/Chats/chatsVisita.dart';
import 'package:bootsup/Vinos/screePrincipal/atencionCliente/chatCreadobyClient.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AtencionClienteScreenVinos extends StatefulWidget {
  const AtencionClienteScreenVinos({super.key});

  @override
  State<AtencionClienteScreenVinos> createState() =>
      _AtencionClienteScreenState();
}

class _AtencionClienteScreenState extends State<AtencionClienteScreenVinos> {
  final TextEditingController _mensajeController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  bool _chatCreado = false;
  String? _chatId;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatId = ChatServiceVinos.generarChatIdUsuario(
        FirebaseAuth.instance.currentUser!.uid);
    return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white,
          appBar: AppBar(
            centerTitle: true,
            toolbarHeight: 50,
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Iconsax.arrow_left,
                  color: isDark ? Colors.white : Colors.black, size: 25),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Atención al Cliente',
              style: TextStyle(
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                // Opciones rápidas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _opcionRapida(Iconsax.message, 'Chat', isDark),
                    _opcionRapida(Iconsax.sms_tracking, 'Estado', isDark),
                  ],
                ),
                const SizedBox(height: 25),

                // Dropdown motivos
                DropdownButtonFormField<String>(
                  initialValue: _motivoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Selecciona el motivo',
                    labelStyle: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    filled: true,
                    fillColor:
                        isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: const Color(0xFFA30000), width: 1.5),
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
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _motivoSeleccionado = value!);
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

                _isSending
                    ? Center(
                        child: CircularProgressIndicator(
                            color: const Color(0xFFA30000)),
                      )
                    : LoadingOverlayButton(
                        text: 'Enviar',
                        onPressedLogic: () async {
                          final mensaje = _mensajeController.text.trim();
                          final correo = _correoController.text.trim();
                          final motivo = _motivoSeleccionado;
                          _chatId = await ChatServiceVinos.verificarOCrearChat(
                              FirebaseAuth.instance.currentUser!.uid);
                          setState(() {
                            _chatCreado = true;
                          });
                          navegarConSlideDerecha(
                            context,
                            ContactochatVinos(
                              userIdVisitante:
                                  FirebaseAuth.instance.currentUser!.uid,
                              mensajeController:
                                  TextEditingController(text: mensaje),
                              correoController:
                                  TextEditingController(text: correo),
                              motivoSeleccionado: motivo,
                            ),
                          );
                          _mensajeController.clear();
                          _correoController.clear();
                          setState(() {
                            _motivoSeleccionado = 'Consulta general';
                          });

                          return;
                        },
                        backgroundColor: const Color(0xFFA30000),
                        textColor: Colors.white,
                      ),

                const SizedBox(height: 30),
                Divider(
                    color:
                        isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    '¿Necesitas ayuda urgente?\nEscríbenos a soporte@tuapp.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection(ChatServiceVinos.coleccionChats)
                .doc(chatId)
                .snapshots(),
            builder: (context, snapshot) {
              // Mientras carga
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              // Si existe el chat, mostramos el botón
              if (snapshot.hasData && snapshot.data!.exists) {
                return FloatingActionButton(
                  backgroundColor: const Color(0xFFA30000),
                  onPressed: () {
                    navegarConSlideDerecha(
                      context,
                      ContactochatVinos(
                        userIdVisitante: FirebaseAuth.instance.currentUser!.uid,
                      ),
                    );
                  },
                  child: const Icon(Iconsax.message),
                );
              }

              // Si no existe chat → no se muestra nada
              return const SizedBox.shrink();
            },
          ),
        ));
  }

  Widget _opcionRapida(IconData icon, String label, bool isDark) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFA30000), width: 1.2),
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: const Color(0xFFA30000)),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
              fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
        ),
      ],
    );
  }
}
