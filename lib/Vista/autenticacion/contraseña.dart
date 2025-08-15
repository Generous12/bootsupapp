import 'package:bootsup/Vista/autenticacion/verificarCorreo.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:iconsax/iconsax.dart';

class PasswordScreen extends StatefulWidget {
  final String email;
  final String username;

  PasswordScreen({required this.email, required this.username});

  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController =
      TextEditingController();
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool arePasswordsEqual = true;

  bool hasMinLength = false;
  bool hasLowercase = false;
  bool hasUppercase = false;
  bool hasNumber = false;

  @override
  void initState() {
    super.initState();

    passwordController.addListener(_checkPasswordRequirements);
    repeatPasswordController.addListener(() {
      setState(() {
        arePasswordsEqual =
            passwordController.text == repeatPasswordController.text;
      });
    });
  }

  void _checkPasswordRequirements() {
    setState(() {
      hasMinLength = passwordController.text.length >= 8;
      hasLowercase = passwordController.text.contains(RegExp(r'[a-z]'));
      hasUppercase = passwordController.text.contains(RegExp(r'[A-Z]'));
      hasNumber = passwordController.text.contains(RegExp(r'[0-9]'));
    });
  }

  void signUpWithEmail(BuildContext context) async {
    if (passwordController.text != repeatPasswordController.text) {
      await showCustomDialog(
        context: context,
        title: 'Contraseña',
        message: 'Las contraseñas no coinciden',
        confirmButtonText: 'Cerrar',
      );
      return;
    }

    if (!hasMinLength || !hasLowercase || !hasUppercase || !hasNumber) {
      await showCustomDialog(
        context: context,
        title: 'Requisitos de contraseña',
        message: 'Este es un mensaje informativo',
        confirmButtonText: 'Cerrar',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: passwordController.text,
      );

      await userCredential.user!.sendEmailVerification();

      setState(() {
        isLoading = false;
      });

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              VerificarCorreoPage(
            user: userCredential.user!,
            email: widget.email,
            password: passwordController.text,
            username: widget.username,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(
                Tween(begin: 0.0, end: 1.0).chain(
                  CurveTween(curve: Curves.easeIn),
                ),
              ),
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      print('Error al registrarse: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: theme.iconTheme.color,
            size: 25,
          ),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Contraseña',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Correo Electrónico',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: TextEditingController(text: widget.email),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                readOnly: true,
                decoration: InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: const Color.fromARGB(255, 30, 30, 30),
                      width: 0.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nombre de usuario',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              TextField(
                controller: TextEditingController(text: widget.username),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                readOnly: true,
                decoration: InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: const Color.fromARGB(255, 30, 30, 30),
                      width: 0.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              const SizedBox(height: 8.0),
              CustomTextField(
                controller: passwordController,
                label: "Ingrese una contraseña",
                prefixIcon: Iconsax.lock,
                obscureText: true,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(value: hasMinLength, onChanged: null),
                      Text(
                        'Min 8 caracteres',
                        style: TextStyle(),
                      ),
                      const SizedBox(width: 12),
                      Checkbox(value: hasLowercase, onChanged: null),
                      Text(
                        'Una minúscula',
                        style: TextStyle(),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(value: hasUppercase, onChanged: null),
                      Text(
                        'Una mayúscula',
                        style: TextStyle(),
                      ),
                      const SizedBox(width: 20),
                      Checkbox(value: hasNumber, onChanged: null),
                      Text(
                        'Un número',
                        style: TextStyle(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              const SizedBox(height: 8.0),
              CustomTextField(
                controller: repeatPasswordController,
                label: "Repita la contraseña",
                prefixIcon: Iconsax.lock5,
                obscureText: true,
              ),
              if (repeatPasswordController.text.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    arePasswordsEqual
                        ? 'Las contraseñas son idénticas'
                        : 'Las contraseñas no coinciden',
                    style: TextStyle(
                      color: arePasswordsEqual
                          ? const Color.fromARGB(255, 0, 0, 0)
                          : const Color.fromARGB(255, 255, 17, 0),
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28.0),
              Stack(
                alignment: Alignment.center,
                children: [
                  LoadingOverlayButton(
                    text: 'Verificar correo',
                    onPressedLogic: () async {
                      FocusScope.of(context).unfocus();
                      await Future.delayed(Duration(milliseconds: 500));
                      signUpWithEmail(context);
                    },
                  )
                ],
              ),
              const SizedBox(height: 5.0),
            ],
          ),
        ),
      ),
    );
  }
}
