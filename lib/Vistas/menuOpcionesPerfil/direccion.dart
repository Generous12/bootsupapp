import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/ModernInfoCard/cartasreutilizbles.dart';
import 'package:bootsup/widgets/SnackBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

class DireccionScreen extends StatefulWidget {
  @override
  _DireccionScreenState createState() => _DireccionScreenState();
}

class _DireccionScreenState extends State<DireccionScreen> {
  String direccionUsuario = '';
  final TextEditingController _direccionController = TextEditingController();
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
          direccionUsuario = userData['direccion'] ?? ''; // Cargar la dirección
          _direccionController.text =
              ''; // Dejar vacío para que ingrese una nueva dirección
        });
      }
    } catch (e) {
      print('Error al cargar los datos del usuario: $e');
    }
  }

  Future<void> _updateUserData() async {
    setState(() {});

    try {
      User? user = _auth.currentUser;

      if (user != null) {
        String nuevaDireccion = _direccionController.text.trim();

        // Validar que la dirección no esté vacía
        if (nuevaDireccion.isEmpty) {
          setState(() {
            showCustomDialog(
              context: context,
              title: 'Error',
              message: 'Los campos no pueden estar vacios',
              confirmButtonText: 'Cerrar',
            );
          });
          return; // Salir si no es válido
        }

        // Actualizar los datos del usuario en Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'direccion': nuevaDireccion,
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
            content: Text('Error al actualizar la dirección: ${e.toString()}')),
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
        titleSpacing: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 48,
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
          'Direccion de domicilio',
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
                '¿Cuál es su dirección?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 30,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Por favor proporcione su nueva dirección.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24.0),
              InfoCard(
                label: "Dirección actual",
                value: direccionUsuario,
                isEditable: false,
              ),
              const SizedBox(height: 16.0),
              EditableCard(
                controller: _direccionController,
                onSave: () async {
                  final edad = _direccionController.text.trim();
                  if (edad.isNotEmpty) {
                    _updateUserData();
                  }
                },
                label: "Direccion",
                hintText: "Ingresar nueva dirección",
                isNumeric: false,
                maxLength: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
