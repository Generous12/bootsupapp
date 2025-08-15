import 'package:bootsup/Modulos/ModuloAuth/AuthService.dart';
import 'package:bootsup/Vista/autenticacion/SplashScreen.dart';
import 'package:bootsup/Vistas/screensPrincipales/MainScreen.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SingleChildScrollView(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40.0),
                        Image.asset(
                          'assets/images/splash4.png',
                          height: 190.0,
                          fit: BoxFit.fitWidth,
                        ),
                        const SizedBox(height: 20.0),
                        CustomTextField(
                          controller: emailController,
                          hintText: "Ingresar correo electrónico",
                          prefixIcon: Iconsax.sms,
                          label: "Correo electronico",
                        ),
                        const SizedBox(height: 20.0),
                        CustomTextField(
                          controller: passwordController,
                          label: "Contraseña",
                          prefixIcon: Iconsax.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 20.0),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            LoadingOverlayButton(
                              text: 'Iniciar Sesión',
                              onPressedLogic: () async {
                                bool success =
                                    await AuthService().signInWithEmail(
                                  context,
                                  email: emailController.text.trim(),
                                  password: passwordController.text.trim(),
                                );

                                if (success) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) => MainScreen(
                                          user: FirebaseAuth
                                              .instance.currentUser),
                                      transitionsBuilder:
                                          (_, animation, __, child) {
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
                                      transitionDuration:
                                          const Duration(milliseconds: 300),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        SplashScreen(),
                                transitionDuration: Duration(milliseconds: 200),
                                reverseTransitionDuration:
                                    Duration(milliseconds: 200),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          child: Text(
                            '¿No tiene una cuenta? Registrarme',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                thickness: 1.0,
                                color: Color.fromARGB(66, 146, 146, 146),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(
                                'O',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                thickness: 1.0,
                                color: Color.fromARGB(66, 146, 146, 146),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 320.0,
                              height: 55.0,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      isDarkMode ? Colors.white : Colors.black,
                                  backgroundColor: isDarkMode
                                      ? Colors.grey[900]
                                      : Colors.white,
                                  side: BorderSide(
                                    color: isDarkMode
                                        ? Colors.white24
                                        : Colors.black26,
                                    width: 0.6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                ),
                                onPressed: () async {
                                  setState(() => isLoading = true);

                                  bool success = await AuthService()
                                      .signInWithGoogle(context);

                                  setState(() => isLoading = false);

                                  if (success) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) => MainScreen(
                                            user: FirebaseAuth
                                                .instance.currentUser),
                                        transitionsBuilder:
                                            (_, animation, __, child) {
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
                                        transitionDuration:
                                            const Duration(milliseconds: 300),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/google.png',
                                      width: 30.0,
                                      height: 30.0,
                                    ),
                                    const SizedBox(width: 15.0),
                                    Text(
                                      'Iniciar sesión con Google',
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
