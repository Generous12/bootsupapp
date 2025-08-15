// ignore_for_file: sized_box_for_whitespace

import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/ModernInfoCard/cartasreutilizbles.dart';
import 'package:bootsup/widgets/SnackBar.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:iconsax/iconsax.dart';

class NombreScreen extends StatefulWidget {
  @override
  _NombreScreenState createState() => _NombreScreenState();
}

class _NombreScreenState extends State<NombreScreen> {
  String nombreUsuario = '';
  final TextEditingController _nombreController = TextEditingController();
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
          nombreUsuario = userData['username'] ?? '';
          _nombreController.text = '';
        });
      }
    } catch (e) {
      print('Error al cargar los datos del usuario: $e');
    }
  }

  String _generateRandomNumber() {
    final Random random = Random();
    int randomNumber = random.nextInt(900000) + 100000;
    return randomNumber.toString();
  }

  Future<void> _updateUserData() async {
    setState(() {});

    try {
      User? user = _auth.currentUser;

      if (user != null) {
        String nuevoNombre = _nombreController.text.trim();

        if (nuevoNombre.isEmpty) {
          await showCustomDialog(
            context: context,
            title: 'Campo vacío',
            message: 'Por favor, ingresa un nombre de usuario',
            confirmButtonText: 'Cerrar',
          );
          setState(() {});
          return;
        }

        String nuevoNombreConNumero = '$nuevoNombre#${_generateRandomNumber()}';

        await _firestore.collection('users').doc(user.uid).update({
          'username': nuevoNombreConNumero,
        });

        setState(() {
          nombreUsuario = nuevoNombreConNumero;
          _nombreController.clear();
        });

        SnackBarUtil.mostrarSnackBarPersonalizado(
          context: context,
          mensaje: 'Registro exitoso',
          icono: Icons.check_circle,
          colorFondo: const Color.fromARGB(255, 0, 0, 0),
        );
      }
    } catch (e) {
      print('Error al actualizar los datos del usuario: $e');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 0,
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
          'Nombre de usuario',
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
                '¿Cómo desea que le llamemos?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 30,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Proporcione un nuevo nombre de usuario que lo represente.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24.0),
              InfoCard(
                label: 'Nombre de usuario actual',
                value: nombreUsuario,
                isEditable: false,
              ),
              const SizedBox(height: 16.0),
              EditableCard(
                controller: _nombreController,
                onSave: () async {
                  final nuevoValor = _nombreController.text.trim();
                  if (nuevoValor.isNotEmpty) {
                    _updateUserData();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEditableContainer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.edit_2,
                color: Colors.amber,
                size: 22,
              ),
              const SizedBox(width: 8.0),
              Text(
                "Editar información",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          CustomTextField(
            controller: _nombreController,
            label: "Nuevo nombre de usuario",
            isNumeric: false,
            maxLength: 15,
            hintText: "Ingresar nombre de usuario",
          ),
          const SizedBox(height: 20.0),
          LoadingOverlayButton(
            text: 'Guardar',
            onPressedLogic: () async {
              _updateUserData();
            },
          ),
        ],
      ),
    );
  }

  Widget buildInfoContainer(String label, String value, bool isEditable) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isEditable ? Iconsax.edit : Iconsax.information,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'No especificado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
