import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foomoons/product/services/bar_printer_service.dart';
import 'package:foomoons/product/services/kitchen_printer_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminView extends ConsumerStatefulWidget {
  const AdminView({super.key});

  @override
  ConsumerState<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends ConsumerState<AdminView> {
  bool isProcessing = false;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).fetchAndLoad(forceRefresh: true);
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      isRefreshing = true;
    });
    await ref.read(adminProvider.notifier).fetchAndLoad(forceRefresh: true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        isRefreshing = false;
      });
    }
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
    final kitchenOrders =
        preparingOrders.where((order) => order.orderType == 'Mutfak').toList();
    final barOrders =
        preparingOrders.where((order) => order.orderType == 'Bar').toList();
    final pastOrders = orders
        .where((order) =>
            order.status == 'teslim edildi' || order.status == 'iptal edildi')
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderColumn(
            context,
            'Yeni Siparişler',
            newOrders,
            'hazırlanıyor',
            menus,
            'yeni',
            showRefresh: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hazırlanıyor',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isProcessing)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange[300]!),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        // Mutfak Bölümü
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom:
                                        BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                                child: Text(
                                  'Mutfak',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: kitchenOrders.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.inbox_outlined,
                                                size: 36,
                                                color: Colors.grey[400]),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Şu anda siparişiniz yok',
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: kitchenOrders.length,
                                        padding: const EdgeInsets.all(8),
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 6),
                                        itemBuilder: (context, index) {
                                          final item = kitchenOrders[index];
                                          return Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey
                                                      .withOpacity(0.1)),
                                            ),
                                            child: Column(
                                              children: [
                                                IntrinsicHeight(
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child:
                                                            _buildOrderDetailTile(
                                                          '',
                                                          item.title ?? '',
                                                          Icons.restaurant_menu,
                                                        ),
                                                      ),
                                                      Container(
                                                        width: 80,
                                                        alignment:
                                                            Alignment.center,
                                                        child:
                                                            _buildOrderDetailTile(
                                                          '',
                                                          '${item.piece} adet',
                                                          Icons
                                                              .format_list_numbered,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                IntrinsicHeight(
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      _buildOrderDetailTile(
                                                        '',
                                                        item.orderDate != null
                                                            ? formatTimestamp(
                                                                item.orderDate!,
                                                                'hazırlanıyor')
                                                            : '--:--',
                                                        Icons.access_time,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child:
                                                            _buildOrderDetailTile(
                                                          '',
                                                          item.tableTitle ??
                                                              'Bilinmiyor',
                                                          Icons
                                                              .table_restaurant,
                                                        ),
                                                      ),
                                                      Container(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child:
                                                            _buildActionButtons(
                                                                item,
                                                                'teslim edildi',
                                                                'hazırlanıyor'),
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
                        // Bar Bölümü
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom:
                                        BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                                child: Text(
                                  'Bar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: barOrders.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.inbox_outlined,
                                                size: 36,
                                                color: Colors.grey[400]),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Şu anda siparişiniz yok',
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: barOrders.length,
                                        padding: const EdgeInsets.all(8),
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 6),
                                        itemBuilder: (context, index) {
                                          final item = barOrders[index];
                                          return Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey
                                                      .withOpacity(0.1)),
                                            ),
                                            child: Column(
                                              children: [
                                                IntrinsicHeight(
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child:
                                                            _buildOrderDetailTile(
                                                          '',
                                                          item.title ?? '',
                                                          Icons.restaurant_menu,
                                                        ),
                                                      ),
                                                      Container(
                                                        width: 80,
                                                        alignment:
                                                            Alignment.center,
                                                        child:
                                                            _buildOrderDetailTile(
                                                          '',
                                                          '${item.piece} adet',
                                                          Icons
                                                              .format_list_numbered,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                IntrinsicHeight(
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      _buildOrderDetailTile(
                                                        '',
                                                        item.orderDate != null
                                                            ? formatTimestamp(
                                                                item.orderDate!,
                                                                'hazırlanıyor')
                                                            : '--:--',
                                                        Icons.access_time,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child:
                                                            _buildOrderDetailTile(
                                                          '',
                                                          item.tableTitle ??
                                                              'Bilinmiyor',
                                                          Icons
                                                              .table_restaurant,
                                                        ),
                                                      ),
                                                      Container(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child:
                                                            _buildActionButtons(
                                                                item,
                                                                'teslim edildi',
                                                                'hazırlanıyor'),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildOrderColumn(context, 'Geçmiş Siparişler', pastOrders,
              'teslim edildi', menus, 'hazır',
              showRefresh: false),
        ],
      ),
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
    // final stockWarning = ref.watch(_menuProvider).stockWarning;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                        child: Icon(Icons.refresh,
                            size: 20, color: Colors.grey[600]),
                      ),
                      onPressed: isRefreshing ? null : _refreshData,
                    ),
                  ],
                  if (status == 'hazırlanıyor' && isProcessing)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange[300]!),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 36, color: Colors.grey[400]),
                          const SizedBox(height: 6),
                          Text(
                            'Şu anda siparişiniz yok',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: orders.length,
                      padding: const EdgeInsets.all(8),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = orders[index];
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                              const SizedBox(height: 6),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildOrderDetailTile(
                                      '',
                                      item.orderDate != null
                                          ? formatTimestamp(
                                              item.orderDate!, status)
                                          : '--:--',
                                      Icons.access_time,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildOrderDetailTile(
                                        '',
                                        item.tableTitle ?? 'Bilinmiyor',
                                        Icons.table_restaurant,
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.centerRight,
                                      child: status == 'hazır'
                                          ? _buildOrderDetailTile(
                                              '',
                                              item.status ?? '',
                                              item.status == 'teslim edildi'
                                                  ? Icons.check_circle_outline
                                                  : Icons.cancel_outlined,
                                            )
                                          : _buildActionButtons(
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
    );
  }

  Widget _buildOrderDetailTile(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: value == 'teslim edildi'
                  ? Colors.green
                  : value == 'iptal edildi'
                      ? Colors.red
                      : null,
            ),
            overflow: value.contains('.')
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(item, String nextStatus, String status) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'yeni') ...[
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.orange[50],
              minimumSize: const Size(36, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(
              Icons.restaurant,
              color: Colors.orange[600],
              size: 18,
            ),
            onPressed: isProcessing
                ? null
                : () async {
                    if (item.id != null) {
                      // Önce siparişi güncelle
                      await ref.read(adminProvider.notifier).updateOrderStatus(
                            item,
                            nextStatus,
                            orderType: 'Mutfak',
                          );

                      // Sonra mutfak fişini yazdır
                      await KitchenPrinterService.printKitchenOrder(
                          item.toJson());
                    }
                  },
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.purple[50],
              minimumSize: const Size(36, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(
              Icons.local_bar,
              color: Colors.purple[600],
              size: 18,
            ),
            onPressed: isProcessing
                ? null
                : () async {
                    if (item.id != null) {
                      // Önce siparişi güncelle
                      await ref.read(adminProvider.notifier).updateOrderStatus(
                            item,
                            nextStatus,
                            orderType: 'Bar',
                          );

                      // Sonra bar fişini yazdır
                      await BarPrinterService.printBarOrder(item.toJson());
                    }
                  },
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.red[50],
              minimumSize: const Size(36, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(
              Icons.cancel_outlined,
              color: Colors.red[600],
              size: 18,
            ),
            onPressed: isProcessing
                ? null
                : () async {
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            width: 400,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Sipariş İptali',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.grey[400],
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Bu siparişi iptal etmek istediğinizden emin misiniz?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text(
                                        'Vazgeç',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text(
                                        'İptal Et',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    if (confirm == true && item.id != null) {
                      ref
                          .read(adminProvider.notifier)
                          .updateOrderStatus(item, 'iptal edildi');
                    }
                  },
          ),
        ],
        if (nextStatus == 'teslim edildi')
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  minimumSize: const Size(36, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  Icons.close,
                  color: Colors.red[600],
                  size: 18,
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                width: 400,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Sipariş İptali',
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          icon: Icon(
                                            Icons.close,
                                            color: Colors.grey[400],
                                            size: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Bu siparişi iptal etmek istediğinizden emin misiniz?',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text(
                                            'Vazgeç',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text(
                                            'İptal Et',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );

                        if (confirm == true && item.id != null) {
                          ref
                              .read(adminProvider.notifier)
                              .updateOrderStatus(item, 'iptal edildi');
                        }
                      },
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        setState(() {
                          isProcessing = true;
                        });
                        try {
                          await ref
                              .read(adminProvider.notifier)
                              .updateOrderStatus(item, nextStatus);
                          await Future.delayed(
                              const Duration(milliseconds: 500));
                        } finally {
                          if (mounted) {
                            setState(() {
                              isProcessing = false;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Hazır',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

String formatTimestamp(Timestamp timestamp, String status) {
  final DateTime dateTime = timestamp.toDate().toLocal();

  // Tam tarih formatı
  final String day = dateTime.day.toString().padLeft(2, '0');
  final String month = dateTime.month.toString().padLeft(2, '0');
  final String year = dateTime.year.toString();
  final String hour = dateTime.hour.toString().padLeft(2, '0');
  final String minute = dateTime.minute.toString().padLeft(2, '0');

  final String fullDate = '$day.$month.$year $hour:$minute';

  if (status == 'hazır') {
    // Geçmiş siparişlerde tam tarihi göster
    return fullDate;
  } else {
    // Diğer durumlarda sadece saat
    return '$hour:$minute';
  }
}
