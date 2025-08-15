import 'package:bootsup/Vista/autenticacion/SplashScreen.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:iconsax/iconsax.dart';

class ConfAvanzada extends StatefulWidget {
  @override
  _ConfAvanzadaState createState() => _ConfAvanzadaState();
}

class _ConfAvanzadaState extends State<ConfAvanzada> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        return !_isLoading;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          toolbarHeight: 48,
          titleSpacing: 0,
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
              if (!_isLoading) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Configuracion avanzada',
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
        body: StreamBuilder<DocumentSnapshot>(
          stream: _getUserDataStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error al cargar los datos'));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text(''));
            }

            var userData = snapshot.data!;
            var nombreUsuario = userData['username'] ?? '';

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildInfoContainer('Nombre de usuario', nombreUsuario,
                        Icons.person, context),
                    const SizedBox(height: 16.0),
                    buildDeleteAccountButton(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildInfoContainer(
      String label, String value, IconData icon, BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Colors.black,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  value.isNotEmpty ? value : 'No especificado',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDeleteAccountButton(BuildContext context) {
    return AbsorbPointer(
      // Desactiva la interacción con todo el contenido dentro
      absorbing: _isLoading, // Si está en carga, se desactiva la interacción
      child: ElevatedButton(
        onPressed: () async {
          if (_user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Por favor, inicie sesión primero.'),
              ),
            );
            return;
          }

          // Mostrar cuadro de confirmación de eliminación

          // ignore: unused_local_variable
          bool? result = await showCustomDialog(
            context: context,
            title: 'Eliminar cuenta',
            message: '¿Estás seguro que deseas continuar?',
            confirmButtonText: 'Sí',
            cancelButtonText: 'No',
            confirmButtonColor: Colors.red,
            cancelButtonColor: Colors.blue,
          ).then((confirmed) {
            if (confirmed != null && confirmed) {
              setState(() {
                _isLoading = true; // Iniciar la carga
              });
              _reauthenticateAndDeleteAccount(context);
            }
            return null;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading
              ? Colors.grey // Color gris cuando está en carga
              : Colors.red, // Color rojo cuando no está en carga
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 110),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ],
              )
            : Text(
                'Eliminar Cuenta',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
      ),
    );
  }

  Future<void> _reauthenticateAndDeleteAccount(BuildContext context) async {
    try {
      if (_user == null) {
        throw FirebaseAuthException(
          message: "Usuario no autenticado.",
          code: 'user-not-authenticated',
        );
      }

      await _reauthenticateUser(context);
      await _deleteUserAccount();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reauthenticateUser(BuildContext context) async {
    if (_user == null) return;

    if (_user!.providerData[0].providerId == 'password') {
      String email = _user!.email!;
      String? password = await _promptPassword(context);
      if (password == null || password.isEmpty) {
        throw FirebaseAuthException(
          message: "Contraseña no proporcionada.",
          code: 'password-not-provided',
        );
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _user!.reauthenticateWithCredential(credential);
    } else if (_user!.providerData[0].providerId == 'google.com') {
      GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _user!.reauthenticateWithCredential(credential);
    }
  }

  Future<void> _deleteUserAccount() async {
    try {
      if (_user != null) {
        final userId = _user!.uid;

        // 1. Eliminar carpeta de imágenes del usuario en Storage
        final userStorageRef =
            FirebaseStorage.instance.ref().child('images/$userId');

        Future<void> _deleteFolder(Reference folderRef) async {
          try {
            final listResult = await folderRef.listAll();

            // Eliminar archivos
            for (var item in listResult.items) {
              await item.delete();
              print("Archivo eliminado: ${item.name}");
            }

            // Eliminar subcarpetas recursivamente
            for (var prefix in listResult.prefixes) {
              await _deleteFolder(prefix);
            }
          } catch (e) {
            print("Error al eliminar la carpeta: $e");
          }
        }

        await _deleteFolder(userStorageRef);
        print("Carpeta de usuario eliminada");

        // 2. Buscar empresa(s) relacionadas al usuario
        final empresaSnapshot = await _firestore
            .collection('empresa')
            .where('userid', isEqualTo: userId)
            .get();

        // Para cada empresa encontrada, eliminar datos relacionados y Storage
        for (var empresaDoc in empresaSnapshot.docs) {
          final empresaId = empresaDoc.id;

          // Eliminar productos relacionados a la empresa
          final productosSnapshot = await _firestore
              .collection('productos')
              .where('empresaId', isEqualTo: empresaId)
              .get();

          for (var productoDoc in productosSnapshot.docs) {
            // Eliminar imágenes del producto en Storage (suponiendo ruta: productos/{empresaId}/{productoId}/)
            final productoStorageRef = FirebaseStorage.instance
                .ref()
                .child('productos/$empresaId/${productoDoc.id}');

            await _deleteFolder(productoStorageRef);

            // Eliminar doc producto
            await productoDoc.reference.delete();
            print("Producto ${productoDoc.id} eliminado");
          }

          // Eliminar publicaciones relacionadas a la empresa
          final publicacionesSnapshot = await _firestore
              .collection('publicaciones')
              .where('empresaId', isEqualTo: empresaId)
              .get();

          for (var pubDoc in publicacionesSnapshot.docs) {
            final publicacionStorageRef = FirebaseStorage.instance
                .ref()
                .child('publicaciones/$empresaId/${pubDoc.id}');

            await _deleteFolder(publicacionStorageRef);

            await pubDoc.reference.delete();
            print("Publicación ${pubDoc.id} eliminada");
          }

          // Eliminar videos relacionados a la empresa
          final videosSnapshot = await _firestore
              .collection('videos')
              .where('empresaId', isEqualTo: empresaId)
              .get();

          for (var videoDoc in videosSnapshot.docs) {
            final videoStorageRef = FirebaseStorage.instance
                .ref()
                .child('videos/$empresaId/${videoDoc.id}');

            await _deleteFolder(videoStorageRef);

            await videoDoc.reference.delete();
            print("Video ${videoDoc.id} eliminado");
          }

          // Finalmente eliminar el documento de la empresa
          await empresaDoc.reference.delete();
          print("Empresa $empresaId eliminada");
        }

        // 3. Eliminar usuario de la colección 'users' en Firestore
        await _firestore.collection('users').doc(userId).delete();

        // 4. Eliminar la cuenta del usuario en Firebase Authentication
        await _user!.delete();

        // 5. Cerrar sesión y redirigir
        await _signOut(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SplashScreen()),
        );

        // 6. Confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuenta eliminada exitosamente'),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    } catch (e) {
      print("Error al eliminar la cuenta: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la cuenta: ${e.toString()}'),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        ),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      // Cierra la sesión del usuario de Firebase y Google
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      // Asegúrate de que `_user` esté definido en tu clase
      setState(() {
        _user = null;
      });

      // Navega al SplashScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    } catch (e) {
      print("Error al cerrar sesión: $e");
    }
  }

  Stream<DocumentSnapshot> _getUserDataStream() {
    if (_user != null) {
      return _firestore.collection('users').doc(_user!.uid).snapshots();
    }
    return Stream.empty(); // Si no hay usuario, se devuelve un Stream vacío
  }

  Future<String?> _promptPassword(BuildContext context) async {
    String? password;
    await showDialog(
      context: context,
      builder: (context) {
        final TextEditingController passwordController =
            TextEditingController();
        return AlertDialog(
          title: Text(
            'Ingrese su contraseña',
            style: TextStyle(fontSize: 20.0, color: Colors.black),
          ),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Contraseña',
            ),
            style: TextStyle(fontSize: 15.0, color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style:
                    TextStyle(fontSize: 18.0, color: const Color(0xFFFFC800)),
              ),
            ),
            TextButton(
              onPressed: () {
                password = passwordController.text;
                Navigator.of(context).pop();
              },
              child: Text(
                'Aceptar',
                style:
                    TextStyle(fontSize: 18.0, color: const Color(0xFFFFC800)),
              ),
            ),
          ],
        );
      },
    );
    return password;
  }
}
