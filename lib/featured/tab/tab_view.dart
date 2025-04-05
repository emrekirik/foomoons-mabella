import 'package:foomoons/featured/admin/admin_view.dart';
import 'package:foomoons/featured/bill/bill_view.dart';
import 'package:foomoons/featured/menu/menu_view.dart';
import 'package:foomoons/featured/past_bills/past_bills_view.dart';
import 'package:foomoons/featured/reports/reports_mobile_view.dart';
import 'package:foomoons/product/constants/color_constants.dart';
import 'package:foomoons/product/widget/custom_appbar.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:foomoons/featured/tables/tables_view.dart';
import 'package:foomoons/featured/reports/reports_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';

class TabView extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const TabView({super.key, this.initialTabIndex = 1}); // Default olarak 2

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TabViewState();
}

class _TabViewState extends ConsumerState<TabView> {
  late int _tabIndex;
  late PageController _pageController;
  final String userType = 'kafe'; // Varsayılan olarak kafe tipini kullan

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex;
    _pageController = PageController(initialPage: _tabIndex);
    Future.microtask(() {
      final profileState = ref.read(profileProvider);
      if (profileState.businessName == null) {
        ref.read(profileProvider.notifier).fetchAndLoad();
      }
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _tabIndex = index;
      _pageController.jumpToPage(_tabIndex);
    });
  }

  List<Widget> _buildNavigationItems(String userType, double deviceWidth) {
    final profileState = ref.watch(profileProvider);
    final isSelfService = profileState.isSelfService ?? false;
    // "çalışan" için farklı, "kafe" için farklı sekmeler döndürüyoruz
    if (userType == 'çalışan') {
      return [
        _buildNavItem(Icons.monitor_rounded, 'Siparişler', 0, deviceWidth),
        _buildNavItem(Icons.table_bar_outlined, 'Adisyonlar', 1, deviceWidth),
      ];
    } else if (userType == 'kafe') {
      return [
        _buildNavItem(Icons.restaurant_menu, 'Menu', 0, deviceWidth),
        if (isSelfService == false)
          _buildNavItem(Icons.monitor_rounded, 'Siparişler', 1, deviceWidth),
        _buildNavItem(Icons.table_bar_outlined, 'Adisyonlar',
            isSelfService ? 1 : 2, deviceWidth),
        _buildNavItem(Icons.history, 'Geçmiş Adisyonlar', isSelfService ? 2 : 3,
            deviceWidth),
        _buildNavItem(Icons.insert_chart_outlined_rounded, 'Raporlar',
            isSelfService ? 3 : 4, deviceWidth),
      ];
    } else {
      return []; // Desteklenmeyen kullanıcı tipi
    }
  }

  Widget _buildNavItem(
      IconData icon, String label, int index, double deviceWidth) {
    /*  return Column(
      mainAxisAlignment:
          deviceWidth < 600 ? MainAxisAlignment.center : MainAxisAlignment.end,
      children: [
        Icon(icon, size: 30),
        if (_tabIndex != index && deviceWidth >= 600)
          Text(label), // Label sadece seçili değilse gösterilir
      ],
    ); */
    return Icon(icon, size: 20);
  }

  List<Widget> _buildPageViews(String userType, double deviceWidth) {
    final profileState = ref.watch(profileProvider);
    final isSelfService = profileState.isSelfService ?? false;

    final pages = [
      if (userType == 'kafe') const MenuView(),
      if (isSelfService == false) const AdminView(),
      if (isSelfService)
        BillView(
          tableId: 139,
          tableTitle: 'Salon 1',
          isSelfService: isSelfService,
        )
      else
        TablesView(isSelfService: isSelfService),
      /* if (userType == 'kafe') const StockView(), */
      if (userType == 'kafe')
        deviceWidth < 800 ? const ReportsMobileView() : const ReportsView(),
      const PastBillsView(),
    ];
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    final List<Widget> navigationItems =
        _buildNavigationItems(userType, deviceWidth);
    final List<Widget> pageViews = _buildPageViews(userType, deviceWidth);

    return Column(
      children: [
        /*  if (isLoading)
          const LinearProgressIndicator(
            color: Colors.green,
            minHeight: 4,
          ), */
        Expanded(
          child: Scaffold(
            backgroundColor: ColorConstants.appbackgroundColor,
            extendBody: true,
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CurvedNavigationBar(
                    index: _tabIndex,
                    animationCurve: Curves.fastLinearToSlowEaseIn,
                    animationDuration: const Duration(milliseconds: 800),
                    height: 44,
                    color: const Color(0xFFE2E8F0),
                    items: navigationItems,
                    backgroundColor: ColorConstants.appbackgroundColor,
                    onTap: (index) {
                      _onTabChanged(index);
                    },
                  ),
                ),
              ),
            ),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(70.0),
              child: CustomAppbar(
                userType: userType,
                showDrawer: false,
                showBackButton: false,
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: pageViews,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SideShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    // Sol gölge
    canvas.drawRect(
      Rect.fromLTRB(-7, 0, 0, size.height),
      paint,
    );

    // Sağ gölge
    canvas.drawRect(
      Rect.fromLTRB(size.width, 0, size.width + 7, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
