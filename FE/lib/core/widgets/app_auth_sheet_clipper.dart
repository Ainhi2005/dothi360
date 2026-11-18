import 'package:flutter/material.dart';

class AppAuthSheetClipper extends CustomClipper<Path> {
  const AppAuthSheetClipper();
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 26)
    ..cubicTo(size.width * .24, -24, size.width * .61, 40, size.width, 8)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();
  @override
  bool shouldReclip(AppAuthSheetClipper oldClipper) => false;
}
