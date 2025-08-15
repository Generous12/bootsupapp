// ignore_for_file: use_build_context_synchronously

import 'package:bootsup/Vistas/screensPrincipales/MainScreen.dart';
import 'package:bootsup/widgets/Providers/usurioProvider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class MembresiaScreen extends StatefulWidget {
  const MembresiaScreen({super.key});
  @override
  _MembresiaScreenState createState() => _MembresiaScreenState();
}

class _MembresiaScreenState extends State<MembresiaScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? membershipStatus;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  // Colores principales
  final Color amarilloFuerte = Color(0xFFFFAF00);
  final Color blanco = Colors.white;
  final Color negro = Colors.black87;
  final Color grisSombra = Colors.black12;
  final Color grisTextoSecundario = Colors.grey.shade600;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    _getMembershipStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _getMembershipStatus() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          membershipStatus = doc['membresia'];
        });
      } catch (e) {
        print('Error al obtener la membresía: $e');
      }
    }
  }

  void _updateMembership(String membership) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'membresia': membership
        }); // 🔄 Actualiza el provider con los nuevos datos
        final usuarioProvider =
            Provider.of<UsuarioProvider>(context, listen: false);
        await usuarioProvider.cargarDatos(user.uid);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Membresía activada como $membership')),
        );
        setState(() {
          membershipStatus = membership;
        });
      } catch (e) {
        print('Error al actualizar la membresía: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al activar la membresía')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se ha encontrado usuario')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 0, 0),
              Color.fromARGB(255, 20, 20, 20),
              Color(0xFFFFAF00).withOpacity(0.85),
              Color(0xFFFFAF00),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Iconsax.arrow_left,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final usuarioProvider = Provider.of<UsuarioProvider>(
                              context,
                              listen: false);
                          await usuarioProvider.recargarDatos();

                          Navigator.pushAndRemoveUntil(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  MainScreen(user: user),
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
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      splashRadius: 15,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Membresías',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),

                /// Mis membresías activas (NUEVO)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.verify, color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Membresía actual: ${membershipStatus?.isNotEmpty == true ? membershipStatus : "Ninguna"}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Iconsax.user_tag, color: Colors.white70, size: 22),
                    ],
                  ),
                ),

                SizedBox(height: 12),
                Text(
                  'Seleccione su tipo de membresía',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 320,
                            child: _buildMembresiaCard(
                              title: 'Clientes',
                              description:
                                  'Acceso a productos exclusivos y descuentos para clientes. '
                                  'Podrás disfrutar de promociones especiales cada mes, participar en eventos exclusivos, y recibir recomendaciones personalizadas según tus preferencias.',
                              benefits:
                                  'Beneficios adicionales:\n- Acceso prioritario a nuevas colecciones.\n- Ofertas personalizadas basadas en tu historial de compras.\n- Atención al cliente dedicada.\n- Posibilidad de acumular puntos para futuras compras.\n- Invitaciones a webinars y lanzamientos exclusivos.',
                              isSelected: membershipStatus == 'Clientes',
                              onTap: () => _updateMembership('Clientes'),
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            width: 320,
                            child: _buildMembresiaCard(
                              title: 'Empresa',
                              description:
                                  'Accede a planes avanzados para gestionar tu empresa y vender productos. '
                                  'Incluye herramientas para seguimiento de inventario, análisis de ventas, y soporte dedicado para impulsar tu negocio.',
                              benefits:
                                  'Beneficios adicionales:\n- Herramientas de gestión y análisis.\n- Soporte prioritario para resolver dudas.\n- Capacitación exclusiva para tu equipo.\n- Integración con plataformas de pago y logística.\n- Reportes personalizados y asesoría comercial.',
                              isSelected: membershipStatus == 'Empresa',
                              onTap: () => _updateMembership('Empresa'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembresiaCard({
    required String title,
    required String description,
    required String benefits,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: blanco,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: amarilloFuerte.withOpacity(0.45),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: grisSombra,
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
        border: isSelected ? Border.all(color: amarilloFuerte, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con ícono
          Row(
            children: [
              Icon(Iconsax.medal_star, color: amarilloFuerte, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: negro,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Descripción con ícono
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Iconsax.info_circle, color: amarilloFuerte, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: negro.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Beneficios con ícono
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Iconsax.tick_circle, size: 18, color: amarilloFuerte),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  benefits,
                  style: TextStyle(
                    fontSize: 14,
                    color: grisTextoSecundario,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón de selección
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey.shade400 : amarilloFuerte,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.transparent
                      : amarilloFuerte.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isSelected ? null : onTap,
                borderRadius: BorderRadius.circular(10),
                splashColor: amarilloFuerte.withOpacity(0.3),
                child: Center(
                  child: Text(
                    isSelected ? 'Seleccionado' : 'Seleccionar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: blanco,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
