import 'package:flutter/material.dart';

class MiniMenuOption {
  final String label;
  final VoidCallback onTap;
  final Widget? customIcon;
  final List<String>? assetIcons;
  final IconData? icon; // <-- Aquí

  MiniMenuOption({
    required this.label,
    required this.onTap,
    this.assetIcons,
    this.customIcon,
    this.icon,
  });
}

class buildOptionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final String description;
  final Color iconBackgroundColor;
  final IconData? icon;
  final List<MiniMenuOption>? subMenuOptions;
  final bool isFirst;
  final bool isLast;

  const buildOptionButton({
    Key? key,
    required this.onPressed,
    this.icon,
    required this.label,
    required this.description,
    this.iconBackgroundColor = const Color(0xFFFFC800),
    this.subMenuOptions,
    this.isFirst = false,
    this.isLast = false,
  }) : super(key: key);
  @override
  State<buildOptionButton> createState() => _OptionButtonWithSubMenuState();
}

class _OptionButtonWithSubMenuState extends State<buildOptionButton> {
  bool _isSubMenuVisible = false;

  void _handlePressed() {
    if (widget.subMenuOptions != null && widget.subMenuOptions!.isNotEmpty) {
      setState(() {
        _isSubMenuVisible = !_isSubMenuVisible;
      });
    } else {
      widget.onPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 350,
          margin: const EdgeInsets.only(left: 20, right: 20),
          child: ElevatedButton(
            onPressed: _handlePressed,
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(330.0, 70)),
              backgroundColor: WidgetStateProperty.all(
                  const Color.fromARGB(255, 255, 255, 255)),
              alignment: Alignment.centerLeft,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 20),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: widget.isFirst
                        ? const Radius.circular(10)
                        : Radius.zero,
                    bottom: widget.isLast && !_isSubMenuVisible
                        ? const Radius.circular(10)
                        : Radius.zero,
                  ),
                ),
              ),
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.pressed)) {
                    return const Color.fromARGB(255, 255, 255, 255);
                  }
                  return null;
                },
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon ?? Icons.help_outline,
                  color: const Color(0xFFFFAF00),
                  size: 24,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: ClipRect(
            child: (_isSubMenuVisible && widget.subMenuOptions != null)
                ? Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 1.0,
                    child: Container(
                      width: 343,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(31, 0, 0, 0),
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color.fromARGB(255, 200, 200, 200),
                          ),
                          ...List.generate(
                            widget.subMenuOptions!.length * 2 - 1,
                            (index) {
                              if (index.isOdd) {
                                return const Divider(
                                  height: 1,
                                  color: Color.fromARGB(255, 232, 232, 232),
                                );
                              }
                              final option = widget.subMenuOptions![index ~/ 2];
                              return GestureDetector(
                                onTap: () {
                                  option.onTap();
                                  setState(() {
                                    _isSubMenuVisible = false;
                                  });
                                },
                                child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 12),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 15),
                                        if (option.customIcon != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 10),
                                            child: option.customIcon!,
                                          )
                                        else if (option.assetIcons != null)
                                          Row(
                                            children: option.assetIcons!
                                                .map(
                                                  (path) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 10),
                                                    child: Image.asset(
                                                      path,
                                                      width: 15,
                                                      height: 20,
                                                      color: const Color(
                                                          0xFF142143),
                                                      colorBlendMode:
                                                          BlendMode.srcIn,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          )
                                        else if (option.icon !=
                                            null) // <-- Agregado
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 10),
                                            child: Icon(
                                              option.icon,
                                              color: const Color(0xFF142143),
                                              size: 20,
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            option.label,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : Align(
                    heightFactor: 0,
                    child: const SizedBox.shrink(),
                  ),
          ),
        ),
      ],
    );
  }
}
