// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print

import 'package:bootsup/widgets/ModernInfoCard/cartasreutilizbles.dart';
import 'package:bootsup/widgets/SnackBar.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

class TelefonoScreen extends StatefulWidget {
  @override
  _TelefonoScreenState createState() => _TelefonoScreenState();
}

class _TelefonoScreenState extends State<TelefonoScreen> {
  String telefonoUsuario = '';
  final TextEditingController _telefonoController = TextEditingController();
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
          telefonoUsuario = userData['telefono'] ?? '';
          _telefonoController.text = '';
        });
      }
    } catch (e) {
      print('Error al cargar los datos del usuario: $e');
    }
  }

  Future<void> _updateUserData() async {
    setState(() {
// Iniciar la carga
    });

    try {
      User? user = _auth.currentUser;

      if (user != null) {
        String nuevoTelefono = _telefonoController.text.trim();

        // Actualizar los datos del usuario en Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'telefono': nuevoTelefono,
        });
        await _loadUserData();
        // Mostrar alerta de éxito
        SnackBarUtil.mostrarSnackBarPersonalizado(
          context: context,
          mensaje: 'Registro exitoso',
          icono: Icons.check_circle,
          colorFondo: const Color.fromARGB(255, 0, 0, 0),
        );
      }
    } catch (e) {
      print('Error al actualizar los datos del usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al actualizar el teléfono: ${e.toString()}')),
      );
    } finally {
      setState(() {
// Finalizar la carga
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 48,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
          'Numero de telefono',
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
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Cuál es su número de teléfono?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 30,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Por favor proporcione su nuevo número de teléfono.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24.0),
              InfoCard(
                label: "Numero de telefono actual",
                value: telefonoUsuario,
                isEditable: false,
              ),
              const SizedBox(height: 16.0),
              EditableCard(
                controller: _telefonoController,
                onSave: () async {
                  final numero = _telefonoController.text.trim();
                  if (numero.isNotEmpty) {
                    _updateUserData();
                  }
                },
                label: "Numero de telefono",
                hintText: "Ingresar numero de telefono",
                isNumeric: true,
                maxLength: 9,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoContainer(String label, String value, bool isEditable) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value.isNotEmpty ? value : 'No especificado',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEditableContainer() {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _telefonoController,
            label: "Ingresar numero de telefono",
            isNumeric: true,
            maxLength: 9,
            showCounter: false,
          ),
          const SizedBox(height: 20.0),
          LoadingOverlayButton(
            text: 'Guardar',
            onPressedLogic: () async {
              _updateUserData();
            },
          )
        ],
      ),
    );
  }
}
