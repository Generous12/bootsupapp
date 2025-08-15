import 'package:bootsup/Modulos/ModuloPublicaciones/Moduloinicio.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class ComentariosScreen extends StatefulWidget {
  final String publicacionId;
  final String userId;

  const ComentariosScreen({
    required this.publicacionId,
    required this.userId,
    super.key,
  });

  @override
  State<ComentariosScreen> createState() => _ComentariosScreenState();
}

class _ComentariosScreenState extends State<ComentariosScreen> {
  final TextEditingController _comentarioCtrl = TextEditingController();

  Future<void> _comentar() async {
    if (_comentarioCtrl.text.trim().isEmpty) return;

    await FirestoreService().comentar(
        widget.publicacionId, widget.userId, _comentarioCtrl.text.trim());

    _comentarioCtrl.clear();
  }

  Future<void> _eliminarComentario(String comentarioId) async {
    await FirestoreService()
        .eliminarComentario(widget.publicacionId, comentarioId, widget.userId);
  }

  void _mostrarModalEliminar(
    BuildContext context,
    String comentarioId,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        height: 215,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.trash, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Eliminar comentario',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '¿Estás seguro de que deseas eliminar este comentario? Esta acción no se puede deshacer.',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close,
                      color: isDark ? Colors.white : Colors.black),
                  label: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Iconsax.trash,
                    size: 18,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  label: Text(
                    'Eliminar',
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    _eliminarComentario(comentarioId);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comentariosRef = FirebaseFirestore.instance
        .collection('publicaciones')
        .doc(widget.publicacionId)
        .collection('comentarios')
        .orderBy('fecha', descending: true);

    return SafeArea(
        child: GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: comentariosRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: Color(0xFFFFAF00),
                        size: 40,
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                        child: Text("Sé el primero en comentar"));
                  }

                  return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final usuarioId = data['usuarioId'];

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(usuarioId)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const ListTile(
                                title: Text("Cargando usuarios..."),
                              );
                            }

                            final userData = userSnapshot.data!.data()
                                as Map<String, dynamic>?;

                            if (userData == null) {
                              return const ListTile(
                                title: Text("Usuario no encontrado"),
                              );
                            }

                            final username =
                                userData['username'] ?? 'Sin nombre';
                            final profileImageUrl = userData['profileImageUrl'];

                            return GestureDetector(
                              onLongPress: () {
                                if (usuarioId == widget.userId) {
                                  _mostrarModalEliminar(
                                      context, docs[index].id);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 15),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 23,
                                      backgroundImage: profileImageUrl != null
                                          ? NetworkImage(profileImageUrl)
                                          : null,
                                      child: profileImageUrl == null
                                          ? const Icon(Icons.person, size: 20)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            data['texto'],
                                            style:
                                                const TextStyle(fontSize: 15),
                                          ),
                                          Row(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 0.0),
                                                child: Text(
                                                  timeago.format(
                                                      (data['fecha']
                                                              as Timestamp)
                                                          .toDate(),
                                                      locale: 'es'),
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.favorite_border,
                                                    size: 25),
                                                onPressed: () {
                                                  // Acción de Me gusta (opcional)
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      });
                },
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _comentarioCtrl,
                      label: "Comentario",
                      hintText: "Escribe un comentario...",
                      maxLength: 200,
                      maxLines: 3,
                      showCounter: false,
                    ),
                  ),
                  SizedBox(width: 5),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFAF00),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Iconsax.send_2),
                      onPressed: _comentar,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
