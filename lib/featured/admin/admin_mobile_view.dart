import 'package:flutter_tabbar_lite/flutter_tabbar_lite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:foomoons/product/providers/app_providers.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class AdminMobileView extends ConsumerStatefulWidget {
  const AdminMobileView({super.key});

  @override
  ConsumerState<AdminMobileView> createState() => _AdminMobileViewState();
}

class _AdminMobileViewState extends ConsumerState<AdminMobileView> {
  String _selectedOrderType = 'Yeni Siparişler'; // Default selection
  bool isProcessing = false;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProvider.notifier).fetchAndLoad(forceRefresh: true);
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      isRefreshing = true;
    });
    await ref.read(adminProvider.notifier).fetchAndLoad(forceRefresh: true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(adminProvider).orders ?? [];
    final menus = ref.watch(menuProvider).products ?? [];
    final newOrders = orders
        .where((order) => order.status == null || order.status == 'yeni')
        .toList();
    final preparingOrders =
        orders.where((order) => order.status == 'hazırlanıyor').toList();
    final pastOrders =
        orders.where((order) => 
            (order.status == 'teslim edildi' || order.status == 'iptal edildi') &&
            order.orderDate != null &&
            DateTime.now().difference(order.orderDate!.toDate()).inDays <= 2).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
          child: FlutterTabBarLite.horizontal(
            borderRadius: 32,
            itemBorderRadius: 32,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF8C42),
                Color(0xFFA5D6A7),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            animateItemSize: false,
            suffixIcons: const [
              Icons.post_add_outlined,
              Icons.update,
              Icons.task_alt,
            ],
            itemPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTabChange: (index) {
              setState(() {
                _selectedOrderType = index == 0
                    ? 'Yeni Siparişler'
                    : index == 1
                        ? 'Hazırlanıyor'
                        : 'Geçmiş Siparişler';
              });
            },
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedOrderType == 'Yeni Siparişler')
                _buildOrderColumn(
                  context,
                  'Yeni Siparişler',
                  newOrders,
                  'hazırlanıyor',
                  menus,
                  'yeni',
                  showRefresh: true,
                ),
              if (_selectedOrderType == 'Hazırlanıyor')
                _buildOrderColumn(
                  context,
                  'Hazırlanıyor',
                  preparingOrders,
                  'teslim edildi',
                  menus,
                  'hazırlanıyor',
                  showRefresh: false,
                ),
              if (_selectedOrderType == 'Geçmiş Siparişler')
                _buildOrderColumn(context, 'Geçmiş Siparişler', pastOrders, '',
                    menus, 'hazır', showRefresh: false),
            ],
          ),
        ),
      ],
    );
  }

  Expanded _buildOrderColumn(
    BuildContext context,
    String title,
    List orders,
    String nextStatus,
    List menus,
    String status, {
    bool showRefresh = false,
  }) {
    final isLoading = ref.watch(loadingProvider);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  if (showRefresh) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: AnimatedRotation(
                        duration: const Duration(milliseconds: 1000),
                        turns: isRefreshing ? 1 : 0,
                        child: Icon(Icons.refresh, size: 20, color: Colors.grey[600]),
                      ),
                      onPressed: isRefreshing ? null : _refreshData,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              Expanded(
                child: isLoading.isLoading('admin')
                    ? ListView.separated(
                        itemCount: 6, // Shimmer için dummy item sayısı
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        separatorBuilder: (context, index) =>
                            const Divider(height: 32),
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: _buildShimmerLoading(),
                          );
                        },
                      )
                    : orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Şu anda siparişiniz yok',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: orders.length,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            separatorBuilder: (context, index) =>
                                const Divider(height: 32),
                            itemBuilder: (context, index) {
                              final item = orders[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: isLoading.isLoading('admin')
                                    ? _buildShimmerLoading()
                                    : Column(
                                        children: [
                                          IntrinsicHeight(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: _buildOrderDetailTile(
                                                    '',
                                                    item.title ?? '',
                                                    Icons.restaurant_menu,
                                                  ),
                                                ),
                                                Container(
                                                  width: 80,
                                                  alignment: Alignment.center,
                                                  child: _buildOrderDetailTile(
                                                    '',
                                                    '${item.piece} adet',
                                                    Icons.format_list_numbered,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          IntrinsicHeight(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 90,
                                                  alignment: Alignment.center,
                                                  child: _buildOrderDetailTile(
                                                    '',
                                                    item.orderDate != null
                                                        ? formatTimestamp(
                                                            item.orderDate!,
                                                            showFullDate: _selectedOrderType == 'Geçmiş Siparişler'
                                                          )
                                                        : '--:--',
                                                    Icons.access_time,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _buildOrderDetailTile(
                                                    '',
                                                    item.tableTitle ?? 'Bilinmiyor',
                                                    Icons.table_restaurant,
                                                  ),
                                                ),
                                                Container(
                                                  alignment: Alignment.centerRight,
                                                  child: _buildActionButtonsRow(
                                                      item, nextStatus, status),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailTile(String label, String value, IconData icon) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () {
          if (value.contains('...')) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset position = box.localToGlobal(Offset.zero);
            
            // Parantez içindeki tam tarihi al
            final fullDate = value.substring(value.indexOf('(') + 1, value.indexOf(')'));
            
            OverlayEntry overlayEntry = OverlayEntry(
              builder: (context) => Positioned(
                left: position.dx,
                top: position.dy - 40,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      fullDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );

            Overlay.of(context).insert(overlayEntry);

            Future.delayed(const Duration(seconds: 2), () {
              overlayEntry.remove();
            });
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                // Parantez içindeki tam tarihi gösterme
                value.contains('(') ? value.substring(0, value.indexOf('(')).trim() : value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: value == 'teslim edildi' 
                      ? Colors.green 
                      : value == 'iptal edildi' 
                          ? Colors.red 
                          : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsRow(item, String nextStatus, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'yeni') ...[
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.check_circle_outline, size: 24),
            color: Colors.green,
            onPressed: () {
              print('item id ${item.id}');
              if (item.id != null) {
                ref.read(adminProvider.notifier).updateOrderStatus(item, nextStatus);
              }
            },
            tooltip: 'Onayla',
          ),
          const SizedBox(width: 8),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.cancel_outlined, size: 24),
            color: Colors.red,
            onPressed: () {
              if (item.id != null) {
                ref.read(adminProvider.notifier).updateOrderStatus(item, 'iptal edildi');
              }
            },
            tooltip: 'İptal Et',
          ),
        ],
        if (nextStatus == 'teslim edildi')
          ElevatedButton(
            onPressed: isProcessing
                ? null
                : () async {
                    setState(() {
                      isProcessing = true;
                    });
                    try {
                       await ref.read(adminProvider.notifier).updateOrderStatus(item, nextStatus);
                      await Future.delayed(const Duration(milliseconds: 500));
                    } finally {
                      setState(() {
                        isProcessing = false;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(60, 32),
            ),
            child: Text(
              'Hazır',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (status == 'hazır') 
          _buildOrderDetailTile('', 
            item.status ?? '', 
            item.status == 'teslim edildi' 
                ? Icons.check_circle_outline 
                : Icons.cancel_outlined
          ),
      ],
    );
  }

  String formatTimestamp(Timestamp timestamp, {bool showFullDate = false}) {
    final DateTime dateTime = timestamp.toDate().toLocal();
    
    // Tam tarih formatı (tooltip için)
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    final String fullDate = '$day.$month.$year $hour:$minute';
    
    if (showFullDate) {
      // Geçmiş siparişlerde sadece saati göster ve tam tarihi parantez içinde sakla
      return '$hour:$minute... ($fullDate)';
    } else {
      // Diğer durumlarda sadece saat
      return '$hour:$minute';
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Container(
                  width: 80,
                  height: 20,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Container(
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
