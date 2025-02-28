import 'package:foomoons/featured/providers/login_notifier.dart';
import 'package:foomoons/featured/responsive/responsive_layout.dart';
import 'package:foomoons/featured/tab/tab_mobile_view.dart';
import 'package:foomoons/featured/tab/tab_view.dart';
import 'package:foomoons/product/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:google_fonts/google_fonts.dart';

// Özel sayfa geçiş animasyonu
class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          maintainState: true,
        );
}

class LoginView extends ConsumerWidget {
  LoginView({super.key});

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;

    final loginNotifier = ref.watch(loginProvider.notifier);
    final loginState = ref.watch(loginProvider);
    final showPassword = ValueNotifier(false);
    print('login view girildi');
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ColorConstants.thirdColor,
      body: SingleChildScrollView(
        child: SizedBox(
          height: deviceHeight,
          child: _LoginContent(
            deviceWidth: deviceWidth,
            emailController: emailController,
            showPassword: showPassword,
            passwordController: passwordController,
            loginNotifier: loginNotifier,
            loginState: loginState,
          ),
        ),
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent({
    required this.deviceWidth,
    required this.emailController,
    required this.showPassword,
    required this.passwordController,
    required this.loginNotifier,
    required this.loginState,
  });

  final double deviceWidth;
  final TextEditingController emailController;
  final ValueNotifier<bool> showPassword;
  final TextEditingController passwordController;
  final LoginNotifier loginNotifier;
  final LoginState loginState;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: isSmallScreen ? size.width * 0.9 : 400,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: ColorConstants.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: isSmallScreen ? size.width * 0.15 : 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  "FOO Moons'da oturum aç",
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 22 : 26,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email adresinizi girin',
                        fillColor: Colors.grey[50],
                        filled: true,
                        prefixIcon: const Icon(Icons.email, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.orange[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Şifre',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder(
                      valueListenable: showPassword,
                      builder: (context, value, child) {
                        return TextField(
                          controller: passwordController,
                          obscureText: !value,
                          decoration: InputDecoration(
                            hintText: 'Şifrenizi girin',
                            fillColor: Colors.grey[50],
                            filled: true,
                            prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(
                                value ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                showPassword.value = !showPassword.value;
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange[300]!),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.secondColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: loginState.isLoading
                        ? null
                        : () async {
                            if (emailController.text.isEmpty || 
                                passwordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lütfen email ve şifrenizi girin'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final message = await loginNotifier.login(
                              email: emailController.text,
                              password: passwordController.text,
                            );

                            if (message!.contains('Success')) {
                              if (context.mounted) {
                                await Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Consumer(
                                      builder: (context, ref, child) {
                                        final initialIndex = ref.read(initialIndexProvider);
                                        return ResponsiveLayout(
                                          desktopBody: const TabView(),
                                          mobileBody: TabMobileView(initialTabIndex: initialIndex),
                                        );
                                      }
                                    ),
                                  ),
                                  (route) => false,
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: loginState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Giriş Yap',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
