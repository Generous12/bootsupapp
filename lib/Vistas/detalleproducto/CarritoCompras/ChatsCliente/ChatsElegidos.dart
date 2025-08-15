import 'package:bootsup/Modulos/Moduloschats/ChatsVisita.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

class ContactoEmpresaScreen1 extends StatefulWidget {
  final String userIdVisitante;
  final String empresaUserId;

  const ContactoEmpresaScreen1({
    Key? key,
    required this.userIdVisitante,
    required this.empresaUserId,
  }) : super(key: key);

  @override
  State<ContactoEmpresaScreen1> createState() => _ContactoEmpresaScreenState();
}

class _ContactoEmpresaScreenState extends State<ContactoEmpresaScreen1> {
  final List<types.Message> _mensajes = [];
  late final String _chatId;
  late final types.User _cliente;

  String? nombreEmpresa;
  String? fotoEmpresa;
  final _controller = TextEditingController();

  final Color naranja = const Color(0xFFFFAF00);

  @override
  void initState() {
    super.initState();
    _cliente = types.User(id: widget.userIdVisitante);

    _inicializarChat();
  }

  Future<void> _inicializarChat() async {
    _chatId = await ChatService.verificarOCrearChat(
      chatId: ChatService.generarChatIdOrdenado(
        widget.userIdVisitante,
        widget.empresaUserId,
      ),
      userIdVisitante: widget.userIdVisitante,
      empresaUserId: widget.empresaUserId,
    );

    debugPrint('🟢 Usando chatId: $_chatId');

    // Escuchar mensajes en tiempo real
    ChatService.escucharMensajes(_chatId).listen((mensajes) {
      debugPrint(" Mensajes recibidos: ${mensajes.length}");
      for (final msg in mensajes) {
        debugPrint(" Mensaje: ${msg.text} | autor: ${msg.author.id}");
      }

      if (!mounted) return;
      setState(() {
        _mensajes
          ..clear()
          ..addAll(mensajes);
      });
    });

    // Obtener datos de la empresa
    final datosEmpresa =
        await ChatService.fetchEmpresaData(widget.empresaUserId);

    if (datosEmpresa != null && mounted) {
      setState(() {
        nombreEmpresa = datosEmpresa['nombre'] ?? 'Empresa';
        fotoEmpresa = datosEmpresa['perfilEmpresa'] ??
            'https://ui-avatars.com/api/?name=${nombreEmpresa ?? "Empresa"}';
      });
    }
  }

  Future<void> _enviarMensaje(types.PartialText mensaje) async {
    try {
      await ChatService.enviarMensaje(
        chatId: _chatId,
        userId: _cliente.id,
        mensaje: mensaje,
      );
      debugPrint("Mensaje enviado: ${mensaje.text}");
    } catch (e) {
      debugPrint(" Error al enviar mensaje: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 48,
        titleSpacing: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon:
              Icon(Iconsax.arrow_left, color: theme.iconTheme.color, size: 25),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            if (fotoEmpresa != null)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(fotoEmpresa!),
              ),
            const SizedBox(width: 10),
            if (nombreEmpresa != null)
              Expanded(
                child: Text(
                  nombreEmpresa!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
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
      body: Column(
        children: [
          Expanded(
            child: Chat(
              messages: List<types.Message>.from(_mensajes),
              onSendPressed: _enviarMensaje,
              user: _cliente,
              showUserAvatars: false,
              showUserNames: false,
              theme: DefaultChatTheme(
                inputBackgroundColor: const Color.fromARGB(255, 15, 116, 89),
                primaryColor: const Color(0xFF142143),
                secondaryColor: const Color(0xFFFFAF00),
                backgroundColor: theme.scaffoldBackgroundColor,
                messageInsetsVertical: 6,
                messageInsetsHorizontal: 10,
                sentMessageBodyTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                receivedMessageBodyTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                inputTextColor: Colors.black,
                inputTextCursorColor: naranja,
              ),
              customBottomWidget: buildCustomInput(),
              emptyState: const SizedBox.shrink(),
              bubbleBuilder: (child,
                  {required message, required nextMessageInGroup}) {
                final isMe = message.author.id == _cliente.id;
                final hora = DateFormat('HH:mm').format(
                  DateTime.fromMillisecondsSinceEpoch(message.createdAt ?? 0),
                );

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color.fromARGB(255, 240, 164, 0)
                        : const Color.fromARGB(255, 0, 0, 0),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(10),
                      topRight: const Radius.circular(10),
                      bottomLeft: Radius.circular(isMe ? 10 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Afacad',
                            color: Colors.white,
                          ),
                          child: child,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          hora,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Afacad',
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCustomInput() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Theme(
        data: theme.copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: colorScheme.primary.withOpacity(0.5),
            cursorColor: colorScheme.onBackground,
            selectionHandleColor: colorScheme.primary,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                shadowColor: Colors.black12,
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  minLines: 1,
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 17,
                    color: colorScheme.onBackground,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF1F1F1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: "Escribe un mensaje...",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: IconButton(
                      icon: Icon(Icons.attach_file,
                          color: theme.iconTheme.color?.withOpacity(0.6)),
                      onPressed: () {
                        // Acción para adjuntar archivos
                      },
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Iconsax.send_2,
                          color: colorScheme.primary, size: 22),
                      onPressed: () {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) {
                          _enviarMensaje(types.PartialText(text: text));
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
