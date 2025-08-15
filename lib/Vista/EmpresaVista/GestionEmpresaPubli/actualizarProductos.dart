import 'package:bootsup/widgets/BotonesSeleccionables.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ActualizarProductoPage extends StatefulWidget {
  final Map<String, dynamic> producto;
  final String heroTag;

  const ActualizarProductoPage({
    Key? key,
    required this.producto,
    required this.heroTag,
  }) : super(key: key);

  @override
  _ActualizarProductoPageState createState() => _ActualizarProductoPageState();
}

class _ActualizarProductoPageState extends State<ActualizarProductoPage> {
  String? selectedColor;
  String? selectedMarca;
  List<String> _tallasSeleccionadas = [];
  List<String> _tamanosSeleccionados = [];
  List<String> _tayaSeleccionados = [];
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _marcatecnologia = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _descuentoController = TextEditingController();
  late PageController _pageController;
  List<String> get imagenes =>
      List<String>.from(widget.producto['imagenes'] ?? []);

  void _handleTallaSelected(List<String> tamanosSeleccionados) {
    setState(() {
      _tallasSeleccionadas = tamanosSeleccionados;
    });
  }

  void _handleTallsPantalones(List<String> tallasPSeleccionados) {
    setState(() {
      _tayaSeleccionados = tallasPSeleccionados;
    });
  }

  void _handleTamanoSelected(List<String> tamanosSeleccionados) {
    setState(() {
      _tamanosSeleccionados = tamanosSeleccionados;
    });
  }

  Widget _buildCamposAdicionales() {
    final categoria = widget.producto['categoria'] ?? '';

    if (categoria == 'Ropa') {
      final List<String> tallasRopa =
          List<String>.from(widget.producto['talla'] ?? []);

      final String tipoPrenda = widget.producto['tipoPrenda'] ?? '';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tipoPrenda == 'Parte inferior') ...[
              SelectorTallaPantalonPeru(
                onTallasSeleccionadas: _handleTallsPantalones,
                seleccionInicial: _tayaSeleccionados,
              ),
            ] else ...[
              const SizedBox(height: 10),
              TamanoSelector(
                onTamanosSelected: _handleTallaSelected,
                tamanosSeleccionados: tallasRopa,
              ),
            ]
          ],
        ),
      );
    } else if (categoria == 'Calzado') {
      final List<String> tallasZapato =
          List<String>.from(widget.producto['talla'] ?? []);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: TallaZapatoSelector(
          onTallasSelected: _handleTamanoSelected,
          tallasSeleccionadas: tallasZapato,
        ),
      );
    } else if (categoria == 'Tecnologias') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: CustomTextField(
          controller: _marcatecnologia,
          hintText: 'Escribe la marca del producto',
          label: "Marca del producto",
          maxLines: 1,
          maxLength: 20,
          showCounter: true,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  void actualizarProducto() async {
    final idProducto = widget.producto['id'];

    if (idProducto == null || idProducto.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID del producto no válido')),
      );
      return;
    }

    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, ingrese el nombre del producto')),
      );
      return;
    }

    final double? precio = double.tryParse(_precioController.text.trim());
    final int? cantidad = int.tryParse(_cantidadController.text.trim());
    final double? descuento = double.tryParse(_descuentoController.text.trim());

    final Map<String, dynamic> datosActualizados = {
      'nombreProducto': _nombreController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'marca': _marcatecnologia.text.trim(),
      'cantidad': cantidad ?? 0,
      'precio': precio ?? 0.0,
      'descuento': descuento ?? 0.0,
    };

    final String categoria = widget.producto['categoria'] ?? '';

    switch (categoria) {
      case 'Ropa':
        datosActualizados['talla'] = _tallasSeleccionadas;
        if (widget.producto['tipoPrenda'] == 'Parte inferior') {
          datosActualizados['tallaPantalon'] = _tayaSeleccionados;
        }

        if (selectedColor != null && selectedColor!.isNotEmpty) {
          datosActualizados['color'] = selectedColor;
        }
        break;

      case 'Calzado':
        datosActualizados['talla'] = _tamanosSeleccionados;
        break;

      case 'Tecnologias':
        if (selectedMarca != null && selectedMarca!.isNotEmpty) {
          datosActualizados['marca'] = selectedMarca;
        }
        break;
    }

    print('ID producto: $idProducto');
    print('Datos a actualizar: $datosActualizados');

    try {
      await FirebaseFirestore.instance
          .collection('productos')
          .doc(idProducto)
          .update(datosActualizados);

      await showCustomDialog(
        context: context,
        title: 'Éxito',
        message: 'Producto actualizado con éxito',
        confirmButtonText: 'Cerrar',
      );
    } catch (error) {
      print('Error al actualizar producto: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $error')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.producto['nombreProducto'] ?? '';
    _descripcionController.text = widget.producto['descripcion'] ?? '';
    _marcatecnologia.text = widget.producto['marca'] ?? '';
    _cantidadController.text = widget.producto['cantidad']?.toString() ?? '';
    _precioController.text = widget.producto['precio']?.toString() ?? '';
    _descuentoController.text = widget.producto['descuento']?.toString() ?? '';
    _pageController = PageController();

    final categoria = widget.producto['categoria'] ?? '';
    final talla = List<String>.from(widget.producto['talla'] ?? []);
    final tallaPant = List<String>.from(widget.producto['tallaPantalon'] ?? []);
    final color = widget.producto['color'] ?? '';

    if (categoria == 'Ropa') {
      _tayaSeleccionados = tallaPant;
      _tallasSeleccionadas = talla;
      selectedColor = color;
    } else if (categoria == 'Calzado') {
      _tamanosSeleccionados = talla;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                  },
                  child: Material(
                    shape: const CircleBorder(),
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.3),
                    color: const Color.fromARGB(255, 0, 0, 0),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        Iconsax.arrow_left,
                        color: Color(0xFFFFAF00),
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: widget.heroTag,
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    imagenes.isNotEmpty && imagenes.any((url) => url.isNotEmpty)
                        ? PageView.builder(
                            controller: _pageController,
                            itemCount: imagenes.length,
                            onPageChanged: (index) {
                              setState(() {});
                            },
                            itemBuilder: (context, index) {
                              final url = imagenes[index];
                              return url.isNotEmpty
                                  ? Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/empresa.png',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'assets/images/empresa.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    );
                            },
                          )
                        : Image.asset(
                            'assets/images/empresa.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                    if (imagenes.isNotEmpty &&
                        imagenes.any((url) => url.isNotEmpty))
                      Positioned(
                        bottom: 12,
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: imagenes.length,
                          effect: ScaleEffect(
                            activeDotColor: Color(0xFFFFAF00),
                            dotColor: Colors.grey.shade400,
                            dotHeight: 8,
                            dotWidth: 8,
                            spacing: 6,
                            scale: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    CustomTextField(
                      controller: _nombreController,
                      hintText: 'Escribe el nombre del producto',
                      label: "Nombre del producto",
                      maxLines: 1,
                      maxLength: 20,
                      showCounter: true,
                    ),
                    SizedBox(height: 10),
                    CustomTextField(
                      controller: _descripcionController,
                      hintText: 'Escribe la descripcion del producto',
                      label: "Descripcion del producto",
                      maxLines: 5,
                      maxLength: 200,
                      showCounter: true,
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _cantidadController,
                            hintText: 'Cantidad',
                            label: 'Cantidad',
                            isNumeric: true,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            controller: _precioController,
                            hintText: 'Precio',
                            label: 'Precio',
                            isNumeric: true,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            controller: _descuentoController,
                            hintText: 'Descuento',
                            label: 'Descuento',
                            isNumeric: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _buildCamposAdicionales(),
                  ],
                )),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: LoadingOverlayButton(
                  text: 'Actualizar producto',
                  onPressedLogic: () async {
                    actualizarProducto();
                    setState(() {});
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
