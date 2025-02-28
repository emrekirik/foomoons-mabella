import 'package:foomoons/featured/admin/admin_mobile_view.dart';
import 'package:foomoons/featured/menu/menu_mobile_view.dart';
import 'package:foomoons/featured/reports/reports_mobile_view.dart';
import 'package:foomoons/featured/tables/tables_mobile_view.dart';
import 'package:foomoons/product/constants/color_constants.dart';
import 'package:foomoons/product/widget/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foomoons/product/providers/app_providers.dart';

// Self service durumu için özel provider
final selfServiceProvider = Provider<bool>((ref) {
  final profileState = ref.watch(profileProvider);
  final isSelfService = profileState.isSelfService ?? false;
  print('🔍 SelfService State: $isSelfService'); // Debug print
  return isSelfService;
});

// Initial index provider
final initialIndexProvider = Provider<int>((ref) {
  final isSelfService = ref.watch(selfServiceProvider);
  print('🔍 Initial Index Provider - Self Service: $isSelfService'); // Debug print
  return 0; // Always start with first tab based on mode
});

// Navigation items provider
final navigationItemsProvider = Provider<List<NavigationRailDestination>>((ref) {
  final isSelfService = ref.watch(selfServiceProvider);
  return _buildNavigationItems('kafe', isSelfService);
});

// Page views provider
final pageViewsProvider = Provider<List<Widget>>((ref) {
  final isSelfService = ref.watch(selfServiceProvider);
  return _buildPageViews('kafe', isSelfService);
});

class TabMobileView extends ConsumerStatefulWidget {
  final int? initialTabIndex;
  const TabMobileView({super.key, this.initialTabIndex});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TabMobileViewState();
}

class _TabMobileViewState extends ConsumerState<TabMobileView>
    with SingleTickerProviderStateMixin {
  late int _tabIndex;
  late PageController _pageController;
  NavigationRailLabelType labelType = NavigationRailLabelType.all;
  bool showLeading = false;
  bool showTrailing = false;
  double groupAlignment = -1.0;
  Map<String, dynamic>? userDetails;

  @override
  void initState() {
    super.initState();
    final providedIndex = widget.initialTabIndex;
    final defaultIndex = ref.read(initialIndexProvider);
    print('🔍 TabMobileView initState - Provided Index: $providedIndex, Default Index: $defaultIndex'); // Debug print
    _tabIndex = providedIndex ?? defaultIndex;
    print('🔍 Final _tabIndex value: $_tabIndex'); // Debug print
    _pageController = PageController(initialPage: _tabIndex);
    Future.microtask(() {
      final profileState = ref.read(profileProvider);
      if (profileState.businessName == null) {
        print('🔍 Fetching profile data...'); // Debug print
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

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
/*     if (userDetails == null) {
      // Kullanıcı bilgileri yüklenmemişse gösterilecek içerik
      return const SizedBox();
    } */
    const String userType = 'kafe';

    // Provider'lardan navigation items ve page views'ı al
    final navigationItems = ref.watch(navigationItemsProvider);
    final pageViews = ref.watch(pageViewsProvider);

    return Container(
      color: ColorConstants.white,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Scaffold(
                backgroundColor: ColorConstants.white,
                extendBody: true,
                appBar: const PreferredSize(
                  preferredSize: Size.fromHeight(70.0),
                  child: CustomAppbar(
                    userType: userType,
                    showDrawer: true,
                    showBackButton: false,
                  ),
                ),
                drawer: Drawer(
                  backgroundColor: Colors.white,
                  width: deviceWidth * 0.20,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Color(0xFFF8F9FA),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: NavigationRail(
                      selectedIndex: _tabIndex,
                      groupAlignment: groupAlignment,
                      onDestinationSelected: (int index) {
                        setState(() {
                          _onTabChanged(index);
                        });
                      },
                      backgroundColor: Colors.transparent,
                      labelType: labelType,
                      useIndicator: true,
                      indicatorColor: Colors.orange.withOpacity(0.1),
                      selectedIconTheme: const IconThemeData(
                        color: Colors.orange,
                        size: 20,
                      ),
                      unselectedIconTheme: const IconThemeData(
                        color: Color(0xFF37474F),
                        size: 20,
                      ),
                      selectedLabelTextStyle: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      unselectedLabelTextStyle: GoogleFonts.poppins(
                        color: Color(0xFF37474F),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      leading: showLeading
                          ? FloatingActionButton(
                              elevation: 0,
                              onPressed: () {
                                // Add your onPressed code here!
                              },
                              child: const Icon(Icons.add),
                            )
                          : const SizedBox(),
                      trailing: showTrailing
                          ? IconButton(
                              onPressed: () {
                                // Add your onPressed code here!
                              },
                              icon: const Icon(Icons.more_horiz_rounded),
                            )
                          : const SizedBox(),
                      destinations: navigationItems,
                    ),
                  ),
                ),
                body: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _tabIndex = index;
                      });
                    },
                    children: pageViews),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<NavigationRailDestination> _buildNavigationItems(String userType, bool isSelfService) {
  TextStyle labelStyle = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  Widget buildLabel(String text) {
    return SizedBox(
      width: 80,
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: labelStyle,
      ),
    );
  }

  if (userType == 'çalışan') {
    return [
      NavigationRailDestination(
        icon: const Icon(Icons.monitor_rounded),
        selectedIcon: const Icon(Icons.monitor_rounded),
        label: buildLabel('Siparişler'),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.table_bar_outlined),
        selectedIcon: const Icon(Icons.table_bar_outlined),
        label: buildLabel('Adisyonlar'),
      ),
    ];
  } else if (userType == 'kafe') {
    if (isSelfService) {
      return [
        NavigationRailDestination(
          icon: const Icon(Icons.insert_chart_outlined_rounded),
          selectedIcon: const Icon(Icons.insert_chart_outlined_rounded),
          label: buildLabel('Raporlar'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.restaurant_menu_sharp),
          selectedIcon: const Icon(Icons.restaurant_menu),
          label: buildLabel('Menu'),
        ),
      ];
    } else {
      return [
        NavigationRailDestination(
          icon: const Icon(Icons.table_bar_outlined),
          selectedIcon: const Icon(Icons.table_bar_outlined),
          label: buildLabel('Adisyonlar'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.monitor_rounded),
          selectedIcon: const Icon(Icons.monitor_rounded),
          label: buildLabel('Siparişler'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.restaurant_menu_sharp),
          selectedIcon: const Icon(Icons.restaurant_menu),
          label: buildLabel('Menu'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.insert_chart_outlined_rounded),
          selectedIcon: const Icon(Icons.insert_chart_outlined_rounded),
          label: buildLabel('Raporlar'),
        ),
      ];
    }
  } else {
    return [];
  }
}

List<Widget> _buildPageViews(String userType, bool isSelfService) {
  if (isSelfService) {
    // Self-service modunda Raporlar ve Menu sayfaları
    return [
      const ReportsMobileView(),
      const MenuMobileView(),
    ];
  }
  
  // Normal modda tüm sayfalar yeni sıralama ile
  return [
    TablesMobileView(isSelfService: isSelfService),
    const AdminMobileView(),
    const MenuMobileView(),
    const ReportsMobileView(),
  ];
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
