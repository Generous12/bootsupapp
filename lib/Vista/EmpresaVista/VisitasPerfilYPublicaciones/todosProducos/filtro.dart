import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';

class FiltrosAdicionalesSheet extends StatelessWidget {
  final void Function(String criterio) onFiltroSeleccionado;

  const FiltrosAdicionalesSheet({
    super.key,
    required this.onFiltroSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Text(
            'Filtrar productos por',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          _buildFiltroTile(
            context: context,
            icon: LucideIcons.messageCircle,
            label: 'Más comentados',
            onTap: () => onFiltroSeleccionado('comentarios'),
          ),
          _buildFiltroTile(
            context: context,
            icon: LucideIcons.clock,
            label: 'Más recientes',
            onTap: () => onFiltroSeleccionado('recientes'),
          ),
          _buildFiltroTile(
            context: context,
            icon: LucideIcons.arrowDown,
            label: 'Precio: menor a mayor',
            onTap: () => onFiltroSeleccionado('precioMenor'),
          ),
          _buildFiltroTile(
            context: context,
            icon: LucideIcons.arrowUp,
            label: 'Precio: mayor a menor',
            onTap: () => onFiltroSeleccionado('precioMayor'),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Icon(icon, color: const Color(0xFFFFAF00)),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            LucideIcons.chevronRight,
            color: isDark ? Colors.white : Colors.black,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
