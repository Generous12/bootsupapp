// ignore_for_file: unused_local_variable

import 'package:bootsup/Clases/ChatResumen.dart';
import 'package:bootsup/Modulos/Moduloschats/ChatsVisita.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/ChatsCliente/ChatsElegidos.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/BotonesSeleccionables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmpresasContactadasScreen extends StatefulWidget {
  const EmpresasContactadasScreen({Key? key}) : super(key: key);

  @override
  State<EmpresasContactadasScreen> createState() =>
      _EmpresasContactadasScreenState();
}

class _EmpresasContactadasScreenState extends State<EmpresasContactadasScreen> {
  final TextEditingController _searchController = TextEditingController();
  String filtroActivo = 'Todos';
  final String clienteID = FirebaseAuth.instance.currentUser!.uid;
  List<ChatResumen> _allChats = [];

  Set<String> _chatsSeleccionados = {};
  bool get _estaSeleccionando => _chatsSeleccionados.isNotEmpty;
  late Stream<List<ChatResumen>> _streamChats;

  @override
  void initState() {
    super.initState();
    _streamChats = ChatService.obtenerChatsDelCliente(clienteID);
  }

  bool _todosSeleccionadosEstanFijados() {
    return _chatsSeleccionados.every((chatId) {
      final chat = _allChats.firstWhere(
        (c) => c.chatId == chatId,
        orElse: () => ChatResumen(
          chatId: '',
          clienteId: '',
          nombre: '',
          fotoUrl: '',
          lastMessage: '',
          unreadCount: 0,
          fijado: false,
        ),
      );
      return chat.fijado;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 55,
            titleSpacing: 12,
            title: _estaSeleccionando
                ? Text(
                    '${_chatsSeleccionados.length} seleccionado(s)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  )
                : _buildSearchBar(),
            actions: _estaSeleccionando
                ? [
                    IconButton(
                      icon: Icon(
                        _todosSeleccionadosEstanFijados()
                            ? LucideIcons.pinOff
                            : LucideIcons.pin,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      onPressed: () async {
                        final seleccionadosFijados =
                            _chatsSeleccionados.where((id) {
                          final chat =
                              _allChats.firstWhere((c) => c.chatId == id);
                          return chat.fijado;
                        }).toList();

                        final seleccionadosNoFijados =
                            _chatsSeleccionados.where((id) {
                          final chat =
                              _allChats.firstWhere((c) => c.chatId == id);
                          return !chat.fijado;
                        }).toList();

                        final seVanADesfijar = seleccionadosNoFijados.isEmpty;

                        if (!seVanADesfijar) {
                          final totalFijadosActuales =
                              _allChats.where((c) => c.fijado).length;
                          final nuevosFijados = seleccionadosNoFijados.length;

                          if (totalFijadosActuales + nuevosFijados > 2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Solo puedes fijar hasta 2 chats'),
                              ),
                            );
                            return;
                          }
                        }

                        for (final chatId in _chatsSeleccionados) {
                          final docRef = FirebaseFirestore.instance
                              .collection('chats')
                              .doc(chatId);
                          await docRef.update({'fijado': !seVanADesfijar});
                        }

                        setState(() {
                          _chatsSeleccionados.clear();
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _chatsSeleccionados.clear();
                        });
                      },
                    )
                  ]
                : null,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: ChatFiltroSelector(
                  onFiltroSelected: (filtro) {
                    setState(() {
                      filtroActivo = filtro;
                    });
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ChatResumen>>(
                  stream: _streamChats,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Color(0xFFFFAF00),
                          size: 50,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                          child: Text("Ocurrió un error inesperado."));
                    }
                    _allChats = snapshot.data ?? [];

                    List<ChatResumen> chats = [..._allChats];
                    if (filtroActivo == 'Leídos') {
                      chats = chats.where((c) => c.unreadCount == 0).toList();
                    } else if (filtroActivo == 'No leídos') {
                      chats = chats.where((c) => c.unreadCount > 0).toList();
                    }
                    final query = _searchController.text.toLowerCase();
                    if (query.isNotEmpty) {
                      chats = chats
                          .where((c) => c.nombre.toLowerCase().contains(query))
                          .toList();
                    }
                    if (chats.isEmpty) {
                      return Center(
                        child: Text(
                          "No hay chats disponibles.",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return ChatItemClienteWidget(
                            resumen: chat,
                            clienteId: clienteID,
                            seleccionado:
                                _chatsSeleccionados.contains(chat.chatId),
                            estaSeleccionando: _chatsSeleccionados.isNotEmpty,
                            onLongPress: (chatId) {
                              setState(() {
                                _chatsSeleccionados.contains(chatId)
                                    ? _chatsSeleccionados.remove(chatId)
                                    : _chatsSeleccionados.add(chatId);
                              });
                            },
                            onTap: (chatId) async {
                              if (_chatsSeleccionados.isNotEmpty) {
                                setState(() {
                                  _chatsSeleccionados.contains(chatId)
                                      ? _chatsSeleccionados.remove(chatId)
                                      : _chatsSeleccionados.add(chatId);
                                });
                                return;
                              }

                              final resumen =
                                  chats.firstWhere((c) => c.chatId == chatId);
                              final mensajesSnapshot = await FirebaseFirestore
                                  .instance
                                  .collection('chats')
                                  .doc(resumen.chatId)
                                  .collection('messages')
                                  .where('authorId',
                                      isEqualTo: resumen.clienteId)
                                  .get();

                              final batch = FirebaseFirestore.instance.batch();
                              for (var doc in mensajesSnapshot.docs) {
                                final readBy =
                                    List<String>.from(doc['readBy'] ?? []);
                                if (!readBy.contains(clienteID)) {
                                  batch.update(doc.reference, {
                                    'readBy': FieldValue.arrayUnion([clienteID])
                                  });
                                }
                              }
                              await batch.commit();
                              navegarConSlideDerecha(
                                context,
                                ContactoEmpresaScreen1(
                                  userIdVisitante: clienteID,
                                  empresaUserId: resumen.clienteId,
                                ),
                              );
                              if (mounted) {
                                setState(() {
                                  _streamChats =
                                      ChatService.obtenerChatsDelCliente(
                                          clienteID);
                                });
                              }
                            });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Theme(
      data: ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: Color(0xFFFFC800),
          cursorColor: Colors.black,
          selectionHandleColor: Colors.black,
        ),
      ),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.iconTheme.color,
                child: Icon(
                  Iconsax.arrow_left,
                  size: 20,
                  color: theme.scaffoldBackgroundColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17.0,
                  fontFamily: 'Afacad',
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: const InputDecoration(
                  hintText: 'Buscar chat...',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 17.0,
                    fontFamily: 'Afacad',
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _searchController.clear()),
                child: Icon(
                  Iconsax.close_circle,
                  size: 25,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              )
            else
              Icon(
                Iconsax.search_normal,
                size: 25,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
          ],
        ),
      ),
    );
  }
}

class ChatItemClienteWidget extends StatelessWidget {
  final ChatResumen resumen;
  final String clienteId;
  final bool seleccionado;
  final bool estaSeleccionando;
  final Function(String chatId) onLongPress;
  final Function(String chatId) onTap;

  const ChatItemClienteWidget({
    Key? key,
    required this.resumen,
    required this.clienteId,
    required this.seleccionado,
    required this.estaSeleccionando,
    required this.onLongPress,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onTap(resumen.chatId),
      onLongPress: () => onLongPress(resumen.chatId),
      child: Container(
        color: seleccionado ? Colors.grey[300] : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(resumen.fotoUrl),
              backgroundColor: Colors.grey[300],
              radius: 25,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resumen.nombre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resumen.lastMessage,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (resumen.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 0, 0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  resumen.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (resumen.fijado)
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  LucideIcons.pin,
                  size: 20,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
