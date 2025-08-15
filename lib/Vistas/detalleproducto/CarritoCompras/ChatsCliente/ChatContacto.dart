import 'package:bootsup/Modulos/Moduloschats/ChatsVisita.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class ContactoEmpresaS extends StatefulWidget {
  final String userIdVisitante;
  final String empresaUserId;

  const ContactoEmpresaS({
    Key? key,
    required this.userIdVisitante,
    required this.empresaUserId,
  }) : super(key: key);

  @override
  State<ContactoEmpresaS> createState() => _ContactoEmpresaScreenState();
}

class _ContactoEmpresaScreenState extends State<ContactoEmpresaS> {
  final List<types.Message> _mensajes = [];
  late String _chatId;
  late types.User _usuario;
  String? perfilEmpresaUrl;
  String? nombreEmpresa;

  final Color azulOscuro = const Color(0xFF142143);
  final Color naranja = const Color(0xFFFFAF00);
  final Color rojoMensaje = const Color.fromARGB(255, 151, 0, 0);

  @override
  void initState() {
    super.initState();
    _usuario = types.User(id: widget.userIdVisitante);
    _chatId = "${widget.userIdVisitante}_${widget.empresaUserId}";
    _inicializarChat();
  }

  Future<void> _inicializarChat() async {
    await ChatService.verificarOCrearChat(
      chatId: _chatId,
      userIdVisitante: widget.userIdVisitante,
      empresaUserId: widget.empresaUserId,
    );

    ChatService.escucharMensajes(_chatId).listen((mensajes) {
      if (!mounted) return;
      setState(() {
        _mensajes
          ..clear()
          ..addAll(mensajes);
      });
    });

    final datosEmpresa =
        await ChatService.fetchEmpresaData(widget.empresaUserId);
    if (datosEmpresa != null && mounted) {
      setState(() {
        perfilEmpresaUrl = datosEmpresa['perfilEmpresa'];
        nombreEmpresa = datosEmpresa['nombre'];
      });
    }
  }

  Future<void> _enviarMensaje(types.PartialText mensaje) async {
    await ChatService.enviarMensaje(
      chatId: _chatId,
      userId: _usuario.id,
      mensaje: mensaje,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: theme.iconTheme.color,
            size: 25,
          ),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            if (perfilEmpresaUrl != null)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(perfilEmpresaUrl!),
                backgroundColor: Colors.transparent,
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
        actions: [
          IconButton(
            icon: Icon(Iconsax.more, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
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
              user: _usuario,
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
                final isMe = message.author.id == _usuario.id;

                // Formatear la hora
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Mensaje
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
                            // Hora
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  final _controller = TextEditingController();

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
