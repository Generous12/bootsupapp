import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/ModernInfoCard/cartasreutilizbles.dart';
import 'package:bootsup/widgets/SnackBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CorreoScreen extends StatefulWidget {
  @override
  _CorreoScreenState createState() => _CorreoScreenState();
}

class _CorreoScreenState extends State<CorreoScreen> {
  String emailUsuario = '';
  final TextEditingController _emailController = TextEditingController();
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
          emailUsuario = userData['email'] ?? '';
          _emailController.text = '';
        });
      }
    } catch (e) {
      print('Error al cargar los datos del usuario: $e');
    }
  }

  Future<bool> _checkEmailVerified(User user) async {
    for (int i = 0; i < 60; i++) {
      await Future.delayed(const Duration(seconds: 1));
      await user.reload();
      user = _auth.currentUser!;
      if (user.emailVerified) {
        return true;
      }
    }
    return false;
  }

  Future<void> _updateUserData() async {
    setState(() {});
    if (_emailController.text.isEmpty) {
      await showCustomDialog(
        context: context,
        title: 'Campo vacío',
        message: 'Por favor, ingresr un correo',
        confirmButtonText: 'Cerrar',
      );
      return;
    }

    try {
      User? user = _auth.currentUser;

      if (user != null) {
        String nuevoEmail = _emailController.text.trim();

        await user.updateEmail(nuevoEmail);

        bool emailVerified = await _checkEmailVerified(user);

        if (emailVerified) {
          await _firestore.collection('users').doc(user.uid).update({
            'email': nuevoEmail,
          });

          setState(() {
            emailUsuario = nuevoEmail;
            _emailController.clear();
          });

          SnackBarUtil.mostrarSnackBarPersonalizado(
            context: context,
            mensaje: 'Registro exitoso',
            icono: Icons.check_circle,
            colorFondo: const Color.fromARGB(255, 0, 0, 0),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Verificación de correo fallida. Intenta nuevamente.')),
          );
        }
      }
    } catch (e) {
      print('Error al actualizar los datos del usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el correo: $e')),
      );
    } finally {
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
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 48,
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
          'Correo electronico',
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
                '¿Cuál es su correo electrónico?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 30,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Proporcione un nuevo correo electrónico donde podamos contactarlo.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24.0),
              InfoCard(
                label: ' Correo electronico',
                value: emailUsuario,
                isEditable: false,
              ),
              const SizedBox(height: 16.0),
              EditableCard(
                controller: _emailController,
                onSave: () async {
                  final nuevoValor = _emailController.text.trim();
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
}
