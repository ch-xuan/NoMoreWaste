import 'package:flutter/material.dart';

class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    super.key,
    required this.isLast,
    required this.onSkip,
    required this.onNext,
    required this.skipText,
    required this.nextText,
    required this.getStartedText,
  });

  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  /// Localized button labels
  final String skipText;
  final String nextText;
  final String getStartedText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: isLast ? _buildLastCTA() : _buildSkipNext(),
    );
  }

  /// Last page → ONE big centered button
  Widget _buildLastCTA() {
    return _GradientButton(
      text: getStartedText,
      onTap: onNext,
      fullWidth: true,
    );
  }

  /// Page 1 & 2 → Skip + Next
  Widget _buildSkipNext() {
    return Row(
      children: [
        GestureDetector(
          onTap: onSkip,
          child: Text(
            skipText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
        ),
        const Spacer(),
        _GradientButton(
          text: nextText,
          onTap: onNext,
          fullWidth: false,
        ),
      ],
    );
  }
}

/// Reusable orange pill button
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.text,
    required this.onTap,
    required this.fullWidth,
  });

  final String text;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF1B77E),
            Color(0xFFE39A5F),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 8),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: fullWidth ? 0 : 36,
            vertical: 16,
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
