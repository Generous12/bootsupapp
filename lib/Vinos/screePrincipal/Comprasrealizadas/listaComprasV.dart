import 'package:bootsup/Vinos/screePrincipal/Comprasrealizadas/detalleCompras.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

DateTime? selectedDate;

class HistorialComprasScreenVinos extends StatefulWidget {
  const HistorialComprasScreenVinos({super.key});

  @override
  State<HistorialComprasScreenVinos> createState() =>
      _HistorialComprasScreenState();
}

class _HistorialComprasScreenState extends State<HistorialComprasScreenVinos> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: theme.iconTheme.color,
            size: 25,
          ),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Mis compras',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filtrar por fecha',
            icon: Icon(
              Iconsax.calendar_1,
              size: 22,
              color: theme.iconTheme.color,
            ),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
                helpText: 'Selecciona una fecha',
                builder: (context, child) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: isDark
                          ? const ColorScheme.dark(
                              primary: Color(0xFFFFAF00),
                              onPrimary: Colors.black,
                              onSurface: Colors.white,
                            )
                          : const ColorScheme.light(
                              primary: Color(0xFFFFAF00),
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                      dialogBackgroundColor:
                          isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                });
              }
            },
          ),
          if (selectedDate != null)
            IconButton(
              tooltip: 'Quitar filtro',
              icon: Icon(
                Icons.close,
                size: 22,
                color: theme.iconTheme.color,
              ),
              onPressed: () {
                setState(() {
                  selectedDate = null;
                });
              },
            ),
        ],
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('compras').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA30000)),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/compras.png',
                    width: 300,
                    height: 300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No hay compras disponibles.",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          final compras = snapshot.data!.docs
              .where((doc) {
                if (doc.data() is! Map<String, dynamic>) return false;
                if (selectedDate == null) return true;

                final fecha = (doc['fecha'] as Timestamp?)?.toDate();
                return fecha != null &&
                    fecha.year == selectedDate!.year &&
                    fecha.month == selectedDate!.month &&
                    fecha.day == selectedDate!.day;
              })
              .map((doc) => doc)
              .toList();

          compras.sort((a, b) {
            final fechaA =
                (a['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final fechaB =
                (b['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return fechaA.compareTo(fechaB);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: compras.length,
            itemBuilder: (context, index) {
              final compra = compras[index];
              final data = compra.data() as Map<String, dynamic>;
              final fecha = (data['fecha'] as Timestamp).toDate();
              final estado = (data['estado'] ?? 'Sin estado').toString();

              return GestureDetector(
                onTap: () {
                  navegarConSlideDerecha(
                    context,
                    DetalleCompraScreenVinos(
                      compraId: compra.id,
                      fecha: (data['fecha'] as Timestamp).toDate(),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compra',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('dd/MM/yyyy – hh:mm a').format(fecha),
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: colorEstado(estado),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              estado.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
