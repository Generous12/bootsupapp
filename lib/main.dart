import 'package:bootsup/Vista/autenticacion/SplashScreen.dart';
import 'package:bootsup/Vista/autenticacion/SinConexion.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/carritoService.dart';
import 'package:bootsup/Vistas/screensPrincipales/MainScreen.dart';
import 'package:bootsup/widgets/Providers/themeProvider.dart';
import 'package:bootsup/widgets/Providers/usurioProvider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'Vistas/screensPrincipales/inicio.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color.fromARGB(255, 0, 0, 0),
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarritoService()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  bool _isConnected = true;
  bool _isLoggedIn = false;
  bool _verificacionCompleta = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnectivity();
      _listenToAuthChanges();

      Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint("❌ Error al verificar la conexión: $e");
      _updateConnectionStatus(ConnectivityResult.none);
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final carrito = Provider.of<CarritoService>(context, listen: false);

    final bool isNowConnected = result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi;

    if (_isConnected != isNowConnected) {
      _isConnected = isNowConnected;

      carrito.limpiarCarrito();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isConnected) {
          _navigatorKey.currentState?.pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => NoInternetScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        } else {
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => _isLoggedIn ? Inicio() : const SplashScreen(),
            ),
            (route) => false,
          );
        }
      });
    }
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      final carrito = Provider.of<CarritoService>(context, listen: false);
      final usuarioProvider =
          Provider.of<UsuarioProvider>(context, listen: false);
      if (user == null) {
        carrito.limpiarCarrito();
        _isLoggedIn = false;
      } else if (user.emailVerified) {
        carrito.setUsuario(user.uid);
        usuarioProvider.cargarDatos(user.uid);
        _isLoggedIn = true;
      }

      if (mounted) {
        setState(() {
          _verificacionCompleta = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Afacad',
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFFAF00),
          onPrimary: Color(0xFFFAFAFA),
          background: Color(0xFFFAFAFA),
          onBackground: Colors.black,
        ),
        scaffoldBackgroundColor: Color(0xFFFAFAFA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAFAFA),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomAppBarTheme: const BottomAppBarTheme(
          color: Color(0xFFFAFAFA),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Afacad',
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFAF00),
          onPrimary: Colors.black,
          background: Color(0xFF121212),
          onBackground: Colors.white,
        ),
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomAppBarTheme: const BottomAppBarTheme(
          color: Color(0xFF121212),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: !_verificacionCompleta
          ? const SplashScreen()
          : _isLoggedIn
              ? MainScreen(user: FirebaseAuth.instance.currentUser)
              : const SplashScreen(),
    );
  }
}
