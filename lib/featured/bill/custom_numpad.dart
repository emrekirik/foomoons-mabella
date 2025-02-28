import 'package:flutter/material.dart';

class CustomNumpad extends StatefulWidget {
  final ValueChanged<String> onInput;
  final double value;
  const CustomNumpad({required this.value, required this.onInput, Key? key})
      : super(key: key);

  @override
  State<CustomNumpad> createState() => _CustomNumpadState();
}

class _CustomNumpadState extends State<CustomNumpad> {
  String input = "";

  void _handleButtonPress(String value) {
    setState(() {
      if (value == "←") {
        // Geri silme işlemi
        if (input.isNotEmpty) {
          input = input.substring(0, input.length - 1);
        }
      } else if (value == ".") {
        // Nokta ekleme işlemi
        if (!input.contains(".")) {
          input += value;
        }
      } else {
        // Sayı ekleme işlemi
        input += value;
      }
    });

    widget.onInput(input); // Ana TextField'a güncel değeri gönder
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Kalan tutar: ${widget.value.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            width: MediaQuery.of(context).size.width *
                0.20, // Genişliği sınırlayın
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) {
                  return _buildNumpadButton(
                    '.',
                    onPressed: () => _handleButtonPress('.'),
                    fontSize: 24,
                  );
                }
                if (index == 10) {
                  return _buildNumpadButton(
                    '0',
                    onPressed: () => _handleButtonPress('0'),
                    fontSize: 16,
                  );
                }
                if (index == 11) {
                  return _buildNumpadButton(
                    '←',
                    onPressed: () => _handleButtonPress('←'),
                    fontSize: 20,
                    color: Colors.red.shade100,
                    textColor: Colors.red.shade700,
                  );
                }
                return _buildNumpadButton(
                  '${index + 1}',
                  onPressed: () => _handleButtonPress('${index + 1}'),
                  fontSize: 16,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumpadButton(
    String text, {
    required VoidCallback onPressed,
    required double fontSize,
    Color? color,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.all(2),
      child: Material(
        color: color ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: textColor ?? Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
