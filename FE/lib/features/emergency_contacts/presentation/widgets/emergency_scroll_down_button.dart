import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EmergencyScrollDownButton extends StatelessWidget {
  const EmergencyScrollDownButton({
    super.key,
    required this.onPressed,
    this.visible = true,
  });

  final VoidCallback onPressed;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Center(
      child: Material(
        color: AppColors.textPrimary,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              Icons.arrow_downward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
