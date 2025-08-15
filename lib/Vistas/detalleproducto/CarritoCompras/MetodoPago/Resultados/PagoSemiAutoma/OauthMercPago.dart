import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class MercadoPagoOAuthWebView extends StatefulWidget {
  final String url;

  const MercadoPagoOAuthWebView({super.key, required this.url});

  @override
  State<MercadoPagoOAuthWebView> createState() =>
      _MercadoPagoOAuthWebViewState();
}

class _MercadoPagoOAuthWebViewState extends State<MercadoPagoOAuthWebView> {
  WebViewController? _controller;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    final cookieManager = WebViewCookieManager();
    cookieManager.clearCookies().then((_) {
      _initWebView();
    });
  }

  void _initWebView() {
    setState(() {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) async {
              if (url.contains('/ok')) {
                if (userId != null) {
                  try {
                    final confirmResponse = await http.post(
                      Uri.parse(
                          'https://bootsupapp-production.up.railway.app/confirmar-mercadopago'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({'userId': userId}),
                    );

                    if (confirmResponse.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Datos de Mercado Pago almacenados correctamente')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Error al almacenar los datos')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al confirmar: $e')),
                    );
                  }
                }

                Navigator.pop(context); // Cerramos la WebView solo al confirmar
              }
            },
            onWebResourceError: (error) {
              // Solo mostrar un mensaje, no cerrar automáticamente
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Error al cargar la página: ${error.description}')),
              );
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Conectar Mercado Pago')),
      body: WebViewWidget(controller: _controller!),
    );
  }
}
