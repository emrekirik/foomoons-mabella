import 'package:flutter/material.dart';


Future<bool?> chartBottomSheet(BuildContext context) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true, // Enable full-screen scrolling
    builder: (BuildContext context) {
      return const ChartSection();
    },
  );
}

class ChartSection extends StatefulWidget {
  const ChartSection({super.key});

  @override
  State<ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<ChartSection> {
  @override
  Widget build(BuildContext context) {
    String dropdownValue = 'Aylık';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: ListTile(
                        title: Text(
                          'Hasılat',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        // subtitle:
                        //     Text('Lorem ipsum dolar sit amet, consectetur'),
                        // subtitleTextStyle: TextStyle(
                        //     fontSize: 15,
                        //     color: Colors.grey,
                        //     fontWeight: FontWeight.w300),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(7)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                          dropdownColor: Colors.grey.shade100,
                          value: dropdownValue,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.blue,
                          ),
                          iconSize: 24,
                          elevation: 16,
                          style: const TextStyle(color: Colors.black),
                          onChanged: (String? newValue) {
                            setState(() {
                              dropdownValue = newValue!;
                            });
                          },
                          items: <String>['Aylık', 'Haftalık', 'Günlük']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: const Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text('Gelir'),
                        leading: Icon(
                          Icons.square,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text('Gider'),
                        leading: Icon(
                          Icons.square,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text('126,000'),
                        leading: Icon(
                          Icons.graphic_eq,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text('126,000'),
                        leading: Icon(
                          Icons.graphic_eq,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 12,
              child: Container(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}