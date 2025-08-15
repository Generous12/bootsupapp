class ChatResumen {
  final String chatId;
  final String clienteId;
  final String nombre;
  final String fotoUrl;
  final String lastMessage;
  final int unreadCount;
  final bool fijado;

  ChatResumen({
    required this.chatId,
    required this.clienteId,
    required this.nombre,
    required this.fotoUrl,
    required this.lastMessage,
    required this.unreadCount,
    this.fijado = false,
  });
}
