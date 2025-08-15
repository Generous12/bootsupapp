import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRPagoScreen extends StatelessWidget {
  final String qrUrl;

  const QRPagoScreen({Key? key, required this.qrUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Escanea y paga con Yape"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Abre tu app de Yape y escanea este código QR para pagar.",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            QrImageView(
              data: qrUrl,
              version: QrVersions.auto,
              size: 250.0,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.check_circle),
              label: Text("Ya pagué"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );
  }
}
