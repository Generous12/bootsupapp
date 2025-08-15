import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label; // Etiqueta arriba (opcional)
  final String? hintText; // Hint dentro
  final IconData? prefixIcon; // Icono al inicio (opcional)
  final bool obscureText; // Si es contraseña (oculta texto)
  final bool isNumeric; // Para teclado numérico
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool showCounter;
  final bool enabled;

  const CustomTextField({
    Key? key,
    this.enabled = true,
    required this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.isNumeric = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines = 1,
    this.onChanged,
    this.focusNode,
    this.showCounter = false,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isMultiline = widget.maxLines! > 1;

    return Theme(
      data: theme.copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: colorScheme.primary,
          cursorColor: colorScheme.onBackground,
          selectionHandleColor: colorScheme.primary,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 0),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.isNumeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.multiline,
          obscureText: _obscureText,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          minLines: widget.minLines ?? 1,
          onChanged: widget.onChanged,
          focusNode: widget.focusNode,
          cursorColor: colorScheme.onBackground,
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 15.5,
            color: colorScheme.onBackground,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 15.5,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            alignLabelWithHint: isMultiline,
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 15.5,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            prefixIcon: widget.prefixIcon != null && !isMultiline
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      widget.prefixIcon,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            counterText: widget.showCounter ? null : "",
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : const Color(0xFFD4D4D4),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.onBackground,
                width: 1.3,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Iconsax.eye : Iconsax.eye_slash,
                      color: colorScheme.onBackground,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

Widget buildInfoLine({
  required BuildContext context,
  required String label,
  required String value,
}) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

//USAO EN ESTDISTICAComp
Widget buildLineChartCard(
    String titulo, Map<String, int> datos, BuildContext context) {
  final keys = datos.keys.toList();
  final values = datos.values.toList();
  final theme = Theme.of(context);

  return Card(
    elevation: 4,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: theme.cardColor,
    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.activity, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        if (value % 10 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < keys.length) {
                          return Text(
                            keys[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 42,
                      interval: 1,
                    ),
                  ),
                  topTitles: AxisTitles(),
                  rightTitles: AxisTitles(),
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: (values.length - 1).toDouble(),
                minY: 0,
                maxY: values.isEmpty
                    ? 10
                    : (values.reduce((a, b) => a > b ? a : b).toDouble() <= 50
                        ? 50
                        : (values.reduce((a, b) => a > b ? a : b).toDouble())),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.3),
                          Colors.transparent
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    spots: List.generate(values.length, (index) {
                      return FlSpot(index.toDouble(), values[index].toDouble());
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildEstadisticaTile(BuildContext context, String titulo, String valor,
    {IconData icon = Iconsax.chart}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Card(
    elevation: 3,
    shadowColor: Colors.black12,
    color: theme.cardColor,
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildTopList(
    BuildContext context, String titulo, Map<String, int> datos) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Card(
    elevation: 3,
    shadowColor: Colors.black12,
    color: theme.cardColor,
    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Iconsax.star_1, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...datos.entries.take(5).map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ),
  );
}

//estado
Color colorEstado(String estado) {
  switch (estado) {
    case 'Recibidos':
      return const Color.fromARGB(255, 0, 145, 255);
    case 'Preparación':
      return Colors.orange;
    case 'Enviado':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

Widget buildDetalleFila(BuildContext context, String titulo, String valor) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onBackground,
          ),
        ),
      ],
    ),
  );
}

Widget infoRow(BuildContext context, String label, String value) {
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      TextField(
        controller: TextEditingController(text: value),
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 16,
          color: theme.textTheme.bodyLarge?.color,
        ),
        readOnly: true,
        decoration: InputDecoration(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700] ?? Colors.grey
                  : Colors.grey[300] ?? Colors.grey,
              width: 0.0,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

String convertirTallaPantalonACintura(String talla) {
  switch (talla) {
    case '26':
      return '70-73 cm';
    case '28':
      return '74-77 cm';
    case '30':
      return '78-81 cm';
    case '32':
      return '82-85 cm';
    case '34':
      return '86-89 cm';
    case '36':
      return '90-95 cm';
    case '38':
      return '96-100 cm';
    case '40':
      return '101-105 cm';
    default:
      return '';
  }
}

String convertirTallaRopaANumero(String talla) {
  switch (talla) {
    case 'S':
      return '30-32';
    case 'M':
      return '34-36';
    case 'L':
      return '38-40';
    case 'XL':
      return '42-44';
    case 'XXL':
      return '44-48';
    default:
      return '';
  }
}

String convertirTallaCalzadoACm(String talla) {
  try {
    final numero = int.tryParse(talla);
    if (numero != null) {
      return (numero + 0.5).toStringAsFixed(1);
    }
  } catch (_) {}
  return '';
}

String mesAbreviado(int mes) {
  const meses = [
    "ene",
    "feb",
    "mar",
    "abr",
    "may",
    "jun",
    "jul",
    "ago",
    "sep",
    "oct",
    "nov",
    "dic"
  ];
  return meses[mes - 1];
}
