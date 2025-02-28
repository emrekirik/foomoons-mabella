import 'package:foomoons/featured/providers/profile_notifier.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:foomoons/featured/profile/profile_info_showdialog.dart';
import 'package:foomoons/product/services/printer_service.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final TextEditingController profileImageController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  Map<String, dynamic>? userDetails;

  @override
  void initState() {
    super.initState();
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

    return Column(
      children: [
       /*  if (isLoading)
          LinearProgressIndicator(
            color: Colors.black,
            backgroundColor: Colors.grey[200],
          ), */
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
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFE5E5E5),
                        width: 1,
                      ),
                    ),
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
            backgroundColor: Color(0xFFF5F5F7),
            body: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              isLoading
                                  ? _buildProfilePhotoShimmer()
                                  : _ProfilePhotoSection(
                                      deviceWidth: deviceWidth,
                                      profileNotifier: profileNotifier,
                                      profileState: profileState,
                                    ),
                              const SizedBox(height: 16),
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
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Column(
                          children: [
                            isLoading
                                ? _buildUserDataShimmer(deviceHeight)
                                : _UserDataSection(
                                    deviceHeight: deviceHeight,
                                    profileState: profileState,
                                    profileNotifier: profileNotifier,
                                  ),
                            const SizedBox(height: 30),
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
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
          SizedBox(height: deviceHeight * 0.015),
          _buildShimmerText('İsim: '),
          SizedBox(height: deviceHeight * 0.01),
          _buildShimmerText('Telefon: '),
          SizedBox(height: deviceHeight * 0.01),
          _buildShimmerText('Email: '),
          SizedBox(height: deviceHeight * 0.015),
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
          SizedBox(height: deviceHeight * 0.015),
          _buildShimmerText('İşletme Adı: '),
          SizedBox(height: deviceHeight * 0.015),
          _buildShimmerText('İşletme Adresi: '),
          SizedBox(height: deviceHeight * 0.015),
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
            letterSpacing: -0.3,
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

class _BusinessDataSection extends StatefulWidget {
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

  @override
  State<_BusinessDataSection> createState() => _BusinessDataSectionState();
}

class _BusinessDataSectionState extends State<_BusinessDataSection> {
  late TextEditingController _printerIpController;
  late TextEditingController _printerNameController;
  late TextEditingController _printer2IpController;
  late TextEditingController _printer2NameController;
  List<String> _availablePrinters = [];

  void _loadPrinters() {
    try {
      final printers = PrinterService.getAvailablePrinters();
      setState(() {
        _availablePrinters = printers;
      });
    } catch (e) {
      print('❌ Hata oluştu: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _printerIpController = TextEditingController(text: widget.profileState.printerIpAddress);
    _printerNameController = TextEditingController(text: widget.profileState.printerName);
    _printer2IpController = TextEditingController(text: widget.profileState.printer2IpAddress);
    _printer2NameController = TextEditingController(text: widget.profileState.printer2Name);
    _loadPrinters();
  }

  @override
  void didUpdateWidget(covariant _BusinessDataSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileState.printerIpAddress != widget.profileState.printerIpAddress) {
      _printerIpController.text = widget.profileState.printerIpAddress ?? '';
    }
    if (oldWidget.profileState.printerName != widget.profileState.printerName) {
      _printerNameController.text = widget.profileState.printerName ?? '';
    }
    if (oldWidget.profileState.printer2IpAddress != widget.profileState.printer2IpAddress) {
      _printer2IpController.text = widget.profileState.printer2IpAddress ?? '';
    }
    if (oldWidget.profileState.printer2Name != widget.profileState.printer2Name) {
      _printer2NameController.text = widget.profileState.printer2Name ?? '';
    }
  }

  @override
  void dispose() {
    _printerIpController.dispose();
    _printerNameController.dispose();
    _printer2IpController.dispose();
    _printer2NameController.dispose();
    super.dispose();
  }

  Future<void> _savePrinterName() async {
    widget.profileNotifier.updatePrinterName(_printerNameController.text);
    await widget.profileNotifier.savePrinterName();
    print('✅ Yazıcı 1 ismi kaydedildi: ${_printerNameController.text}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yazıcı 1 ismi kaydedildi')),
      );
    }
  }

  Future<void> _savePrinterIp() async {
    widget.profileNotifier.updatePrinterIpAddress(_printerIpController.text);
    await widget.profileNotifier.savePrinterIpAddress();
    print('✅ Yazıcı 1 IP adresi kaydedildi: ${_printerIpController.text}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yazıcı 1 IP adresi kaydedildi')),
      );
    }
  }

  Future<void> _savePrinter2Name() async {
    widget.profileNotifier.updatePrinter2Name(_printer2NameController.text);
    await widget.profileNotifier.savePrinter2Name();
    print('✅ Yazıcı 2 ismi kaydedildi: ${_printer2NameController.text}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yazıcı 2 ismi kaydedildi')),
      );
    }
  }

  Future<void> _savePrinter2Ip() async {
    widget.profileNotifier.updatePrinter2IpAddress(_printer2IpController.text);
    await widget.profileNotifier.savePrinter2IpAddress();
    print('✅ Yazıcı 2 IP adresi kaydedildi: ${_printer2IpController.text}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yazıcı 2 IP adresi kaydedildi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CustomTitle(
                deviceHeight: widget.deviceHeight,
                title: 'İşletme Bilgileri',
              ),
              InkWell(
                onTap: () => showBusinessInfoDialog(
                  context: context,
                  businessName: widget.profileState.businessName ?? '',
                  address: widget.profileState.businessAddress ?? '',
                  info: widget.profileState.businessInfo ?? '',
                  onSave: (businessName, address, info) async {
                    await widget.profileNotifier.updateProfileInfo(
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
          SizedBox(height: widget.deviceHeight * 0.015),
          _CustomText(
            title: 'İşletme Adı: ',
            desc: widget.profileState.businessName ?? '',
          ),
          SizedBox(height: widget.deviceHeight * 0.015),
          _CustomText(
            title: 'İşletme Adresi: ',
            desc: widget.profileState.businessAddress ?? '',
          ),
          SizedBox(height: widget.deviceHeight * 0.015),
          _CustomTextVertical(
            title: 'İşletme Hakkında: ',
            desc: widget.profileState.businessInfo ?? '',
          ),
          SizedBox(height: widget.deviceHeight * 0.02),
          InkWell(
            onTap: () async {
              final success = await widget.profileNotifier.pickAndUploadBusinessImage();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          success ? 'İşletme fotoğrafı başarıyla yüklendi' : 'Fotoğraf yüklenirken bir hata oluştu',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
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
                  if (widget.profileState.isUploading)
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
          SizedBox(height: widget.deviceHeight * 0.02),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Bar Yazıcısı',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Bar siparişleri için yazıcı ayarları',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _availablePrinters.contains(_printerNameController.text) 
                                ? _printerNameController.text 
                                : null,
                            hint: Text(
                              'Yazıcı Seçin',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                            items: _availablePrinters.map((String printer) {
                              return DropdownMenuItem<String>(
                                value: printer,
                                child: Text(
                                  printer,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _printerNameController.text = newValue;
                                });
                                _savePrinterName();
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.grey[400], size: 20),
                        onPressed: _loadPrinters,
                        tooltip: 'Yazıcıları Yenile',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: widget.deviceHeight * 0.015),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _printerNameController,
                    decoration: InputDecoration(
                      hintText: 'Yazıcı 1 İsmi',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      prefixIcon: Icon(Icons.local_printshop, color: Colors.grey[400], size: 20),
                      isDense: true,
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    onSubmitted: (_) => _savePrinterName(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.save, color: Colors.grey[400], size: 20),
                  onPressed: _savePrinterName,
                ),
              ],
            ),
          ),
          SizedBox(height: widget.deviceHeight * 0.015),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _printerIpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Yazıcı 1 IP Adresi',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      prefixIcon: Icon(Icons.print, color: Colors.grey[400], size: 20),
                      isDense: true,
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    onSubmitted: (_) => _savePrinterIp(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.save, color: Colors.grey[400], size: 20),
                  onPressed: _savePrinterIp,
                ),
              ],
            ),
          ),
          SizedBox(height: widget.deviceHeight * 0.03),
          // Yazıcı 2 Bölümü
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Mutfak Yazıcısı',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Mutfak siparişleri için yazıcı ayarları',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _availablePrinters.contains(_printer2NameController.text) 
                                ? _printer2NameController.text 
                                : null,
                            hint: Text(
                              'Yazıcı Seçin',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                            items: _availablePrinters.map((String printer) {
                              return DropdownMenuItem<String>(
                                value: printer,
                                child: Text(
                                  printer,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _printer2NameController.text = newValue;
                                });
                                _savePrinter2Name();
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.grey[400], size: 20),
                        onPressed: _loadPrinters,
                        tooltip: 'Yazıcıları Yenile',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: widget.deviceHeight * 0.015),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _printer2NameController,
                    decoration: InputDecoration(
                      hintText: 'Yazıcı 2 İsmi',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      prefixIcon: Icon(Icons.local_printshop, color: Colors.grey[400], size: 20),
                      isDense: true,
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    onSubmitted: (_) => _savePrinter2Name(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.save, color: Colors.grey[400], size: 20),
                  onPressed: _savePrinter2Name,
                ),
              ],
            ),
          ),
          SizedBox(height: widget.deviceHeight * 0.015),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _printer2IpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Yazıcı 2 IP Adresi',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      prefixIcon: Icon(Icons.print, color: Colors.grey[400], size: 20),
                      isDense: true,
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    onSubmitted: (_) => _savePrinter2Ip(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.save, color: Colors.grey[400], size: 20),
                  onPressed: _savePrinter2Ip,
                ),
              ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
        /*       InkWell(
                onTap: () => showProfileInfoDialog(
                  context: context,
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
          SizedBox(height: deviceHeight * 0.015),
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
          SizedBox(height: deviceHeight * 0.015),
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
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: GestureDetector(
              onTap: () {
           /*      profileNotifier.pickAndUploadImage(); */
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
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            letterSpacing: -0.3,
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
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: GoogleFonts.poppins(
            fontSize: 20,
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
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        letterSpacing: -0.5,
      ),
    );
  }
}
