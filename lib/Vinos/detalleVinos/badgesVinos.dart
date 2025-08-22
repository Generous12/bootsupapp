import 'package:badges/badges.dart' as badges;
import 'package:bootsup/ModulosVinos/crritoServiceV.dart';
import 'package:bootsup/Vinos/detalleVinos/carrito.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/MetodoPago/Resultados/PagoSemiAutoma/subirMetodoPago.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class IconoCarritoConBadgeVinos extends StatefulWidget {
  final bool usarEstiloBoton;
  final double altura;
  final double iconSize;
  final Color fondoColor;
  final Color iconColor;
  final double borderRadius;

  const IconoCarritoConBadgeVinos({
    super.key,
    this.usarEstiloBoton = false,
    this.altura = 48.0,
    this.iconSize = 24.0,
    this.fondoColor = const Color.fromARGB(0, 0, 0, 0),
    this.iconColor = Colors.white,
    this.borderRadius = 8.0,
  });

  @override
  State<IconoCarritoConBadgeVinos> createState() =>
      _IconoCarritoConBadgeState();
}

class _IconoCarritoConBadgeState extends State<IconoCarritoConBadgeVinos> {
  @override
  Widget build(BuildContext context) {
    final carrito = Provider.of<CarritoServiceVinos>(context);
    int cantidadCarrito = carrito.obtenerCantidadTotal();

    Widget icono = IconButton(
      icon: Icon(
        Iconsax.bag,
        color: widget.iconColor,
        size: widget.iconSize,
      ),
      onPressed: () {
        navegarConSlideArriba(context, CarritoPageVinos());
      },
    );

    if (widget.usarEstiloBoton) {
      icono = Container(
        height: widget.altura,
        width: widget.altura,
        decoration: BoxDecoration(
          color: widget.fondoColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Center(child: icono),
      );
    }

    return badges.Badge(
      position: badges.BadgePosition.topEnd(top: -1, end: 28),
      showBadge: cantidadCarrito > 0,
      badgeContent: Text(
        '$cantidadCarrito',
        style: const TextStyle(color: Colors.white, fontSize: 8),
      ),
      badgeStyle: const badges.BadgeStyle(
        badgeColor: Color.fromARGB(255, 255, 0, 0),
      ),
      child: icono,
    );
  }
}

class BotonFlotanteConBadge extends StatefulWidget {
  final bool mostrarBadge;
  final Color fondoColor;
  final Color iconColor;
  final double iconSize;

  const BotonFlotanteConBadge({
    super.key,
    this.mostrarBadge = false,
    this.fondoColor = Colors.blue,
    this.iconColor = Colors.white,
    this.iconSize = 24.0,
  });

  @override
  State<BotonFlotanteConBadge> createState() => _BotonFlotanteConBadgeState();
}

class _BotonFlotanteConBadgeState extends State<BotonFlotanteConBadge> {
  @override
  Widget build(BuildContext context) {
    Widget fab = FloatingActionButton(
      backgroundColor: widget.fondoColor,
      onPressed: () {
        navegarConSlideArriba(context, GestionMetodosPagoScreen());
      },
      child: Icon(Iconsax.card_edit,
          color: widget.iconColor, size: widget.iconSize),
    );

    return badges.Badge(
      position: badges.BadgePosition.topEnd(top: -5, end: -5),
      showBadge: widget.mostrarBadge,
      badgeContent: const Text(
        '!',
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
      ),
      badgeStyle: const badges.BadgeStyle(
        badgeColor: Colors.red,
        padding: EdgeInsets.all(5),
      ),
      child: fab,
    );
  }
}

// Ejemplo de uso en un Scaffold
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ejemplo FAB con Badge")),
      body: const Center(child: Text("Contenido de la pantalla")),
      floatingActionButton: BotonFlotanteConBadge(
        mostrarBadge: true,
        fondoColor: Colors.blue,
        iconColor: Colors.white,
        iconSize: 26,
      ),
    );
  }
}
