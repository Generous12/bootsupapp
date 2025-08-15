import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MetodoPagoResultadoScreen extends StatefulWidget {
  final String preferenceUrl;
  const MetodoPagoResultadoScreen({super.key, required this.preferenceUrl});

  @override
  State<MetodoPagoResultadoScreen> createState() =>
      _MetodoPagoResultadoScreenState();
}

class _MetodoPagoResultadoScreenState extends State<MetodoPagoResultadoScreen> {
  late final WebViewController _controller;
  bool _navegado = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (_navegado) return;
            if (url.contains('success')) {
              _navegado = true;
              Navigator.pop(context, 'success');
            } else if (url.contains('failure')) {
              _navegado = true;
              Navigator.pop(context, 'failure');
            } else if (url.contains('pending')) {
              _navegado = true;
              Navigator.pop(context, 'pending');
            }
          },
          onWebResourceError: (error) {},
        ),
      )
      ..loadRequest(Uri.parse(widget.preferenceUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: _controller),
    );
  }
}
