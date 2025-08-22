// ignore_for_file: unused_local_variable

import 'package:bootsup/Clases/ChatResumen.dart';
import 'package:bootsup/Vista/EmpresaVista/GestionEmpresaPubli/ChatEmpresa/chatsClientes.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/BotonesSeleccionables.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChatClientesScreen extends StatefulWidget {
  const ChatClientesScreen({Key? key}) : super(key: key);

  @override
  State<ChatClientesScreen> createState() => _ChatClientesScreenState();
}

class _ChatClientesScreenState extends State<ChatClientesScreen> {
  final Color fondo = const Color(0xFFFAFAFA);
  final String empresaId = FirebaseAuth.instance.currentUser!.uid;
  String filtroActivo = 'Todos';

  final TextEditingController _searchController = TextEditingController();
  List<ChatResumen> _allChats = [];
  Set<String> _chatsSeleccionados = {};
  bool get _estaSeleccionando => _chatsSeleccionados.isNotEmpty;
  late Stream<List<ChatResumen>> _streamChats;

  @override
  void initState() {
    super.initState();
    _streamChats = obtenerChatsDeEmpresa(empresaId);
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

  Stream<List<ChatResumen>> obtenerChatsDeEmpresa(String empresaId) async* {
    final chatsStream = FirebaseFirestore.instance
        .collection('chats')
        .where('empresaUserId', isEqualTo: empresaId)
        .snapshots();

    await for (final chatSnapshot in chatsStream) {
      List<ChatResumen> lista = [];

      final userCache = <String, Map<String, dynamic>>{};

      await Future.wait(chatSnapshot.docs.map((doc) async {
        try {
          final data = doc.data();
          final userIds = List<String>.from(data['userIds'] ?? []);
          final clienteId =
              userIds.firstWhere((id) => id != empresaId, orElse: () => '');
          if (clienteId.isEmpty) return;

          if (!userCache.containsKey(clienteId)) {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(clienteId)
                .get();
            userCache[clienteId] = userDoc.data() ?? {};
          }

          final userData = userCache[clienteId]!;
          final nombre = userData['username'] ?? 'Cliente';
          final fotoUrl = userData['profileImageUrl'] ??
              'https://ui-avatars.com/api/?name=$nombre';

          final mensajesSnapshot = await FirebaseFirestore.instance
              .collection('chats')
              .doc(data['chatId'])
              .collection('messages')
              .where('authorId', isEqualTo: clienteId)
              .get();

          final unreadCount = mensajesSnapshot.docs
              .where((msg) =>
                  !(List<String>.from(msg['readBy'] ?? []).contains(empresaId)))
              .length;

          lista.add(ChatResumen(
            chatId: data['chatId'],
            clienteId: clienteId,
            nombre: nombre,
            fotoUrl: fotoUrl,
            lastMessage: data['lastMessage'] ?? '',
            unreadCount: unreadCount,
            fijado: data['fijado'] ?? false,
          ));
        } catch (e) {
          debugPrint('❌ Error al procesar chat: $e');
        }
      })); //MOSTRAR LOS NO LEIDOS PRIMERO
      lista.sort((a, b) {
        if (a.unreadCount > 0 && b.unreadCount == 0) {
          return -1;
        } else if (a.unreadCount == 0 && b.unreadCount > 0) {
          return 1;
        } else {
          return 0;
        }
      });
      yield lista;
    }
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

                        // Si todos los seleccionados están fijados, se van a DESFIJAR
                        final seVanADesfijar = seleccionadosNoFijados.isEmpty;

                        if (!seVanADesfijar) {
                          // Si se van a fijar, verifica si excede el límite de 2
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

                        // Actualiza el estado de los chats seleccionados
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
                      ));
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
                        return _ChatItemWidget(
                          resumen: chat,
                          empresaId: empresaId,
                          seleccionado:
                              _chatsSeleccionados.contains(chat.chatId),
                          estaSeleccionando: _estaSeleccionando,
                          onLongPress: (chatId) {
                            setState(() {
                              if (_chatsSeleccionados.contains(chatId)) {
                                _chatsSeleccionados.remove(chatId);
                              } else {
                                _chatsSeleccionados.add(chatId);
                              }
                            });
                          },
                          onTap: (chatId) async {
                            // solo se ejecuta si no está seleccionando
                            final mensajesSnapshot = await FirebaseFirestore
                                .instance
                                .collection('chats')
                                .doc(chat.chatId)
                                .collection('messages')
                                .where('authorId', isEqualTo: chat.clienteId)
                                .get();

                            final batch = FirebaseFirestore.instance.batch();
                            for (var doc in mensajesSnapshot.docs) {
                              final readBy =
                                  List<String>.from(doc['readBy'] ?? []);
                              if (!readBy.contains(empresaId)) {
                                batch.update(doc.reference, {
                                  'readBy': FieldValue.arrayUnion([empresaId])
                                });
                              }
                            }

                            await batch.commit();

                            if (!context.mounted) return;
                            navegarConSlideDerecha(
                              context,
                              ContactoEmpresaScreen(
                                userIdVisitante: chat.clienteId,
                                empresaUserId: empresaId,
                              ),
                            );
                            if (mounted) {
                              setState(() {
                                _streamChats = obtenerChatsDeEmpresa(empresaId);
                              });
                            }
                          },
                        );
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
        padding: EdgeInsets.symmetric(horizontal: 12),
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

class _ChatItemWidget extends StatelessWidget {
  final ChatResumen resumen;
  final String empresaId;
  final bool seleccionado;
  final bool estaSeleccionando;
  final Function(String chatId) onLongPress;
  final Function(String chatId) onTap;

  const _ChatItemWidget({
    required this.resumen,
    required this.empresaId,
    required this.seleccionado,
    required this.estaSeleccionando,
    required this.onLongPress,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onLongPress: () => onLongPress(resumen.chatId),
      onTap: () {
        if (estaSeleccionando) {
          onLongPress(resumen.chatId);
        } else {
          onTap(resumen.chatId);
        }
      },
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
