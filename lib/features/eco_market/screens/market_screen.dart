import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// 🔥 FIX: Import path corrected based on your folder structure 🔥
import '../providers/market_provider.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  Future<void> _launchWhatsApp(BuildContext context, String phone, String productTitle) async {
    final String message = 'Hello, I am interested in buying "$productTitle" from the Vanam App.';
    final Uri uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp. Please install WhatsApp.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening WhatsApp.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketState = ref.watch(marketProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F0F11) : const Color(0xFFF4F6F9);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    const primaryGreen = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🔥 Premium App Bar 🔥
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : primaryGreen,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 60, bottom: 16, right: 16),
              title: const Text(
                'Eco-Market',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?w=800&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        // 🔥 FIX: Changed withOpacity to withValues to fix warnings 🔥
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.8)
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 80,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔥 Content Body 🔥
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text(
                'Support local forest communities. Buy authentic natural products directly with Zero Commission.',
                style: TextStyle(color: subTextColor, fontSize: 14.5, fontWeight: FontWeight.w500, height: 1.5),
              ),
            ),
          ),

          // 🔥 Loading State 🔥
          if (marketState.isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: primaryGreen),
                    const SizedBox(height: 16),
                    Text('Fetching forest products...', style: TextStyle(color: subTextColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )

          // 🔥 Empty State 🔥
          else if (marketState.products.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No direct forest products listed right now.',
                  style: TextStyle(color: subTextColor, fontSize: 16),
                ),
              ),
            )

          // 🔥 Products List 🔥
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final product = marketState.products[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA), width: 1.2),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🖼 Product Image
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            child: Stack(
                              children: [
                                Image.network(
                                  product.imageUrl,
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 220,
                                    color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
                                    child: Icon(Icons.image_not_supported, color: subTextColor, size: 40),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row( // Added const here
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 14),
                                        SizedBox(width: 4),
                                        Text('100% Direct', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 📝 Product Details
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: textColor,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          product.price,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: primaryGreen,
                                          ),
                                        ),
                                        Text(
                                          'per ${product.unit}',
                                          style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.person_pin_circle_rounded, color: Colors.orange.shade700, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'By ${product.villagerName}',
                                        style: TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  product.description,
                                  style: TextStyle(fontSize: 13.5, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, height: 1.5),
                                ),
                                const SizedBox(height: 24),

                                // 🟢 WhatsApp Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchWhatsApp(context, product.phone, product.title),
                                    icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                                    label: const Text(
                                      'Chat & Buy on WhatsApp',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: marketState.products.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}