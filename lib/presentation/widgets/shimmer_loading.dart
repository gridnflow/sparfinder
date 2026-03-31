import 'package:flutter/material.dart';

/// A shimmer effect widget that animates a gradient across its child.
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFEBEBF4),
                Color(0xFFF4F4F4),
                Color(0xFFEBEBF4),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single shimmer bone (rectangle placeholder).
class ShimmerBone extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBone({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton that mimics an OfferCard layout.
class OfferCardSkeleton extends StatelessWidget {
  const OfferCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            const ShimmerBone(height: 130, borderRadius: 0),
            // Info area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBone(width: 80, height: 12),
                    const SizedBox(height: 6),
                    const ShimmerBone(height: 14),
                    const SizedBox(height: 4),
                    const ShimmerBone(width: 60, height: 10),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const ShimmerBone(width: 50, height: 18),
                        ShimmerBone(
                            width: 20, height: 20, borderRadius: 10),
                      ],
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

/// A row of two skeleton cards, matching _CardRow layout.
class SkeletonCardRow extends StatelessWidget {
  const SkeletonCardRow({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 8) / 2;
        final cardHeight = cardWidth / 0.57;
        return SizedBox(
          height: cardHeight,
          child: Row(
            children: [
              SizedBox(width: cardWidth, child: const OfferCardSkeleton()),
              const SizedBox(width: 8),
              SizedBox(width: cardWidth, child: const OfferCardSkeleton()),
            ],
          ),
        );
      },
    );
  }
}

/// Grid of skeleton card rows for home screen loading state.
class HomeLoadingSkeleton extends StatelessWidget {
  final int rowCount;

  const HomeLoadingSkeleton({super.key, this.rowCount = 4});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: SkeletonCardRow(),
          ),
          childCount: rowCount,
        ),
      ),
    );
  }
}

/// Skeleton for search results (price comparison rows).
class SearchLoadingSkeleton extends StatelessWidget {
  final int itemCount;

  const SearchLoadingSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary banner skeleton
            const ShimmerBone(height: 80, borderRadius: 16),
            const SizedBox(height: 16),
            const ShimmerBone(width: 200, height: 14),
            const SizedBox(height: 12),
            // Price comparison row skeletons
            ...List.generate(
              itemCount,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: const Row(
                    children: [
                      ShimmerBone(width: 28, height: 28, borderRadius: 14),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBone(width: 120, height: 14),
                            SizedBox(height: 4),
                            ShimmerBone(width: 80, height: 12),
                          ],
                        ),
                      ),
                      ShimmerBone(width: 60, height: 20),
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
}
