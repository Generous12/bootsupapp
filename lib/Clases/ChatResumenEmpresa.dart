class ChatResumenEmpresa {
  final String chatId;
  final String clienteId;
  final String nombreCliente;
  final String fotoClienteUrl;
  final String lastMessage;
  final int unreadCount;

  ChatResumenEmpresa({
    required this.chatId,
    required this.clienteId,
    required this.nombreCliente,
    required this.fotoClienteUrl,
    required this.lastMessage,
    required this.unreadCount,
  });
}
