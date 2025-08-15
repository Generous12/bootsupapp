import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/foundation.dart';

class ChatServiceEmpresa {
  static Future<String> verificarOCrearChat({
    required String chatId,
    required String userIdVisitante, // cliente
    required String empresaUserId,
  }) async {
    try {
      // Buscar si ya existe un chat creado por el cliente con esta empresa
      final chats = await FirebaseFirestore.instance
          .collection('chats')
          .where('creadoPor', isEqualTo: userIdVisitante)
          .get();

      for (final doc in chats.docs) {
        final userIds = List<String>.from(doc['userIds'] ?? []);
        if (userIds.contains(empresaUserId)) {
          debugPrint('✅ Chat existente encontrado (empresa): ${doc.id}');
          return doc.id;
        }
      }

      // Si no existe, se crea
      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      await chatRef.set({
        'chatId': chatId,
        'userIds': [userIdVisitante, empresaUserId],
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'empresaUserId': empresaUserId,
        'creadoPor':
            userIdVisitante, // importante para mantener misma estructura
        'lastMessage': '',
        'fijado': false,
      });

      debugPrint('🆕 Nuevo chat creado desde empresa con ID: $chatId');
      return chatId;
    } catch (e) {
      debugPrint('❌ Error en verificarOCrearChat (empresa): $e');
      return chatId; // fallback en caso de error
    }
  }

  /// Escucha los últimos 30 mensajes en tiempo real
  static Stream<List<types.TextMessage>> escucharMensajes(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(30)
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

  /// Envía un mensaje de texto al chat
  static Future<void> enviarMensaje({
    required String chatId,
    required String authorId,
    required types.PartialText mensaje,
  }) async {
    if (mensaje.text.trim().isEmpty) return;

    final nuevoMensaje = {
      'authorId': authorId,
      'text': mensaje.text.trim(),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'readBy': [],
    };

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    try {
      await chatRef.collection('messages').add(nuevoMensaje);
      await chatRef.update({
        'lastMessage': mensaje.text.trim(),
      });
    } catch (e) {
      debugPrint("❌ Error al enviar mensaje: $e");
    }
  }

  /// Carga los datos del cliente (usuario visitante)
  static Future<Map<String, dynamic>?> cargarDatosCliente(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      final cacheDoc =
          await userRef.get(const GetOptions(source: Source.cache));
      final Map<String, dynamic>? cacheData = cacheDoc.data();

      final networkDoc =
          await userRef.get(const GetOptions(source: Source.server));
      final Map<String, dynamic>? networkData = networkDoc.data();

      // Retorna primero lo de red si está disponible
      return networkData ?? cacheData;
    } catch (e) {
      debugPrint("❌ Error cargando datos cliente: $e");
      return null;
    }
  }

//ELIMINAR MENSAJE SELECCIONADO
  static Future<void> eliminarMensaje({
    required String chatId,
    required String mensajeId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(mensajeId)
          .delete();

      debugPrint("✅ Mensaje eliminado correctamente.");

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

      await firestore.collection('chats').doc(chatId).update({
        'lastMessage': nuevoLastMessage,
      });
    } catch (e) {
      debugPrint("❌ Error al eliminar el mensaje y actualizar lastMessage: $e");
    }
  }
}
