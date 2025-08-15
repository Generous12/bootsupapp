import 'package:bootsup/Modulos/ModuloStats/EstadisticaService.dart';
import 'package:bootsup/Vista/EmpresaVista/Estadistica/VerPdf.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class EstadisticasComprasScreen extends StatefulWidget {
  const EstadisticasComprasScreen({super.key});

  @override
  State<EstadisticasComprasScreen> createState() =>
      _EstadisticasComprasScreenState();
}

class _EstadisticasComprasScreenState extends State<EstadisticasComprasScreen> {
  final _comprasService = EstadisticaService();

  Map<String, int> _comprasPorDia = {};
  double _ingresosTotales = 0;
  double _descuentosTotales = 0;
  double _impuestosTotales = 0;
  double _subtotalPromedio = 0;
  int _totalCompras = 0;
  Map<String, int> _topProductos = {};
  Map<String, int> _topCategorias = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final resultado =
        await _comprasService.obtenerEstadisticasCompras(user.uid);
    setState(() {
      _comprasPorDia = Map<String, int>.from(resultado['comprasPorDia']);
      _ingresosTotales = (resultado['ingresosTotales'] as num).toDouble();
      _descuentosTotales = (resultado['descuentosTotales'] as num).toDouble();
      _impuestosTotales = (resultado['impuestosTotales'] as num).toDouble();
      _subtotalPromedio = (resultado['subtotalPromedio'] as num).toDouble();
      _totalCompras = resultado['totalCompras'];
      _topProductos = Map<String, int>.from(resultado['topProductos']);
      _topCategorias = Map<String, int>.from(resultado['topCategorias']);
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        automaticallyImplyLeading: false,
        titleSpacing: 12,
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
          'Estadística general',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
              icon: const Icon(Iconsax.document_upload,
                  color: Color.fromARGB(255, 0, 0, 0)),
              tooltip: 'Exportar reporte',
              onPressed: () async {
                try {
                  final file = await PDFGenerator.generarBoleta(
                    totalCompras: _totalCompras,
                    ingresosTotales: _ingresosTotales,
                    descuentosTotales: _descuentosTotales,
                    impuestosTotales: _impuestosTotales,
                    subtotalPromedio: _subtotalPromedio,
                    topProductos: _topProductos,
                    topCategorias: _topCategorias,
                  );

                  print('Ruta del PDF: ${file.path}');

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VerBoletaScreen(filePath: file.path),
                    ),
                  );
                } catch (e) {
                  print('Error al generar o compartir PDF: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al generar o compartir el PDF'),
                      backgroundColor: Color(0xFF142143),
                    ),
                  );
                }
              }),
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _cargando
            ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Color(0xFFFFAF00),
                  size: 50,
                ),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildLineChartCard(
                        'Compras por día', _comprasPorDia, context),
                    const SizedBox(height: 16),
                    buildEstadisticaTile(
                        context, 'Total de compras', '$_totalCompras'),
                    buildEstadisticaTile(context, 'Ingresos totales',
                        'S/ ${_ingresosTotales.toStringAsFixed(2)}'),
                    buildEstadisticaTile(context, 'Descuentos totales',
                        'S/ ${_descuentosTotales.toStringAsFixed(2)}'),
                    buildEstadisticaTile(context, 'Impuestos totales',
                        'S/ ${_impuestosTotales.toStringAsFixed(2)}'),
                    buildEstadisticaTile(context, 'Subtotal promedio',
                        'S/ ${_subtotalPromedio.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    buildTopList(
                        context, 'Top productos vendidos', _topProductos),
                    buildTopList(context, 'Top categorías', _topCategorias),
                  ],
                )),
      ),
    );
  }
}
