import 'package:bootsup/Clases/ChatResumen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatService {
  static String generarChatIdOrdenado(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static Stream<List<ChatResumen>> obtenerChatsDelCliente(
      String clienteID) async* {
    final chatsStream = FirebaseFirestore.instance
        .collection('chats')
        .where('creadoPor', isEqualTo: clienteID)
        //.where('userIds', arrayContains: clienteID)

        .snapshots();

    await for (final chatSnapshot in chatsStream) {
      List<ChatResumen> lista = [];

      final userCache = <String, Map<String, dynamic>>{};

      for (var doc in chatSnapshot.docs) {
        final data = doc.data();
        final userIds = List<String>.from(data['userIds'] ?? []);
        final empresaId =
            userIds.firstWhere((id) => id != clienteID, orElse: () => '');

        if (empresaId.isEmpty) continue;

        final lastMessage = data['lastMessage'] ?? '';
        final chatId = data['chatId'];

        try {
          // Cacheo de empresa
          if (!userCache.containsKey(empresaId)) {
            final empresaDoc = await FirebaseFirestore.instance
                .collection('empresa')
                .doc(empresaId)
                .get();

            if (empresaDoc.exists) {
              userCache[empresaId] = empresaDoc.data()!;
            } else {
              debugPrint(
                  '⚠️ Empresa $empresaId no existe en la colección empresa');
              continue;
            }
          }

          final userData = userCache[empresaId]!;
          final nombre = userData['nombre'] ?? 'Empresa';
          final fotoUrl = userData['perfilEmpresa'] ??
              'https://ui-avatars.com/api/?name=$nombre';

          final mensajesSnapshot = await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .where('authorId', isEqualTo: empresaId)
              .get();

          final unreadCount = mensajesSnapshot.docs
              .where((msg) =>
                  !(List<String>.from(msg['readBy'] ?? []).contains(clienteID)))
              .length;

          lista.add(ChatResumen(
            chatId: chatId,
            clienteId: empresaId,
            nombre: nombre,
            fotoUrl: fotoUrl,
            lastMessage: lastMessage,
            unreadCount: unreadCount,
            fijado: data['fijado'] ?? false,
          ));
          lista.sort((a, b) {
            if (a.unreadCount > 0 && b.unreadCount == 0) {
              return -1;
            } else if (a.unreadCount == 0 && b.unreadCount > 0) {
              return 1;
            } else {
              return 0;
            }
          });
        } catch (e) {
          debugPrint('❌ Error al procesar empresa $empresaId: $e');
        }
      }

      yield lista;
    }
  }

  static Future<String> verificarOCrearChat({
    required String chatId,
    required String userIdVisitante,
    required String empresaUserId,
  }) async {
    final chats = await FirebaseFirestore.instance
        .collection('chats')
        //    .where('userIds', arrayContains: userIdVisitante)
        .where('creadoPor', isEqualTo: userIdVisitante)
        .get();

    for (final doc in chats.docs) {
      final userIds = List<String>.from(doc['userIds'] ?? []);
      if (userIds.contains(empresaUserId)) {
        debugPrint('✅ Chat existente encontrado: ${doc.id}');
        return doc.id;
      }
    }

    // Si no existe, lo crea
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    await chatRef.set({
      'chatId': chatId,
      'userIds': [userIdVisitante, empresaUserId],
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'empresaUserId': empresaUserId,
      'creadoPor': userIdVisitante,
      'lastMessage': '',
      'fijado': false,
    });

    debugPrint('🆕 Nuevo chat creado con ID: $chatId');
    return chatId;
  }

  /// Escucha mensajes en tiempo real
  static Stream<List<types.TextMessage>> escucharMensajes(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return types.TextMessage(
          id: doc.id,
          author: types.User(id: data['authorId']),
          createdAt: data['createdAt'],
          text: data['text'],
        );
      }).toList();
    });
  }

  /// Envía un nuevo mensaje
  static Future<void> enviarMensaje({
    required String chatId,
    required String userId,
    required types.PartialText mensaje,
  }) async {
    final nuevoMensaje = {
      'authorId': userId,
      'text': mensaje.text,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'readBy': [],
    };

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // Agregar mensaje
    await chatRef.collection('messages').add(nuevoMensaje);

    // Obtener el documento actual del chat
    final chatDoc = await chatRef.get();

    // Solo si no existe el campo "creadoPor", lo agregamos
    if (!chatDoc.exists || !chatDoc.data()!.containsKey('creadoPor')) {
      await chatRef.set({
        'creadoPor': userId,
        'lastMessage': mensaje.text,
      }, SetOptions(merge: true));
    } else {
      // Si ya tiene "creadoPor", solo actualizamos los mensajes recientes
      await chatRef.update({
        'lastMessage': mensaje.text,
      });
    }
  }

  /// Obtiene los datos de la empresa desde Firestore
  static Future<Map<String, dynamic>?> fetchEmpresaData(String userId) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('empresa').doc(userId);

      final cacheSnapshot =
          await docRef.get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.exists) {
        return cacheSnapshot.data();
      }

      final networkSnapshot =
          await docRef.get(const GetOptions(source: Source.server));

      if (networkSnapshot.exists) {
        return networkSnapshot.data();
      }

      return null;
    } catch (e) {
      print('Error al obtener datos de empresa: $e');
      return null;
    }
  }

  /// FALTA USAR---Elimina un mensaje del chat y actualiza el campo `lastMessage`
  static Future<void> eliminarMensaje({
    required String chatId,
    required String mensajeId,
  }) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. Eliminar el mensaje
      await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(mensajeId)
          .delete();

      debugPrint("✅ Mensaje eliminado correctamente.");

      // 2. Obtener el nuevo último mensaje (si queda alguno)
      final mensajesSnapshot = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      String nuevoLastMessage = 'Se eliminó un mensaje';

      if (mensajesSnapshot.docs.isNotEmpty) {
        final ultimoMensaje = mensajesSnapshot.docs.first.data();
        nuevoLastMessage = ultimoMensaje['text'] ?? 'Mensaje';
      }

      // 3. Actualizar el campo lastMessage en el documento del chat
      await firestore.collection('chats').doc(chatId).update({
        'lastMessage': nuevoLastMessage,
      });

      debugPrint("✅ lastMessage actualizado: $nuevoLastMessage");
    } catch (e) {
      debugPrint("❌ Error al eliminar mensaje o actualizar lastMessage: $e");
    }
  }
}
