import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton Loader Widget - أفضل من CircularProgressIndicator
/// يعطي تجربة مستخدم أفضل بكثير أثناء التحميل
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF374151) : Colors.grey[300]!,
      highlightColor: isDark ? const Color(0xFF4B5563) : Colors.grey[100]!,
      direction: ShimmerDirection.ltr, // من اليسار لليمين
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Skeleton Card Loader - لتحميل Cards
class SkeletonCard extends StatelessWidget {
  final double? height;
  final EdgeInsets? padding;

  const SkeletonCard({
    super.key,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.circular(25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: 150,
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (height != null) ...[
            const SizedBox(height: 16),
            SkeletonLoader(
              width: double.infinity,
              height: height,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton List Loader - لتحميل قوائم
class SkeletonListLoader extends StatelessWidget {
  final int itemCount;
  final double? itemHeight;

  const SkeletonListLoader({
    super.key,
    this.itemCount = 5,
    this.itemHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return SkeletonCard(height: itemHeight);
      },
    );
  }
}

/// Skeleton Service Card - لتحميل بطاقات الخدمات
class SkeletonServiceCard extends StatelessWidget {
  const SkeletonServiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          SkeletonLoader(
            width: double.infinity,
            height: 150,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 12),
          // Title
          SkeletonLoader(
            width: 200,
            height: 20,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          // Description
          SkeletonLoader(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(7),
          ),
          const SizedBox(height: 6),
          SkeletonLoader(
            width: 150,
            height: 14,
            borderRadius: BorderRadius.circular(7),
          ),
          const SizedBox(height: 12),
          // Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(
                width: 80,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
              SkeletonLoader(
                width: 100,
                height: 36,
                borderRadius: BorderRadius.circular(18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton Provider Card - لتحميل بطاقات العاملين
class SkeletonProviderCard extends StatelessWidget {
  const SkeletonProviderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          SkeletonLoader(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: 18,
                  borderRadius: BorderRadius.circular(9),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 120,
                  height: 14,
                  borderRadius: BorderRadius.circular(7),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SkeletonLoader(
                      width: 60,
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(width: 12),
                    SkeletonLoader(
                      width: 80,
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
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

/// Skeleton Grid Loader - لتحميل شبكات
class SkeletonGridLoader extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const SkeletonGridLoader({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return const SkeletonServiceCard();
      },
    );
  }
}

/// Skeleton Quick Services - لتحميل Quick Services PageView
class SkeletonQuickServices extends StatelessWidget {
  const SkeletonQuickServices({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background skeleton
                const SkeletonLoader(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.zero,
                ),
                // Content overlay
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SkeletonLoader(
                        width: 150,
                        height: 24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 8),
                      SkeletonLoader(
                        width: 200,
                        height: 16,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
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

/// Skeleton Available Offers - لتحميل Available Offers List
class SkeletonAvailableOffers extends StatelessWidget {
  const SkeletonAvailableOffers({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Service Image
              SkeletonLoader(
                width: 80,
                height: 80,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              // Service Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: 18,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: 150,
                      height: 14,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonLoader(
                          width: 60,
                          height: 16,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        SkeletonLoader(
                          width: 80,
                          height: 16,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton Popular Workers - لتحميل Popular Workers List
class SkeletonPopularWorkers extends StatelessWidget {
  const SkeletonPopularWorkers({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => const SkeletonProviderCard(),
      ),
    );
  }
}

/// Skeleton Screen - شاشة كاملة بـ Skeleton Loading
class SkeletonScreen extends StatelessWidget {
  final Widget? child;
  final bool showAppBar;

  const SkeletonScreen({
    super.key,
    this.child,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF5F5F5),
      appBar: showAppBar
          ? AppBar(
              backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
              elevation: 0,
              title: SkeletonLoader(
                width: 150,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SkeletonLoader(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            )
          : null,
      body: child ??
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                5,
                (index) => const SkeletonCard(height: 100),
              ),
            ),
          ),
    );
  }
}
