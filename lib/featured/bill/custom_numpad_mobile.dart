import 'package:flutter/material.dart';

class CustomNumpadMobile extends StatefulWidget {
  final ValueChanged<String> onInput;
  final double value;
  const CustomNumpadMobile({required this.value, required this.onInput, Key? key})
      : super(key: key);

  @override
  State<CustomNumpadMobile> createState() => _CustomNumpadMobileState();
}

class _CustomNumpadMobileState extends State<CustomNumpadMobile> {
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
    List<String> buttons = [
      "7",
      "8",
      "9",
      "4",
      "5",
      "6",
      "1",
      "2",
      "3",
      ".",
      "0",
      "←"
    ];

    return Center(
      child: Column(
      
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Kalan tutar: ${widget.value.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SizedBox(
              width: MediaQuery.of(context).size.width *
                  0.8, // Genişliği sınırlayın
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Her satırda 4 buton
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.5,
                ),
                itemCount: buttons.length,
                itemBuilder: (context, index) {
                  final buttonLabel = buttons[index];
                  return ElevatedButton(
                    onPressed: () => _handleButtonPress(buttonLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonLabel == "←"
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
