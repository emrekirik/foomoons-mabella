import 'package:foomoons/featured/stock/stock_list_item.dart';
import 'package:foomoons/product/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';

/// MenuView Widget
class StockView extends ConsumerStatefulWidget {
  final String? successMessage;
  const StockView({this.successMessage, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _StockViewState();
}

class _StockViewState extends ConsumerState<StockView> {
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchData();
  }

  void _fetchData() {
    Future.microtask(() {
      if (mounted) {
        final menuState = ref.read(menuProvider);
        if (menuState.products == null || menuState.categories == null) {
          ref.read(menuProvider.notifier).fetchAndLoad();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider).isLoading('menu');
    final menuNotifier = ref.watch(menuProvider.notifier);
    double deviceWidth = MediaQuery.of(context).size.width;
    final orderItem = ref
            .watch(menuProvider)
            .products
            ?.where((item) => item.stock != null)
            .toList() ??
        [];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: ColorConstants.white,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                  top: 20, right: deviceWidth * 0.2, left: deviceWidth * 0.2),
              child: Column(
                children: [
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'Ürün',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Stok Sayısı',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Güncelle',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: orderItem.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = orderItem[index];
                            return isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : StockListItem(
                                    item: item,
                                    menuNotifier: menuNotifier,
                                  );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
