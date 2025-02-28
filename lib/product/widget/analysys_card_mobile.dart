import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foomoons/product/providers/app_providers.dart';
import 'package:shimmer/shimmer.dart';

class AnalysysCardMobile extends ConsumerWidget {
  final String cardTitle;
  final String assetImage;
  final String cardSubtitle;
  final Widget subTitleIcon;
  final String cardPiece;
  final int? businessId;

  const AnalysysCardMobile({
    super.key,
    required this.cardTitle,
    required this.assetImage,
    required this.cardSubtitle,
    required this.subTitleIcon,
    required this.cardPiece,
    this.businessId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(loadingProvider).isLoading('reports');
    final deviceWidth = MediaQuery.of(context).size.width;
    final bool isCentered = cardTitle == 'Toplam Hasılat' && businessId == 14;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? _buildShimmerLoading(deviceWidth)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (deviceWidth >= 850) ...[
                  Image.asset(
                    assetImage,
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: isCentered
                        ? CrossAxisAlignment.center 
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cardPiece,
                        style: TextStyle(
                          fontSize: deviceWidth < 400 ? 28 : 32,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -0.5,
                          color: Colors.black,
                        ),
                        textAlign: isCentered
                            ? TextAlign.center 
                            : TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cardTitle,
                        style: TextStyle(
                          fontSize: deviceWidth < 400 ? 14 : 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        textAlign: isCentered
                            ? TextAlign.center 
                            : TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: isCentered
                            ? MainAxisAlignment.center 
                            : MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.graphic_eq,
                            size: deviceWidth < 400 ? 12 : 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cardSubtitle,
                            style: TextStyle(
                              fontSize: deviceWidth < 400 ? 10 : 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildShimmerLoading(double deviceWidth) {
    final bool isCentered = cardTitle == 'Toplam Hasılat' && businessId == 14;
    
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (deviceWidth >= 850) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: isCentered
                  ? CrossAxisAlignment.center 
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: deviceWidth < 400 ? 32 : 36,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: deviceWidth < 400 ? 16 : 18,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isCentered
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Container(
                      width: deviceWidth < 400 ? 12 : 14,
                      height: deviceWidth < 400 ? 12 : 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      height: deviceWidth < 400 ? 12 : 14,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
