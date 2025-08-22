import 'package:bootsup/ModulosVinos/Chats/chatsVisita.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class ContactochatVinos extends StatefulWidget {
  final String userIdVisitante;
  final TextEditingController? mensajeController;
  final TextEditingController? correoController;
  final String? motivoSeleccionado;

  const ContactochatVinos({
    Key? key,
    required this.userIdVisitante,
    this.mensajeController,
    this.correoController,
    this.motivoSeleccionado,
  }) : super(key: key);

  @override
  State<ContactochatVinos> createState() => _ContactochatVinosState();
}

class _ContactochatVinosState extends State<ContactochatVinos> {
  final List<types.Message> _mensajes = [];
  late String _chatId;
  late types.User _usuario;
  final TextEditingController _controller = TextEditingController();
  String? perfilEmpresaUrl;
  String? nombreEmpresa;

  @override
  void initState() {
    super.initState();
    _usuario = types.User(id: widget.userIdVisitante);

    // Construir el texto inicial combinando correo y motivo si existen
    final buffer = StringBuffer();
    if (widget.correoController != null &&
        widget.correoController!.text.isNotEmpty) {
      buffer.writeln('Correo: ${widget.correoController!.text}');
    }
    if (widget.motivoSeleccionado != null &&
        widget.motivoSeleccionado!.isNotEmpty) {
      buffer.writeln('Motivo: ${widget.motivoSeleccionado}');
    }

    // Si hay un mensaje inicial del contacto, agregarlo
    if (widget.mensajeController != null &&
        widget.mensajeController!.text.isNotEmpty) {
      buffer.writeln('Mensaje: ${widget.mensajeController!.text}');
    }

    // Inicializar el controlador con todo el texto
    _controller.text = buffer.toString().trim();

    _inicializarChat();
  }

  Future<void> _inicializarChat() async {
    _chatId =
        await ChatServiceVinos.verificarOCrearChat(widget.userIdVisitante);

    ChatServiceVinos.escucharMensajes(_chatId).listen((mensajes) {
      if (!mounted) return;
      setState(() {
        _mensajes
          ..clear()
          ..addAll(mensajes);
      });
    });

    if (mounted) {
      setState(() {
        perfilEmpresaUrl = 'https://ui-avatars.com/api/?name=Empresa';
        nombreEmpresa = 'Empresa';
      });
    }
  }

  Future<void> _enviarMensaje(types.PartialText mensaje) async {
    if (_chatId.isEmpty) return;
    await ChatServiceVinos.enviarMensaje(
      chatId: _chatId,
      userId: _usuario.id,
      mensaje: mensaje,
    );
  }

  Future<void> _enviarConConfirmacion() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    bool enviar = true;

    if (widget.mensajeController != null || widget.motivoSeleccionado != null) {
      // Mostrar confirmación solo si venimos con datos
      enviar = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirmar envío'),
              content: Text('¿Deseas enviar tu mensaje?\n\n"$text"'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Enviar')),
              ],
            ),
          ) ??
          false;
    }

    if (enviar) {
      await _enviarMensaje(types.PartialText(text: text));
      _controller.clear();
    }
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
                backgroundImage: AssetImage('assets/images/logo.png'),
                backgroundColor: Colors.transparent,
              ),
            const SizedBox(width: 10),
            if (nombreEmpresa != null)
              Expanded(
                child: Text(
                  'La Casita del Pisco',
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
                inputTextCursorColor: Colors.black,
              ),
              customBottomWidget: buildCustomInput(),
              emptyState: const SizedBox.shrink(),
              bubbleBuilder: (child,
                  {required message, required nextMessageInGroup}) {
                final isMe = message.author.id == _usuario.id;
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

  Widget buildCustomInput() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
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
                  color: theme.colorScheme.onBackground,
                ),
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    onPressed: () {},
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Iconsax.send_2,
                        color: theme.colorScheme.primary, size: 22),
                    onPressed: _enviarConConfirmacion,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
