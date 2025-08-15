import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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
    final backgroundHighlight = isDark
        ? Colors.grey.shade800
        : const Color.fromARGB(255, 255, 228, 170);
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
                      border: Border.all(
                        color: borderColor,
                        width: 1.2,
                      ),
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

class CategoriaSelector extends StatefulWidget {
  final Function(String) onCategoriaSelected;

  const CategoriaSelector({super.key, required this.onCategoriaSelected});

  @override
  State<CategoriaSelector> createState() => _CategoriaSelectorState();
}

class _CategoriaSelectorState extends State<CategoriaSelector> {
  String? selectedCategoria;

  final List<Map<String, dynamic>> categorias = [
    {'label': 'General', 'icon': Iconsax.category},
    {'label': 'Ropa', 'icon': Iconsax.shop},
    {'label': 'Calzado', 'icon': Iconsax.rulerpen},
    {'label': 'Tecnologias', 'icon': Iconsax.cpu},
    {'label': 'Limpieza', 'icon': Iconsax.brush},
    {'label': 'Muebles', 'icon': Iconsax.lamp},
    {'label': 'Juguetes', 'icon': Iconsax.game},
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

          final selectedColor =
              isDark ? Colors.amber : Colors.black; // fondo seleccionado
          final backgroundColor =
              isDark ? Colors.grey.shade900 : const Color(0xFFFAFAFA);
          final textColor = isSelected
              ? (isDark ? Colors.black : Colors.white)
              : (isDark ? Colors.white70 : Colors.black);

          return ChoiceChip(
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                selectedCategoria = categoria;
              });
              widget.onCategoriaSelected(categoria);
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
                Icon(
                  icon,
                  size: 18,
                  color: textColor,
                ),
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
          );
        },
      ),
    );
  }
}

class TamanoSelector extends StatefulWidget {
  final ValueChanged<List<String>> onTamanosSelected;
  final List<String> tamanosSeleccionados; // 👈 NUEVO

  const TamanoSelector({
    super.key,
    required this.onTamanosSelected,
    this.tamanosSeleccionados = const [], // 👈 NUEVO
  });

  @override
  _TamanoSelectorState createState() => _TamanoSelectorState();
}

class _TamanoSelectorState extends State<TamanoSelector> {
  final List<String> tamanos = ['S', 'M', 'L', 'XL', 'XXL'];
  final Map<String, String> medidas = {
    'S': '30-32',
    'M': '34-36',
    'L': '38-40',
    'XL': '42-44',
    'XXL': '46-48',
  };

  List<String> selectedTamanos = [];
  final Color lightYellow = const Color.fromARGB(255, 255, 255, 255);

  @override
  void initState() {
    super.initState();
    selectedTamanos = List.from(widget.tamanosSeleccionados);
  }

  void toggleSelection(String tamano) {
    setState(() {
      if (selectedTamanos.contains(tamano)) {
        selectedTamanos.remove(tamano);
      } else {
        selectedTamanos.add(tamano);
      }
    });
    widget.onTamanosSelected(selectedTamanos);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona la talla',
          style: TextStyle(
            fontSize: 14,
            color: Color.fromARGB(255, 145, 145, 145),
          ),
        ),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            itemCount: tamanos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tamano = tamanos[index];
              final isSelected = selectedTamanos.contains(tamano);

              final selectedColor = isDark ? Colors.amber : Colors.black;
              final backgroundColor =
                  isDark ? Colors.grey.shade900 : Colors.white;
              final textColor = isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white70 : Colors.black);

              return ChoiceChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tamano,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      medidas[tamano] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => toggleSelection(tamano),
                backgroundColor: backgroundColor,
                selectedColor: selectedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TallaZapatoSelector extends StatefulWidget {
  final ValueChanged<List<String>> onTallasSelected;
  final List<String> tallasSeleccionadas; // 👈 NUEVO

  const TallaZapatoSelector({
    super.key,
    required this.onTallasSelected,
    this.tallasSeleccionadas = const [], // 👈 NUEVO
  });

  @override
  _TallaZapatoSelectorState createState() => _TallaZapatoSelectorState();
}

class _TallaZapatoSelectorState extends State<TallaZapatoSelector> {
  final List<String> tamanos = ['36', '37', '38', '39', '40', '41'];
  final Map<String, String> centimetros = {
    '36': '23 cm',
    '37': '23.5 cm',
    '38': '24 cm',
    '39': '25 cm',
    '40': '25.5 cm',
    '41': '26 cm',
  };

  List<String> selectedTamanos = [];
  final Color lightYellow = const Color.fromARGB(255, 255, 255, 255);

  @override
  void initState() {
    super.initState();
    selectedTamanos = List.from(widget.tallasSeleccionadas);
  }

  void toggleSelection(String tamano) {
    setState(() {
      if (selectedTamanos.contains(tamano)) {
        selectedTamanos.remove(tamano);
      } else {
        selectedTamanos.add(tamano);
      }
    });
    widget.onTallasSelected(selectedTamanos);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona una talla',
          style: TextStyle(
            fontSize: 14,
            color: Color.fromARGB(255, 145, 145, 145),
          ),
        ),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            itemCount: tamanos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tamano = tamanos[index];
              final isSelected = selectedTamanos.contains(tamano);

              // Estilos dinámicos
              final selectedColor = isDark ? Colors.amber : Colors.black;
              final textColor = isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white : Colors.black);
              final borderColor =
                  isSelected ? Colors.transparent : Colors.grey.shade500;

              return ChoiceChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tamano,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      centimetros[tamano] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => toggleSelection(tamano),
                backgroundColor: Colors.transparent,
                selectedColor: selectedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: borderColor),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

//SIN USO
class ColoresSelector extends StatefulWidget {
  final ValueChanged<String> onColorSelected;
  final String? colorSeleccionado; // 👈 NUEVO

  const ColoresSelector({
    super.key,
    required this.onColorSelected,
    this.colorSeleccionado, // 👈 NUEVO
  });

  @override
  _ColoresSelectorState createState() => _ColoresSelectorState();
}

class _ColoresSelectorState extends State<ColoresSelector> {
  String? selectedColorName;

  final Map<String, Color> colores = {
    'Rojo': Colors.red,
    'Verde': Colors.green,
    'Azul': Colors.blue,
    'Amarillo': Colors.yellow,
    'Naranja': Colors.orange,
    'Morado': Colors.purple,
    'Rosado': Colors.pink,
    'Negro': Colors.black,
    'Blanco': Colors.white,
    'Gris': Colors.grey,
  };
  @override
  void initState() {
    super.initState();
    selectedColorName = widget.colorSeleccionado; // 👈 NUEVO
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona un color',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: colores.length,
            itemBuilder: (context, index) {
              final colorName = colores.keys.elementAt(index);
              final colorValue = colores[colorName]!;

              final isSelected = selectedColorName == colorName;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColorName = colorName;
                  });
                  widget.onColorSelected(colorName);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorValue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Text(
                            colorName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorValue.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CantidadSelectorHorizontal extends StatelessWidget {
  final int cantidadSeleccionada;
  final ValueChanged<int> onSeleccionar;

  const CantidadSelectorHorizontal({
    super.key,
    required this.cantidadSeleccionada,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(10, (index) {
            final numero = index + 1;
            final bool seleccionado = cantidadSeleccionada == numero;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: () => onSeleccionar(numero),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? colorScheme.primary
                        : colorScheme.surface,
                    border: Border.all(
                      color: seleccionado
                          ? colorScheme.primary.withOpacity(0.8)
                          : colorScheme.outlineVariant,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$numero',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: seleccionado
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class SelectorTallaPantalonPeru extends StatefulWidget {
  final ValueChanged<List<String>> onTallasSeleccionadas;
  final List<String> seleccionInicial;

  const SelectorTallaPantalonPeru({
    super.key,
    required this.onTallasSeleccionadas,
    this.seleccionInicial = const [],
  });

  @override
  State<SelectorTallaPantalonPeru> createState() =>
      _SelectorTallaPantalonPeruState();
}

class _SelectorTallaPantalonPeruState extends State<SelectorTallaPantalonPeru> {
  final List<Map<String, String>> opciones = [
    {'cm': '70-73', 'talla': '26'},
    {'cm': '74-77', 'talla': '28'},
    {'cm': '78-81', 'talla': '30'},
    {'cm': '82-85', 'talla': '32'},
    {'cm': '86-89', 'talla': '34'},
    {'cm': '90-95', 'talla': '36'},
    {'cm': '96-100', 'talla': '38'},
    {'cm': '101-105', 'talla': '40'},
  ];

  List<String> seleccionadas = [];

  @override
  void initState() {
    super.initState();
    seleccionadas = List.from(widget.seleccionInicial);
  }

  void _alternarSeleccion(String talla) {
    setState(() {
      if (seleccionadas.contains(talla)) {
        seleccionadas.remove(talla);
      } else {
        seleccionadas.add(talla);
      }
    });
    widget.onTallasSeleccionadas(seleccionadas);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona la talla',
          style: TextStyle(
            fontSize: 14,
            color: Color.fromARGB(255, 145, 145, 145),
          ),
        ),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: opciones.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final opcion = opciones[index];
              final talla = opcion['talla']!;
              final cm = opcion['cm']!;
              final isSelected = seleccionadas.contains(talla);

              final selectedColor = isDark ? Colors.amber : Colors.black;
              final backgroundColor =
                  isDark ? Colors.grey.shade900 : Colors.white;
              final textColor = isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white70 : Colors.black);

              return ChoiceChip(
                selected: isSelected,
                onSelected: (_) => _alternarSeleccion(talla),
                backgroundColor: backgroundColor,
                selectedColor: selectedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color:
                        isDark ? Colors.white12 : Colors.black.withOpacity(0.3),
                  ),
                ),
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$cm cm',
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Talla $talla',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ChatFiltroSelector extends StatefulWidget {
  final Function(String) onFiltroSelected;

  const ChatFiltroSelector({super.key, required this.onFiltroSelected});

  @override
  State<ChatFiltroSelector> createState() => _ChatFiltroSelectorState();
}

class _ChatFiltroSelectorState extends State<ChatFiltroSelector> {
  String? filtroSeleccionado;

  final List<Map<String, dynamic>> filtros = [
    {'label': 'Todos', 'icon': Iconsax.message},
    {'label': 'No leídos', 'icon': Iconsax.sms},
    {'label': 'Leídos', 'icon': Iconsax.tick_circle},
  ];

  @override
  void initState() {
    super.initState();
    filtroSeleccionado = 'Todos';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFiltroSelected(filtroSeleccionado!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: filtros.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filtro = filtros[index]['label'];
              final icon = filtros[index]['icon'];
              final isSelected = filtroSeleccionado == filtro;

              final selectedColor = isDark ? Colors.amber : Colors.black;
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
                    color:
                        isDark ? Colors.white12 : Colors.black.withOpacity(0.3),
                  ),
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: textColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filtro,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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

          final selectedColor = isDark ? Colors.amber : Colors.black;
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
                Icon(
                  icon,
                  size: 18,
                  color: textColor,
                ),
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

class MotivosObservacionRow extends StatefulWidget {
  final ValueChanged<String?> onMotivoSeleccionado;

  const MotivosObservacionRow({
    super.key,
    required this.onMotivoSeleccionado,
  });

  @override
  State<MotivosObservacionRow> createState() => _MotivosObservacionRowState();
}

class _MotivosObservacionRowState extends State<MotivosObservacionRow> {
  final List<String> motivos = [
    "Nombre incorrecto",
    "Monto distinto",
    "Pago duplicado",
    "Sin comprobante",
    "Referencia inválida",
  ];

  int? motivoSeleccionado;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(motivos.length, (index) {
          final bool isSelected = motivoSeleccionado == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  motivoSeleccionado = index;
                });
                widget.onMotivoSeleccionado(
                  isSelected ? null : motivos[index],
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFAF00)
                      : isDark
                          ? Colors.grey[800]
                          : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isDark ? Colors.white12 : Colors.black.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.warning_2,
                      size: 18,
                      color: isSelected ? Colors.black : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      motivos[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : isDark
                                ? Colors.white
                                : Colors.black,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
