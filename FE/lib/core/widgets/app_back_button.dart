import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackButton extends StatelessWidget {
  final String fallbackPath;
  final VoidCallback? onPressed;

  const AppBackButton({
    super.key,
    this.fallbackPath = '/',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else if (Navigator.canPop(context)) {
          context.pop();
        } else {
          context.go(fallbackPath);
        }
      },
    );
  }
}
