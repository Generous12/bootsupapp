import 'package:bootsup/ModulosVinos/inventarioService.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CategoriaSelectorVinos extends StatefulWidget {
  final Function(String) onCategoriaSelected;

  const CategoriaSelectorVinos({super.key, required this.onCategoriaSelected});

  @override
  State<CategoriaSelectorVinos> createState() => _CategoriaSelectorState();
}

class _CategoriaSelectorState extends State<CategoriaSelectorVinos> {
  String? selectedCategoria;

  final List<Map<String, dynamic>> categorias = [
    {'label': 'General', 'icon': Icons.category},
    {'label': 'Vino Tinto', 'icon': Icons.wine_bar},
    {'label': 'Vino Blanco', 'icon': Icons.wine_bar},
    {'label': 'Pisco Quebranta', 'icon': Icons.local_bar},
    {'label': 'Pisco Acholado', 'icon': Icons.local_bar},
    {'label': 'Pisco Italia', 'icon': Icons.local_bar},
    {'label': 'Pisco Mosto Verde', 'icon': Icons.local_bar},
  ];

  @override
  void initState() {
    super.initState();
    selectedCategoria = 'General';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCategoriaSelected(selectedCategoria!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final categoria = categorias[index]['label'];
          final icon = categorias[index]['icon'];
          final isSelected = selectedCategoria == categoria;

          final backgroundColor = isSelected
              ? (isDark ? const Color(0xFFA30000) : Colors.black)
              : (isDark ? Colors.grey.shade900 : const Color(0xFFFAFAFA));
          final textColor = isSelected
              ? (isDark ? Colors.black : Colors.white)
              : (isDark ? Colors.white70 : Colors.black);

          return GestureDetector(
            onTap: () async {
              setState(() {
                selectedCategoria = categoria;
              });

              if (categoria == 'General') {
                await InventarioService().listarProductos();
              } else {
                await InventarioService().listarProductosPorCategoria(
                  categoria,
                );
              }

              widget.onCategoriaSelected(categoria);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isDark ? Colors.white12 : Colors.black.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: textColor),
                  const SizedBox(width: 6),
                  Text(
                    categoria,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ImageRatioSelector extends StatefulWidget {
  final Function(double, double) onRatioSelected;
  final bool isDisabled;

  const ImageRatioSelector({
    super.key,
    required this.onRatioSelected,
    required this.isDisabled,
  });

  @override
  State<ImageRatioSelector> createState() => _ImageRatioSelectorState();
}

class _ImageRatioSelectorState extends State<ImageRatioSelector> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _ratios = [
    {
      'label': '1x1',
      'desc': 'Cuadrado',
      'ratio': [1.0, 1.0],
    },
    {
      'label': '3x4',
      'desc': 'Vertical clásico',
      'ratio': [3.0, 4.0],
    },
    {
      'label': '4x5',
      'desc': 'Retrato',
      'ratio': [4.0, 5.0],
    },
  ];
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? Colors.white : Colors.black;
    final backgroundHighlight =
        isDark ? Colors.grey.shade800 : const Color.fromARGB(100, 255, 98, 98);
    final chipSelectedColor = isDark ? Colors.white : Colors.black;
    final chipUnselectedColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SizedBox(
        height: 110,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final buttonWidth = constraints.maxWidth / _ratios.length;

            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Fondo animado
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  left: _selectedIndex * buttonWidth,
                  top: 0,
                  width: buttonWidth,
                  height: 110,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 1.2),
                      color: backgroundHighlight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                // Botones
                Row(
                  children: List.generate(_ratios.length, (index) {
                    final isSelected = _selectedIndex == index;
                    final ratio = _ratios[index]['ratio'];
                    final label = _ratios[index]['label'];
                    final double ratioHeight = 52;
                    final double ratioWidth =
                        ratioHeight * (ratio[0] / ratio[1]);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!widget.isDisabled) {
                            setState(() => _selectedIndex = index);
                            widget.onRatioSelected(ratio[0], ratio[1]);
                          }
                        },
                        child: Container(
                          height: 110,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: ratioWidth,
                                height: ratioHeight,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? chipSelectedColor
                                      : chipUnselectedColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _ratios[index]['desc'],
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PedidoFiltroSelector extends StatefulWidget {
  final Function(String) onFiltroSelected;

  const PedidoFiltroSelector({Key? key, required this.onFiltroSelected})
      : super(key: key);

  @override
  State<PedidoFiltroSelector> createState() => PedidoFiltroSelectorState();
}

class PedidoFiltroSelectorState extends State<PedidoFiltroSelector> {
  String? filtroSeleccionado;

  final Color colorPrincipal = Colors.black;
  final Color colorFondo = const Color(0xFFFAFAFA);

  final List<Map<String, dynamic>> filtros = [
    // {'label': 'Rechazado', 'icon': Iconsax.close_circle},
    {'label': 'No atendido', 'icon': Iconsax.warning_2},
    {'label': 'Recibidos', 'icon': Iconsax.receipt},
    {'label': 'Preparación', 'icon': Iconsax.box},
    {'label': 'Enviado', 'icon': Iconsax.truck_fast},
  ];

  @override
  void initState() {
    super.initState();
    filtroSeleccionado = 'No atendido';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFiltroSelected(filtroSeleccionado!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filtro = filtros[index]['label'];
          final icon = filtros[index]['icon'];
          final isSelected = filtroSeleccionado == filtro;

          final selectedColor = isDark ? const Color(0xFFA30000) : Colors.black;
          final backgroundColor =
              isDark ? Colors.grey.shade900 : const Color(0xFFFAFAFA);
          final textColor = isSelected
              ? (isDark ? Colors.black : Colors.white)
              : (isDark ? Colors.white70 : Colors.black);

          return ChoiceChip(
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                filtroSeleccionado = filtro;
              });
              widget.onFiltroSelected(filtro);
            },
            backgroundColor: backgroundColor,
            selectedColor: selectedColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.3),
              ),
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 6),
                Text(
                  filtro,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
