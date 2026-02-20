import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────
//  Shimmer base colour helper
// ─────────────────────────────────────────────
Color _base(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return dark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8E8);
}

Color _highlight(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return dark ? const Color(0xFF3A3A3C) : const Color(0xFFF5F5F5);
}

// ─────────────────────────────────────────────
//  Primitive skeleton block
// ─────────────────────────────────────────────
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _base(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _base(context),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Shimmer wrapper
// ─────────────────────────────────────────────
class ShimmerWrapper extends StatelessWidget {
  final Widget child;

  const ShimmerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base(context),
      highlightColor: _highlight(context),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
//  Marketplace Grid Skeleton  (2-col grid card)
// ─────────────────────────────────────────────
class MarketplaceGridSkeleton extends StatelessWidget {
  const MarketplaceGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => _AppCardSkeleton(),
      ),
    );
  }
}

class _AppCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bg = _base(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _highlight(context),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          // App name
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: _highlight(context),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: _highlight(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Container(
            width: 70,
            height: 11,
            decoration: BoxDecoration(
              color: _highlight(context),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          // Button placeholder
          Container(
            width: double.infinity,
            height: 36,
            decoration: BoxDecoration(
              color: _highlight(context),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  My Tests list skeleton  (card-style row)
// ─────────────────────────────────────────────
class TestListSkeleton extends StatelessWidget {
  final int itemCount;
  const TestListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, _) => _TestCardSkeleton(),
      ),
    );
  }
}

class _TestCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bg = _base(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _highlight(context),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 15,
                      decoration: BoxDecoration(
                        color: _highlight(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 11,
                      decoration: BoxDecoration(
                        color: _highlight(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  color: _highlight(context),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: _highlight(context),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 20),
          // Button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: _highlight(context),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Profile screen skeleton
// ─────────────────────────────────────────────
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = _base(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ShimmerWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar circle
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Container(
                width: 160,
                height: 24,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              // Email
              Container(
                width: 200,
                height: 14,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 32),
              // Karma card
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 24),
              // Menu items
              for (int i = 0; i < 5; i++) ...[
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Wallet / Transaction list skeleton
// ─────────────────────────────────────────────
class WalletTransactionSkeleton extends StatelessWidget {
  const WalletTransactionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, _) => ShimmerWrapper(child: _TransactionRowSkeleton()),
        childCount: 6,
      ),
    );
  }
}

class _TransactionRowSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bg = _base(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _highlight(context),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 13,
                  decoration: BoxDecoration(
                    color: _highlight(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 100,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  My Apps list skeleton
// ─────────────────────────────────────────────
class MyAppsListSkeleton extends StatelessWidget {
  const MyAppsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, _) => _MyAppCardSkeleton(),
      ),
    );
  }
}

class _MyAppCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bg = _base(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 140,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Admin Stats Grid skeleton
// ─────────────────────────────────────────────
class AdminStatsSkeleton extends StatelessWidget {
  const AdminStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = _base(context);
    return ShimmerWrapper(
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: List.generate(
          4,
          (_) => Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Generic list skeleton (admin users / apps)
// ─────────────────────────────────────────────
class GenericListSkeleton extends StatelessWidget {
  final int itemCount;
  const GenericListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => _GenericRowSkeleton(),
      ),
    );
  }
}

class _GenericRowSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bg = _base(context);
    return Container(
      height: 72,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: 120,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Image placeholder skeleton (replaces spinner
//  inside CachedNetworkImage placeholder)
// ─────────────────────────────────────────────
class ImageSkeleton extends StatelessWidget {
  final double size;
  final double borderRadius;
  final Color? baseColor;

  const ImageSkeleton({
    super.key,
    required this.size,
    this.borderRadius = 12,
    this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = baseColor ?? _base(context);
    return Shimmer.fromColors(
      baseColor: bg,
      highlightColor: _highlight(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class CircularImageSkeleton extends StatelessWidget {
  final double size;

  const CircularImageSkeleton({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final bg = _base(context);
    return Shimmer.fromColors(
      baseColor: bg,
      highlightColor: _highlight(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
