import 'package:flutter/material.dart';

/// A single item in [AminaBottomNav].
class AminaNavItem {
  final IconData icon; // shown when inactive (outline/linear)
  final IconData activeIcon; // shown inside the raised bubble when active
  final String label;
  final VoidCallback onTap;
  final int badge;
  final Widget? customChild; // optional custom widget (e.g. profile avatar)

  const AminaNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.badge = 0,
    this.customChild,
  });
}

/// Bottom navigation styled after the Figma "BNB-27" component:
/// a white bar with rounded top corners and a concave notch under the
/// active item, whose icon floats in a raised white circular bubble.
class AminaBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<AminaNavItem> items;
  final Color activeColor;
  final Color inactiveColor;

  const AminaBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    this.activeColor = const Color(0xFF8B5CF6),
    this.inactiveColor = const Color(0xFF9DB2CE),
  });

  static const double _barHeight = 66;
  static const double _overhang = 22; // bubble rise above the bar
  static const double _bubble = 52;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bottomInset = MediaQuery.of(context).padding.bottom;
          final n = items.length;
          final slot = width / n;
          final activeCenterX = slot * currentIndex + slot / 2;
          final totalHeight = _barHeight + _overhang + bottomInset;

          return SizedBox(
            height: totalHeight,
            width: width,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // White bar with rounded corners + concave notch + shadow.
                // Extends to the very bottom edge (behind the home indicator).
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: PhysicalShape(
                    clipper: _NavBarClipper(
                      notchCenterX: activeCenterX,
                      notchRadius: 34,
                      cornerRadius: 26,
                    ),
                    color: Colors.white,
                    elevation: 12,
                    shadowColor: Colors.black.withOpacity(0.12),
                    child: SizedBox(
                        height: _barHeight + bottomInset, width: double.infinity),
                  ),
                ),

                // Icons + labels row (sits above the home indicator inset)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: bottomInset,
                  height: _barHeight,
                  child: Row(
                    children: List.generate(n, (i) {
                      final item = items[i];
                      final active = i == currentIndex;
                      return Expanded(
                        child: InkWell(
                          onTap: item.onTap,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // For the active item the icon lives in the
                                // floating bubble, so keep an empty slot here.
                                active
                                    ? const SizedBox(height: 24)
                                    : item.customChild ?? _iconWithBadge(item, inactiveColor),
                                const SizedBox(height: 5),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        active ? FontWeight.w600 : FontWeight.w400,
                                    color: active ? activeColor : inactiveColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Raised bubble for the active item
                Positioned(
                  left: activeCenterX - _bubble / 2,
                  top: 0,
                  child: GestureDetector(
                    onTap: items[currentIndex].onTap,
                    child: Container(
                      width: _bubble,
                      height: _bubble,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        items[currentIndex].activeIcon,
                        size: 24,
                        color: activeColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
  }

  Widget _iconWithBadge(AminaNavItem item, Color color) {
    if (item.badge <= 0) {
      return Icon(item.icon, size: 24, color: color);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(item.icon, size: 24, color: color),
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            padding: const EdgeInsets.all(3),
            constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: Text(
              item.badge > 9 ? '9+' : item.badge.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Clips the nav bar into a rounded-top rectangle with a smooth concave
/// notch centered under the active item.
class _NavBarClipper extends CustomClipper<Path> {
  final double notchCenterX;
  final double notchRadius;
  final double cornerRadius;

  _NavBarClipper({
    required this.notchCenterX,
    required this.notchRadius,
    required this.cornerRadius,
  });

  @override
  Path getClip(Size size) {
    final r = notchRadius;
    final cx = notchCenterX;
    final path = Path();

    path.moveTo(cornerRadius, 0);

    // approach the notch
    path.lineTo(cx - r - 6, 0);
    // dip down into a smooth concave curve
    path.cubicTo(cx - r + 8, 0, cx - r + 6, r, cx, r);
    path.cubicTo(cx + r - 6, r, cx + r - 8, 0, cx + r + 6, 0);

    // top-right corner
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // right, bottom, left edges
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, cornerRadius);

    // top-left corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_NavBarClipper old) =>
      old.notchCenterX != notchCenterX ||
      old.notchRadius != notchRadius ||
      old.cornerRadius != cornerRadius;
}
