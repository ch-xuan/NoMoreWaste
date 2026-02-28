import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  final String imagePath;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Available height for this page inside PageView
        final h = constraints.maxHeight;

        // Responsive sizing (prevents overflow on small heights)
        final imageH = (h * 0.32).clamp(140.0, 240.0);
        final topGap = (h * 0.06).clamp(10.0, 28.0);
        final midGap = (h * 0.04).clamp(10.0, 20.0);
        final textGap = (h * 0.03).clamp(8.0, 14.0);

        // Use SingleChildScrollView as a safety net ONLY when height is too small.
        // This avoids yellow overflow stripes on extreme window sizes.
        final needsScroll = h < 520;

        final content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: topGap),

            // Image scales with screen height
            Image.asset(
              imagePath,
              height: imageH,
              fit: BoxFit.contain,
            ),

            SizedBox(height: midGap),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F2A3F),
                ),
              ),
            ),

            SizedBox(height: textGap),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.4,
                  color: Colors.black.withOpacity(0.75),
                ),
              ),
            ),

            SizedBox(height: topGap),
          ],
        );

        if (!needsScroll) return content;

        // Fallback for small windows (e.g., Windows narrow height):
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: h),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}
