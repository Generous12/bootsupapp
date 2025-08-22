import 'package:bootsup/Clases/ChatResumen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatServiceVinos {
  static const String empresaIdFija = 'empresa_unica';
  static const String coleccionChats = 'chatsVinos';

  static String generarChatIdUsuario(String usuarioId) {
    return '${usuarioId}_chat_empresa';
  }

  static Stream<List<ChatResumen>> obtenerChatsDelCliente(
      String clienteID) async* {
    final chatId = generarChatIdUsuario(clienteID);
    final chatDoc = FirebaseFirestore.instance
        .collection(coleccionChats)
        .doc(chatId)
        .snapshots();

    await for (final docSnapshot in chatDoc) {
      if (!docSnapshot.exists) {
        yield [];
        continue;
      }

      final data = docSnapshot.data()!;
      final lastMessage = data['lastMessage'] ?? '';
      final unreadCount = await _calcularMensajesNoLeidos(chatId, clienteID);

      yield [
        ChatResumen(
          chatId: chatId,
          clienteId: empresaIdFija,
          nombre: 'Empresa',
          fotoUrl: 'https://ui-avatars.com/api/?name=Empresa',
          lastMessage: lastMessage,
          unreadCount: unreadCount,
          fijado: data['fijado'] ?? false,
        )
      ];
    }
  }

  /// Calcula mensajes no leídos
  static Future<int> _calcularMensajesNoLeidos(
      String chatId, String clienteID) async {
    final mensajesSnapshot = await FirebaseFirestore.instance
        .collection(coleccionChats)
        .doc(chatId)
        .collection('messages')
        .where('authorId', isEqualTo: empresaIdFija)
        .get();

    return mensajesSnapshot.docs
        .where((msg) =>
            !(List<String>.from(msg['readBy'] ?? []).contains(clienteID)))
        .length;
  }

  /// Verifica o crea un chat para el usuario
  static Future<String> verificarOCrearChat(String usuarioID) async {
    final chatId = generarChatIdUsuario(usuarioID);
    final chatRef =
        FirebaseFirestore.instance.collection(coleccionChats).doc(chatId);

    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      await chatRef.set({
        'chatId': chatId,
        'userIds': [usuarioID, empresaIdFija],
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'creadoPor': usuarioID,
        'lastMessage': '',
        'fijado': false,
      });
      debugPrint('🆕 Nuevo chat creado con ID: $chatId');
    } else {
      debugPrint('✅ Chat existente encontrado: $chatId');
    }

    return chatId;
  }

  /// Escucha mensajes en tiempo real
  static Stream<List<types.TextMessage>> escucharMensajes(String chatId) {
    return FirebaseFirestore.instance
        .collection(coleccionChats)
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

  /// Envía un mensaje
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

    final chatRef =
        FirebaseFirestore.instance.collection(coleccionChats).doc(chatId);
    await chatRef.collection('messages').add(nuevoMensaje);

    await chatRef.set({'lastMessage': mensaje.text}, SetOptions(merge: true));
  }

  /// Elimina un mensaje
  static Future<void> eliminarMensaje({
    required String chatId,
    required String mensajeId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    try {
      await firestore
          .collection(coleccionChats)
          .doc(chatId)
          .collection('messages')
          .doc(mensajeId)
          .delete();

      final mensajesSnapshot = await firestore
          .collection(coleccionChats)
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

      await firestore
          .collection(coleccionChats)
          .doc(chatId)
          .update({'lastMessage': nuevoLastMessage});
      debugPrint("✅ lastMessage actualizado: $nuevoLastMessage");
    } catch (e) {
      debugPrint("❌ Error al eliminar mensaje o actualizar lastMessage: $e");
    }
  }
}
