import 'package:flutter/material.dart';

class MenuOption {
  final String title;
  final String? description;
  final IconData? icon;
  final List<MenuSubOption>? subOptions;
  final VoidCallback? onTap;

  MenuOption({
    required this.title,
    this.description,
    this.icon,
    this.subOptions,
    this.onTap,
  });
}

class MenuSubOption {
  final String title;
  final IconData? icon;
  final VoidCallback onTap;

  MenuSubOption({
    required this.title,
    this.icon,
    required this.onTap,
  });
}

class FullWidthMenuTile extends StatefulWidget {
  final MenuOption option;

  const FullWidthMenuTile({super.key, required this.option});

  @override
  State<FullWidthMenuTile> createState() => _FullWidthMenuTileState();
}

class _FullWidthMenuTileState extends State<FullWidthMenuTile> {
  bool _expanded = false;

  void _handleTap() {
    if (widget.option.subOptions != null &&
        widget.option.subOptions!.isNotEmpty) {
      setState(() {
        _expanded = !_expanded;
      });
    } else {
      widget.option.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _handleTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.option.icon ?? Icons.tune,
                    // color: const Color(0xFFFFAF00),
                    color: const Color(0xFFA30000),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.option.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (widget.option.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            widget.option.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.option.subOptions != null &&
                    widget.option.subOptions!.isNotEmpty)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.iconTheme.color?.withOpacity(0.6),
                  ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            children: widget.option.subOptions?.map((sub) {
                  return GestureDetector(
                    onTap: () {
                      sub.onTap();
                      setState(() => _expanded = false);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 56),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (sub.icon != null) ...[
                            Icon(
                              sub.icon,
                              size: 18,
                              color: theme.colorScheme.primary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            sub.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList() ??
                [],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

Widget buildSectionHeader(BuildContext context, String title) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 15, 20, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary, // usa el color principal del tema
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    ),
  );
}
