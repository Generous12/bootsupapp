import 'package:bootsup/Vista/EmpresaVista/Estadistica/EstadisticaComp.dart';
import 'package:bootsup/Vista/EmpresaVista/GestionEmpresaPubli/empresaPedidos/compradores.dart';
import 'package:bootsup/Vista/EmpresaVista/GestionEmpresaPubli/gestionProductos.dart';
import 'package:bootsup/Vista/EmpresaVista/GestionEmpresaPubli/gestionPublicaciones.dart';
import 'package:bootsup/Vista/EmpresaVista/GestionEmpresaPubli/ChatEmpresa/gestionchats.dart';
import 'package:bootsup/Vista/EmpresaVista/PerfilEmpresa.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/MetodoPago/Resultados/PagoSemiAutoma/subirMetodoPago.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/menuBotones/fullWidthButton.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ConfiguracionPerfilEmpresa extends StatefulWidget {
  @override
  _ConfiguracionPerfilEmpresaState createState() =>
      _ConfiguracionPerfilEmpresaState();
}

class _ConfiguracionPerfilEmpresaState
    extends State<ConfiguracionPerfilEmpresa> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: true,
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
            Navigator.pop(context, true);
          },
        ),
        title: Text(
          'Opciones de empresa',
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
      body: ListView(
        children: [
          buildSectionHeader(context, "Perfil de Empresa"),
          FullWidthMenuTile(
            option: MenuOption(
              title: 'Perfil Empresa',
              description: 'Edita la información de tu negocio',
              icon: Iconsax.building_4,
              onTap: () {
                navegarConSlideDerecha(context, EmpresaProfileScreen());
              },
            ),
          ),
          buildSectionHeader(context, "Gestion de articulos y multimedia"),
          FullWidthMenuTile(
            option: MenuOption(
              title: "Gestión de Productos",
              description: "Administra tus productos disponibles",
              icon: Iconsax.box,
              onTap: () {
                navegarConSlideDerecha(context, Gestionproductos());
              },
            ),
          ),
          FullWidthMenuTile(
            option: MenuOption(
              title: "Gestión de Publicaciones",
              description: "Administra tus publicaciones disponibles",
              icon: Iconsax.global,
              onTap: () {
                navegarConSlideDerecha(context, Gestionpublicaciones());
              },
            ),
          ),
          buildSectionHeader(context, "Pedidos"),
          FullWidthMenuTile(
            option: MenuOption(
              title: "Pedidos",
              description: "Gestiona los pedidos de tus clientes",
              icon: Iconsax.shopping_cart,
              onTap: () {
                navegarConSlideDerecha(context, ComprasUsuarioPage());
              },
            ),
          ),
          buildSectionHeader(context, "Chats"),
          FullWidthMenuTile(
            option: MenuOption(
              title: "Chats",
              description: "Conversa y responde a tus clientes",
              icon: Iconsax.message,
              onTap: () {
                navegarConSlideDerecha(context, ChatClientesScreen());
              },
            ),
          ),
          buildSectionHeader(context, "Estadistica"),
          FullWidthMenuTile(
            option: MenuOption(
              title: "Reportes",
              description: "Revisa el rendimiento de tus ventas",
              icon: Iconsax.dollar_circle,
              onTap: () {
                navegarConSlideDerecha(context, EstadisticasComprasScreen());
              },
            ),
          ),
          buildSectionHeader(context, "Pagos"),
          FullWidthMenuTile(
            option: MenuOption(
              title: "Métodos de Pago",
              description: "Configura Yape, Plin u otros métodos",
              icon: Iconsax.card_edit,
              onTap: () {
                navegarConSlideDerecha(context, GestionMetodosPagoScreen());
              },
            ),
          ),
        ],
      ),
    );
  }
}
