import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class CustomDropdownSelector extends StatelessWidget {
  final String labelText;
  final String hintText;
  final String? value;
  final List<String> items;
  final Function(String) onChanged;
  final Map<String, VoidCallback>? itemActions;

  const CustomDropdownSelector({
    Key? key,
    required this.labelText,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField2<String>(
      value: value?.isEmpty == true ? null : value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontFamily: 'Afacad',
          fontSize: 14,
          color: isDarkMode
              ? Colors.grey[300]
              : const Color.fromARGB(255, 100, 100, 100),
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[900] : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : const Color(0xFFD4D4D4),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white : Colors.black,
            width: 1.2,
          ),
        ),
      ),
      dropdownStyleData: DropdownStyleData(
        isOverButton: false,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isDarkMode ? Colors.grey[900] : Colors.white,
        ),
        elevation: 4,
      ),
      hint: Text(
        hintText,
        style: TextStyle(
          fontFamily: 'Afacad',
          fontSize: 15,
          color: isDarkMode
              ? Colors.grey[400]
              : const Color.fromARGB(255, 108, 108, 108),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      item,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 15,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value); // acción general
          if (itemActions != null && itemActions!.containsKey(value)) {
            itemActions![value]!(); // acción específica
          }
        }
      },
    );
  }
}
