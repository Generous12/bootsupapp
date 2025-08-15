import 'dart:math';
import 'package:bootsup/Vista/autenticacion/SplashScreen.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/Bottombar/bottombar.dart';
import 'package:bootsup/widgets/Providers/themeProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  Future<User?> checkSignInStatus(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      await signInWithGoogle(context);
      return _auth.currentUser;
    } else {
      return user;
    }
  }

  Future<bool> signInWithEmail(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      await showCustomDialog(
        context: context,
        title: 'Atención',
        message: 'Complete todos los campos',
        confirmButtonText: 'Cerrar',
      );
      return false;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      await showCustomDialog(
        context: context,
        title: 'Atención',
        message: 'Formato de correo inválido',
        confirmButtonText: 'Cerrar',
      );
      return false;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Correo o contraseña incorrectos';
      if (e.code == 'user-disabled') {
        errorMessage = 'Cuenta deshabilitada, contacte soporte';
      }

      await showCustomDialog(
        context: context,
        title: 'Error de autenticación',
        message: errorMessage,
        confirmButtonText: 'Cerrar',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      String email = userCredential.user!.email!;
      String displayName = userCredential.user!.displayName ?? 'Usuario';

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      String usernameWithNumber;

      if (userDoc.exists) {
        usernameWithNumber = userDoc['username'];
      } else {
        String randomNumber =
            Random().nextInt(999999).toString().padLeft(6, '0');
        usernameWithNumber = '$displayName#$randomNumber';

        String profileImageUrl = userCredential.user!.photoURL ?? '';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': usernameWithNumber,
          'email': email,
          'profileImageUrl': profileImageUrl,
          'direccion': '',
          'dni': '',
          'telefono': '',
          'membresia': 'Clientes',
        });
      }

      return true;
    } catch (e) {
      print('Error en login: $e');
      if (e is PlatformException && e.code == 'sign_in_canceled') {
        return false;
      }
      await showCustomDialog(
        context: context,
        title: 'Error de autenticación',
        message: 'No se pudo iniciar sesión con Google. Inténtalo nuevamente.',
        confirmButtonText: 'Cerrar',
      );
      return false;
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      await _auth.signOut();
      await _googleSignIn.signOut();
      ImageCacheHelper.clearCache();
      themeProvider.resetTheme();
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
    } catch (e) {}
  }
}
