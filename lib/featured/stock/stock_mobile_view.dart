/* import 'package:foomoons/featured/providers/loading_notifier.dart';
import 'package:foomoons/featured/stock/stock_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';

/// MenuView Widget
class StockMobileView extends ConsumerStatefulWidget {
  final String? successMessage;
  const StockMobileView({this.successMessage, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _StockMobileViewState();
}

class _StockMobileViewState extends ConsumerState<StockMobileView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (mounted) {
        final menuState = ref.read(menuProvider);
        if (menuState.products == null || menuState.categories == null) {
          await ref.read(menuProvider.notifier).fetchAndLoad();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider).isLoading('menu');
    final menuNotifier = ref.watch(menuProvider.notifier);
    final orderItem = ref
            .watch(menuProvider)
            .products
            ?.where((item) => item.stock != null)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Stok',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'İşlem',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      padding: const EdgeInsets.all(8),
                      itemCount: orderItem.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = orderItem[index];
                        return isLoading
                            ? const Center(child: CircularProgressIndicator())
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
  }
}
 */