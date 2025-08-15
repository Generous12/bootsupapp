import 'dart:convert';

import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/ModernInfoCard/cartasreutilizbles.dart';
import 'package:bootsup/widgets/SnackBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';

class IdentidadScreen extends StatefulWidget {
  @override
  _IdentidadScreenState createState() => _IdentidadScreenState();
}

class _IdentidadScreenState extends State<IdentidadScreen> {
  String dniUsuario = '';
  final TextEditingController _dniController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot userData =
            await _firestore.collection('users').doc(user.uid).get();

        setState(() {
          dniUsuario = userData['dni'] ?? ''; // Cargar el DNI del usuario
          _dniController.text = ''; // Dejar vacío para que ingrese un nuevo DNI
        });
      }
    } catch (e) {
      print('Error al cargar los datos del usuario: $e');
    }
  }

  Future<void> guardarDNI() async {
    final dni = _dniController.text.trim();

    if (dni.isEmpty || dni.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DNI inválido. Debe tener 8 dígitos.')),
      );
      return;
    }

    final token = 'sk_9430.gQKCaD0rLlm5Ktx13v8fKsLV29i602Mo';

    try {
      final uri =
          Uri.parse('https://api.decolecta.com/v1/reniec/dni?numero=$dni');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔍 STATUS CODE: ${response.statusCode}');
      print('🔍 BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dniValido = data['document_number'] == dni;

        if (dniValido) {
          // ✅ Guardar en Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .set({'dni': dni}, SetOptions(merge: true));

          SnackBarUtil.mostrarSnackBarPersonalizado(
            context: context,
            mensaje: 'Registro exitoso',
            icono: Icons.check_circle,
            colorFondo: const Color.fromARGB(255, 0, 0, 0),
          );
          await _loadUserData();
        } else {
          await showCustomDialog(
            context: context,
            title: 'DNI no encontrado',
            message:
                'El DNI ingresado no existe. Verifica e intenta nuevamente.',
            confirmButtonText: 'Cerrar',
          );
        }
      } else {
        await showCustomDialog(
          context: context,
          title: 'Error de búsqueda',
          message: 'No se pudo validar el DNI. Intenta más tarde.',
          confirmButtonText: 'Cerrar',
        );
      }
    } catch (e) {
      print('❌ Error guardando DNI: $e');
      await showCustomDialog(
        context: context,
        title: 'Error de conexión',
        message: 'Ocurrió un error al conectar con RENIEC: $e',
        confirmButtonText: 'Cerrar',
      );
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: theme.iconTheme.color,
            size: 25,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Numero de identidad',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[300],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Cuál es su número de DNI?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 30,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Por favor proporcione su nuevo número de DNI.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24.0),
              InfoCard(
                label: "Numero de identidad",
                value: dniUsuario,
                isEditable: false,
              ),
              const SizedBox(height: 16.0),
              EditableCard(
                controller: _dniController,
                onSave: () async {
                  final numero = _dniController.text.trim();
                  if (numero.isNotEmpty) {
                    guardarDNI();
                  }
                },
                label: "Numero de identidad",
                hintText: "ingresar du numero de identidad",
                isNumeric: true,
                maxLength: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
