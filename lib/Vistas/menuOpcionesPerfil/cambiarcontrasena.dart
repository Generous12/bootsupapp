import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:iconsax/iconsax.dart';

class PasswordScreen1 extends StatefulWidget {
  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen1> {
  final TextEditingController currentPasswordController =
      TextEditingController();
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

  Future<void> _changePassword() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (currentPasswordController.text.isEmpty) {
        await showCustomDialog(
          context: context,
          title: 'Campo vacío',
          message: 'Por favor, ingresa tu contraseña actual',
          confirmButtonText: 'Cerrar',
        );

        setState(() => isLoading = false);
        return;
      }

      if (passwordController.text.isEmpty) {
        await showCustomDialog(
          context: context,
          title: 'Campo vacío',
          message: 'Por favor, ingresa una nueva contraseña',
          confirmButtonText: 'Cerrar',
        );
        setState(() => isLoading = false);
        return;
      }

      final user = _auth.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-logged-in',
          message: 'El usuario no está autenticado.',
        );
      }

      final email = user.email;
      if (email == null) {
        throw FirebaseAuthException(
          code: 'user-email-null',
          message: 'El correo del usuario no está disponible.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      if (arePasswordsEqual &&
          hasMinLength &&
          hasLowercase &&
          hasUppercase &&
          hasNumber) {
        await user.updatePassword(passwordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Contraseña actualizada exitosamente.',
              style: TextStyle(),
            ),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );

        Navigator.pop(context);
      } else {
        throw FirebaseAuthException(
          code: 'password-requirements-not-met',
          message: 'La nueva contraseña no cumple con los requisitos.',
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Ocurrió un error al cambiar la contraseña.',
            style: TextStyle(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
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
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
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
          'Cambiar contraseña',
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              '¿Actualizaras nueva contraseña?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 30,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Por favor proporcione su nueva contraseña actualizada',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24.0),
            CustomTextField(
              controller: currentPasswordController,
              label: "Ingrese su contraseña actual",
              prefixIcon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 10.0),
            CustomTextField(
              controller: passwordController,
              label: "Ingrese una nueva contraseña",
              prefixIcon: Icons.lock,
              obscureText: true,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: hasMinLength,
                      onChanged: null,
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                        (states) =>
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                    Text(
                      'Min 8 caracteres',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Checkbox(
                      value: hasLowercase,
                      onChanged: null,
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                        (states) =>
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                    Text(
                      'Una minúscula',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: hasUppercase,
                      onChanged: null,
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                        (states) =>
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                    Text(
                      'Una mayúscula',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Checkbox(
                      value: hasNumber,
                      onChanged: null,
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                        (states) =>
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                    Text(
                      'Un número',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            CustomTextField(
              controller: repeatPasswordController,
              label: "Repita la nueva contraseña",
              prefixIcon: Icons.lock_outline,
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
            LoadingOverlayButton(
              text: 'Actualizar contraseña',
              onPressedLogic: () async {
                _changePassword();
              },
            )
          ],
        ),
      ),
    );
  }
}
