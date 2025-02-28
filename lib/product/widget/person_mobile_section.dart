import 'package:foomoons/product/widget/personal_card_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonMobileSection extends ConsumerWidget {
  final List<Map<String, dynamic>> employees;
  final BoxConstraints constraints;
  const PersonMobileSection(
      {super.key, required this.employees, required this.constraints});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListTile(
                title: Text(
                'Personel Bilgileri',
                style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                // subtitle: Text('Lorem ipsum dolar sit amet, consectetur'),
                // subtitleTextStyle: TextStyle(
                //     fontSize: 15,
                //     color: Colors.grey,
                //     fontWeight: FontWeight.w300),
              ),
            ),
          /*   Container(
              width: deviceWidth < 950 ? 40 : 50,
              height: deviceWidth < 950 ? 40 : 50,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(60)),
              child: IconButton(
                onPressed: () {
                  addPersonalBottomSheet(
                      context, ref.read(reportsProvider.notifier));
                },
                icon: const Icon(
                  Icons.add,
                  color: Colors.black,
                ),
              ),
            ), */
          ],
        ),
        Flexible(
          flex: 8,
          child: employees.isNotEmpty // Çalışanlar varsa göster
            ? GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                  padding: const EdgeInsets.all(10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: (constraints.maxWidth / 120)
                        .floor(), //sütun sayısı
                    crossAxisSpacing:
                        10, // Öğeler arasındaki yatay boşluk
                    mainAxisSpacing: 10, // Öğeler arasındaki dikey boşluk
                    childAspectRatio: 0.7,
                ),
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final employee = employees[index];
                  return PersonalCardItem(
                    name: employee['name'] ?? 'Bilinmiyor',
                    position: employee['position'] ?? 'Bilinmiyor',
                    profileImage: employee['profileImage'] ??
                          'assets/images/personal_placeholder.png', // varsayılan bir resim ekleyebilirsiniz
                  );
                },
              )
              : const Center(
                  child: Text('Yakında hizmete açılacak'),
                    ),
        )
      ],
    );
  }
}
