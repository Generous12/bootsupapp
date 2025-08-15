import 'package:bootsup/Vistas/menuOpcionesPerfil/NombreUsuario.dart';
import 'package:bootsup/Vistas/menuOpcionesPerfil/cambiarcontrasena.dart';
import 'package:bootsup/Vistas/menuOpcionesPerfil/confAvanzada.dart';
import 'package:bootsup/Vistas/menuOpcionesPerfil/correoUsu.dart';
import 'package:bootsup/Vistas/menuOpcionesPerfil/direccion.dart';
import 'package:bootsup/Vistas/menuOpcionesPerfil/dni.dart';
import 'package:bootsup/Vistas/menuOpcionesPerfil/personlizacionTema.dart';
import 'package:bootsup/Vistas/menuOpcionesPerfil/telefono.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/menuBotones/fullWidthButton.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        toolbarHeight: 48,
        centerTitle: true,
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
          'Configuracion',
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
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionHeader(context, "Datos del usuario"),
              FullWidthMenuTile(
                option: MenuOption(
                  title: 'Editar nombre de usuario',
                  description: 'Modifica tu nombre público de usuario.',
                  icon: Iconsax.user_edit,
                  onTap: () {
                    navegarConSlideDerecha(context, NombreScreen());
                  },
                ),
              ),
              FullWidthMenuTile(
                option: MenuOption(
                  title: 'Editar correo electrónico',
                  description: 'Actualiza tu correo asociado a la cuenta.',
                  icon: Iconsax.sms,
                  onTap: () {
                    navegarConSlideDerecha(context, CorreoScreen());
                  },
                ),
              ),
              FullWidthMenuTile(
                option: MenuOption(
                  title: 'Cambiar contraseña',
                  description: 'Cambia tu contraseña actual por una nueva.',
                  icon: Iconsax.password_check,
                  onTap: () {
                    navegarConSlideDerecha(context, PasswordScreen1());
                  },
                ),
              ),
              FullWidthMenuTile(
                option: MenuOption(
                  title: 'Editar DNI',
                  description: 'Modifica tu documento de identidad.',
                  icon: Iconsax.card,
                  onTap: () {
                    navegarConSlideDerecha(context, IdentidadScreen());
                  },
                ),
              ),
              FullWidthMenuTile(
                option: MenuOption(
                  title: 'Editar dirección',
                  description: 'Modifica tu dirección de envío o residencia.',
                  icon: Iconsax.location,
                  onTap: () {
                    navegarConSlideDerecha(context, DireccionScreen());
                  },
                ),
              ),
              FullWidthMenuTile(
                option: MenuOption(
                  title: 'Editar número de teléfono',
                  description: 'Cambia el número de contacto registrado.',
                  icon: Iconsax.call,
                  onTap: () {
                    navegarConSlideDerecha(context, TelefonoScreen());
                  },
                ),
              ),
              buildSectionHeader(context, "Temas"),
              FullWidthMenuTile(
                option: MenuOption(
                  title: 'Personalización de la cuenta',
                  description: 'Cambia el tema y colores de la app.',
                  icon: Iconsax.setting_2,
                  onTap: () {
                    navegarConSlideDerecha(
                        context, const PersonalizacionCuentaScreen());
                  },
                ),
              ),
              buildSectionHeader(context, "Eliminr mi cuenta"),
              FullWidthMenuTile(
                option: MenuOption(
                  title: 'Configuración avanzada',
                  description: 'Ajustes adicionales y opciones de cuenta.',
                  icon: Iconsax.setting_2,
                  onTap: () {
                    navegarConSlideDerecha(context, ConfAvanzada());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
