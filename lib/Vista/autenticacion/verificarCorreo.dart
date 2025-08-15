import 'dart:async';
import 'dart:math';
import 'package:bootsup/Vista/autenticacion/SplashScreen.dart';
import 'package:bootsup/Vistas/screensPrincipales/MainScreen.dart';
import 'package:bootsup/widgets/SnackBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerificarCorreoPage extends StatefulWidget {
  final User user;
  final String email;
  final String password;
  final String username;

  const VerificarCorreoPage({
    Key? key,
    required this.user,
    required this.email,
    required this.password,
    required this.username,
  }) : super(key: key);

  @override
  State<VerificarCorreoPage> createState() => _VerificarCorreoPageState();
}

class _VerificarCorreoPageState extends State<VerificarCorreoPage> {
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  bool _isChecking = false;
  bool _hasResentOnce = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      setState(() {
        _secondsRemaining--;
      });

      if (_secondsRemaining <= 0) {
        timer.cancel();
        if (_hasResentOnce) {
          await _deleteUnverifiedUser();
          if (mounted) {
            SnackBarUtil.mostrarSnackBarPersonalizado(
              context: context,
              mensaje: 'Su correo no fue verificado a tiempo.',
              icono: Icons.warning,
              colorFondo: const Color.fromARGB(255, 0, 0, 0),
            );
            Navigator.pop(context);
          }
        } else {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && !user.emailVerified && !_hasResentOnce) {
      setState(() {
        _isResending = true;
      });

      try {
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          await refreshedUser.sendEmailVerification();
          _hasResentOnce = true;

          _startTimer();

          SnackBarUtil.mostrarSnackBarPersonalizado(
            context: context,
            mensaje: 'Correo reenviado. Verifica tu bandeja.',
            icono: Icons.check_circle_outline_outlined,
            colorFondo: Colors.redAccent,
          );
        } else {
          SnackBarUtil.mostrarSnackBarPersonalizado(
            context: context,
            mensaje: 'Tu correo ya está verificado.',
            icono: Icons.check_circle,
            colorFondo: Colors.redAccent,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al reenviar el correo.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _checkIfEmailVerified() async {
    setState(() {
      _isChecking = true;
    });

    await widget.user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      // Usuario verificó el correo, guardar datos en Firestore
      String randomNumber = Random().nextInt(999999).toString().padLeft(6, '0');
      String usernameWithNumber = '${widget.username}#$randomNumber';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
        'username': usernameWithNumber,
        'email': widget.email,
        'profileImageUrl': '',
        'direccion': '',
        'dni': '',
        'telefono': '',
        'membresia': 'Clientes',
      });

      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              MainScreen(user: FirebaseAuth.instance.currentUser),
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
    } else {
      await _deleteUnverifiedUser();

      SnackBarUtil.mostrarSnackBarPersonalizado(
        context: context,
        mensaje: 'Su correo no fue verificado a tiempo.',
        icono: Icons.close,
        colorFondo: Colors.redAccent,
      );

      Navigator.pop(context);
    }

    setState(() {
      _isChecking = false;
    });
  }

  Future<void> _deleteUnverifiedUser() async {
    try {
      await widget.user.delete();
    } catch (e) {
      print('Error eliminando usuario no verificado: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 248, 248, 248),
        elevation: 0, // Sin sombra para evitar cambios de tonalidad
        scrolledUnderElevation:
            0, // Importante en versiones recientes de Flutter
        surfaceTintColor:
            Colors.transparent, // Evita cualquier efecto dinámico de color
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            _deleteUnverifiedUser();
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 248, 248, 248),
      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.height *
              0.8, // El 80% del tamaño de la pantalla
          width: double.infinity,
          margin: const EdgeInsets.symmetric(
              horizontal: 17.0, vertical: 20.0), // Márgenes solo a los lados
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC800), // Fondo amarillo
            borderRadius: BorderRadius.circular(
                20.0), // Bordes redondeados para el doblez
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Sombra suave
                blurRadius: 10.0, // Desenfoque de la sombra
                offset: Offset(5, 5), // Desplazamiento de la sombra
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Centra los elementos verticalmente
            crossAxisAlignment: CrossAxisAlignment
                .center, // Centra los elementos horizontalmente
            children: [
              // Icono de email
              Icon(
                Icons.email_outlined,
                size: 90,
                color: Colors.black,
              ),
              SizedBox(height: 20),
              Text(
                'Hemos enviado un correo de verificación a tu email. Por favor, revisa tu bandeja de entrada y confirma tu cuenta.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isChecking ? null : _checkIfEmailVerified,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                ),
                child: _isChecking
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Correo confirmado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
              SizedBox(height: 20),
              _isResending
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        strokeWidth: 2,
                      ),
                    )
                  : GestureDetector(
                      onTap: _canResend ? _resendVerificationEmail : null,
                      child: Text(
                        _canResend
                            ? 'Reenviar código'
                            : 'Reenviar código (${_secondsRemaining}s)',
                        style: TextStyle(
                          color: _canResend ? Colors.black : Colors.grey,
                          fontSize: 20,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
              SizedBox(height: 30),
              TextButton.icon(
                onPressed: () {
                  _deleteUnverifiedUser();
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          SplashScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation.drive(
                            Tween(begin: 0.0, end: 1.0).chain(
                              CurveTween(curve: Curves.easeIn),
                            ),
                          ),
                          child: child,
                        );
                      },
                      transitionDuration: Duration(milliseconds: 500),
                    ),
                    (route) =>
                        false, // 🔒 Borra todo el historial de navegación
                  );
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: const Color.fromARGB(
                      255, 0, 0, 0), // Cambia el color del icono a amarillo
                ),
                label: Text(
                  'Volver al login',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18), // Tamaño de la fuente ajustado
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
