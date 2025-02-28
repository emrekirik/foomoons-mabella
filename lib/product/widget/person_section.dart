import 'package:foomoons/product/providers/app_providers.dart';
import 'package:foomoons/product/widget/personal_card_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonSection extends ConsumerWidget {
  final BoxConstraints constraints;
  const PersonSection({super.key, required this.constraints});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(reportsProvider).employees;

    if (employees.isEmpty) {
/*       ref.read(_reportsProvider.notifier).fetchEmployees(); */
    }
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Personel Bilgileri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
      /*             Container(
                    width: deviceWidth < 950 ? 40 : 48,
                    height: deviceWidth < 950 ? 40 : 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: IconButton(
                      onPressed: () {
                        addPersonalDialog(context, ref.read(reportsProvider.notifier));
                      },
                      icon: Icon(
                        Icons.add_rounded,
                        color: Colors.grey.shade700,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ), */
                ],
              ),
              Expanded(
                flex: 8,
                child: employees.isNotEmpty
                    ? GridView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: (constraints.maxWidth / 250).floor(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          final employee = employees[index];
                          return PersonalCardItem(
                            name: employee['name'] ?? 'Bilinmiyor',
                            position: employee['position'] ?? 'Bilinmiyor',
                            profileImage: employee['profileImage'] ?? '',
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          'Yakında hizmete açılacak',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
