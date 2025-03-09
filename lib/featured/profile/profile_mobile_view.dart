import 'package:foomoons/featured/profile/show_personel_info_bottomsheet.dart';
import 'package:foomoons/featured/providers/profile_notifier.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';


class ProfileMobileView extends ConsumerStatefulWidget {
  const ProfileMobileView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ProfileMobileViewState();
}

class _ProfileMobileViewState extends ConsumerState<ProfileMobileView> {
  final TextEditingController profileImageController = TextEditingController();

  final TextEditingController nameController = TextEditingController();

  final TextEditingController titleController = TextEditingController();
  Map<String, dynamic>? userDetails;

  @override
  void initState() {
    super.initState();
    // Sadece state boşsa veri yükle
    Future.microtask(() {
      final profileState = ref.read(profileProvider);
      if (profileState.businessName == null) {
        ref.read(profileProvider.notifier).fetchAndLoad();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider).isLoading('profile');
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;
    final profileState = ref.watch(profileProvider);
    final profileNotifier = ref.read(profileProvider.notifier);

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            if (isLoading)
              const LinearProgressIndicator(
                color: Colors.green,
              ),
            Expanded(
              child: Scaffold(
                appBar: PreferredSize(
                  preferredSize: Size.fromHeight(60.0),
                  child: AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    systemOverlayStyle: SystemUiOverlayStyle.dark,
                    flexibleSpace: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    title: Image.asset(
                      'assets/images/logo.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                    centerTitle: true,
                  ),
                ),
                backgroundColor: Colors.grey[50],
                body: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            isLoading
                                ? _buildProfilePhotoShimmer()
                                : _ProfilePhotoSection(
                                    deviceWidth: deviceWidth,
                                    profileNotifier: profileNotifier,
                                    profileState: profileState,
                                  ),
                            const SizedBox(height: 20),
                            if (isLoading) ...[
                              _buildNameEmailShimmer(),
                            ] else ...[
                              Text(
                                profileState.name ?? 'İsim Belirtilmemiş',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                profileState.email ?? 'Email Belirtilmemiş',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            isLoading
                                ? _buildUserDataShimmer(deviceHeight)
                                : _UserDataSection(
                                    deviceHeight: deviceHeight,
                                    profileState: profileState,
                                    profileNotifier: profileNotifier,
                                  ),
                            const SizedBox(height: 24),
                            isLoading
                                ? _buildBusinessDataShimmer(deviceHeight)
                                : _BusinessDataSection(
                                    deviceHeight: deviceHeight,
                                    deviceWidth: deviceWidth,
                                    profileState: profileState,
                                    profileNotifier: profileNotifier,
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildNameEmailShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            width: 200,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 150,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDataShimmer(double deviceHeight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CustomTitle(
                deviceHeight: deviceHeight,
                title: 'ÜNVAN',
              ),
              Icon(
                Icons.edit,
                size: 20,
                color: Colors.orange[400],
              ),
            ],
          ),
          SizedBox(height: deviceHeight * 0.02),
          _buildShimmerText('İsim: '),
          SizedBox(height: deviceHeight * 0.01),
          _buildShimmerText('Telefon: '),
          SizedBox(height: deviceHeight * 0.01),
          _buildShimmerText('Email: '),
          SizedBox(height: deviceHeight * 0.02),
        ],
      ),
    );
  }

  Widget _buildBusinessDataShimmer(double deviceHeight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CustomTitle(
                deviceHeight: deviceHeight,
                title: 'İşletme Bilgileri',
              ),
              Icon(
                Icons.edit,
                size: 20,
                color: Colors.orange[400],
              ),
            ],
          ),
          SizedBox(height: deviceHeight * 0.02),
          _buildShimmerText('İşletme Adı: '),
          SizedBox(height: deviceHeight * 0.02),
          _buildShimmerText('İşletme Adresi: '),
          SizedBox(height: deviceHeight * 0.02),
          _buildShimmerText('İşletme Hakkında: '),
        ],
      ),
    );
  }

  Widget _buildShimmerText(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

class _BusinessDataSection extends StatelessWidget {
  const _BusinessDataSection({
    required this.deviceHeight,
    required this.deviceWidth,
    required this.profileState,
    required this.profileNotifier,
  });

  final double deviceHeight;
  final double deviceWidth;
  final ProfileState profileState;
  final ProfileNotifier profileNotifier;

  void _showPrinterIpDialog(
    BuildContext context,
    String title,
    String currentValue,
    Function(String) onSave,
  ) {
    final TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'IP adresini girin (örn: 192.168.1.100)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: Text(
              'Kaydet',
              style: GoogleFonts.poppins(
                color: Colors.orange[400],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CustomTitle(
                deviceHeight: deviceHeight,
                title: 'İşletme Bilgileri',
              ),
              InkWell(
                onTap: () => showBusinessInfoBottomSheet(
                  context,
                  businessName: profileState.businessName ?? '',
                  address: profileState.businessAddress ?? '',
                  info: profileState.businessInfo ?? '',
                  onSave: (businessName, address, info) async {
                    await profileNotifier.updateProfileInfo(
                      fieldName: 'businessAll',
                      updatedValue: '$businessName|$address|$info',
                    );
                  },
                ),
                child: Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.orange[400],
                ),
              ),
            ],
          ),
          SizedBox(height: deviceHeight * 0.02),
          _CustomText(
            title: 'İşletme Adı: ',
            desc: profileState.businessName ?? '',
          ),
          SizedBox(height: deviceHeight * 0.02),
          _CustomText(
            title: 'İşletme Adresi: ',
            desc: profileState.businessAddress ?? '',
          ),
          SizedBox(height: deviceHeight * 0.02),
          _CustomTextVertical(
            title: 'İşletme Hakkında: ',
            desc: profileState.businessInfo ?? '',
          ),
          SizedBox(height: deviceHeight * 0.02),
          // Bar Yazıcı IP Adresi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _CustomText(
                  title: 'Bar Yazıcı IP: ',
                  desc: profileState.printerIpAddress ?? 'Ayarlanmamış',
                ),
              ),
              IconButton(
                onPressed: () => _showPrinterIpDialog(
                  context,
                  'Bar Yazıcı IP',
                  profileState.printerIpAddress ?? '',
                  (value) async {
                    profileNotifier.updatePrinterIpAddress(value);
                    await profileNotifier.savePrinterIpAddress();
                  },
                ),
                icon: Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.orange[400],
                ),
              ),
            ],
          ),
          SizedBox(height: deviceHeight * 0.02),
          // Mutfak Yazıcı IP Adresi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _CustomText(
                  title: 'Mutfak Yazıcı IP: ',
                  desc: profileState.printer2IpAddress ?? 'Ayarlanmamış',
                ),
              ),
              IconButton(
                onPressed: () => _showPrinterIpDialog(
                  context,
                  'Mutfak Yazıcı IP',
                  profileState.printer2IpAddress ?? '',
                  (value) async {
                    profileNotifier.updatePrinter2IpAddress(value);
                    await profileNotifier.savePrinter2IpAddress();
                  },
                ),
                icon: Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.orange[400],
                ),
              ),
            ],
          ),
          SizedBox(height: deviceHeight * 0.02),
          InkWell(
            onTap: () async {
              final success = await profileNotifier.pickAndUploadBusinessImage();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'İşletme fotoğrafı başarıyla yüklendi',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.error,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Fotoğraf yüklenirken bir hata oluştu',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.upload,
                    size: 20,
                    color: Colors.orange[400],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'İşletme Fotoğrafı Yükle',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (profileState.isUploading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[400]!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserDataSection extends ConsumerWidget {
  const _UserDataSection({
    required this.deviceHeight,
    required this.profileState,
    required this.profileNotifier,
  });

  final double deviceHeight;
  final ProfileState profileState;
  final ProfileNotifier profileNotifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CustomTitle(
                deviceHeight: deviceHeight,
                title: 'ÜNVAN',
              ),
      /*         InkWell(
                onTap: () => showPersonalInfoBottomSheet(
                  context,
                  name: profileState.name ?? '',
                  email: profileState.email ?? '',
                  phone: profileState.userPhoneNumber ?? '',
                  onSave: (name, email, phone) {
                    ref.read(profileProvider.notifier).updateProfileInfo(
                      fieldName: 'name',
                      updatedValue: name,
                    );
                    ref.read(profileProvider.notifier).updateProfileInfo(
                      fieldName: 'phoneNumber',
                      updatedValue: phone,
                    );
                  },
                ),
                child: Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.orange[400],
                ),
              ), */
            ],
          ),
          SizedBox(height: deviceHeight * 0.02),
          _CustomText(
            title: 'İsim: ',
            desc: profileState.name ?? 'Bilinmiyor',
          ),
          SizedBox(height: deviceHeight * 0.01),
          _CustomText(
            title: 'Telefon: ',
            desc: profileState.userPhoneNumber ?? '',
          ),
          SizedBox(height: deviceHeight * 0.01),
          _CustomText(
            title: 'Email: ',
            desc: profileState.email ?? 'bilinmiyor',
          ),
          SizedBox(height: deviceHeight * 0.02),
        ],
      ),
    );
  }
}

class _ProfilePhotoSection extends StatelessWidget {
  const _ProfilePhotoSection({
    required this.profileNotifier,
    required this.profileState,
    required this.deviceWidth,
  });
  final ProfileNotifier profileNotifier;
  final ProfileState profileState;
  final double deviceWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: GestureDetector(
              onTap: () {
              //  profileNotifier.pickAndUploadImage();
              },
              child: ClipOval(
                child: profileState.photoURL != null
                    ? Image.network(
                        profileState.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/personal_placeholder.png',
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/personal_placeholder.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          if (profileState.isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange[400],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomText extends StatelessWidget {
  final String title;
  final String desc;

  const _CustomText({
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CustomTextVertical extends StatelessWidget {
  final String title;
  final String desc;

  const _CustomTextVertical({
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CustomTitle extends StatelessWidget {
  final String title;
  final double deviceHeight;

  const _CustomTitle({
    required this.title,
    required this.deviceHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.orange[700],
      ),
    );
  }
}
