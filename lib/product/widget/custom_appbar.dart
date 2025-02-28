import 'package:foomoons/featured/auth/login_view.dart';
import 'package:foomoons/featured/profile/profile_mobile_view.dart';
import 'package:foomoons/featured/profile/profile_view.dart';
import 'package:foomoons/featured/responsive/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CustomAppbar extends ConsumerStatefulWidget {
  final bool showBackButton;
  final bool showDrawer;
  final String userType;
  const CustomAppbar({
    super.key,
    required this.userType,
    required this.showBackButton,
    required this.showDrawer,
  });

  @override
  ConsumerState<CustomAppbar> createState() => _CustomAppbarState();
}

class _CustomAppbarState extends ConsumerState<CustomAppbar> {
  void _handleMenuSelection(String value, BuildContext context) async {
    if (!mounted) return;
    
    switch (value) {
      case 'Profile':
        if (context.mounted) {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const ResponsiveLayout(
              desktopBody: ProfileView(),
              mobileBody: ProfileMobileView(),
            ),
          ));
        }
        break;
      case 'Logout':
        if (context.mounted) {
          // Loading dialog göster
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: LoadingAnimationWidget.flickr(
                leftDotColor: const Color(0xFFFF8A00),
                rightDotColor: const Color(0xFF00B761),
                size: 45,
              ),
            ),
          );
          
          // Logout işlemini gerçekleştir
          await ref.read(loginProvider.notifier).signOut();
          
          // Loading dialog'u kapat
          if (context.mounted) {
            Navigator.pop(context); // Dialog'u kapat
            
            // Login sayfasına yönlendir
            await Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LoginView(),
              ),
            );
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizeWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Container(
        width: sizeWidth * 0.8,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(52),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: -1,
              blurRadius: 6,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.showDrawer == false
                    ? const SizedBox()
                    : IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                widget.showBackButton
                    ? IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_ios_new))
                    : const SizedBox(),
              ],
            ),
            Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
            Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.grey[300],
                radius: 16,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.person, size: 16),
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 8),
                  onSelected: (value) => _handleMenuSelection(value, context),
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    if (widget.userType == 'kafe')
                      const PopupMenuItem<String>(
                        value: 'Profile',
                        child: Text('Profile'),
                      ),
                    const PopupMenuItem<String>(
                      value: 'Logout',
                      child: Text('Logout'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
