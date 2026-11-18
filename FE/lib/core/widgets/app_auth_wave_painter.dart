import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppAuthWavePainter extends CustomPainter {
  const AppAuthWavePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rear = Path()
      ..moveTo(0, size.height * .2)
      ..cubicTo(size.width * .38, size.height * .25, size.width * .4,
          size.height * 1.2, size.width, size.height * .1)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(rear, Paint()..color = AppColors.authWaveLight);
    final middle = Path()
      ..moveTo(0, size.height * .55)
      ..cubicTo(size.width * .35, size.height * .1, size.width * .5,
          size.height * 1.1, size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(middle,
        Paint()..color = AppColors.authWaveMedium.withValues(alpha: .75));
    final front = Path()
      ..moveTo(0, size.height * .4)
      ..cubicTo(size.width * .18, size.height * .5, size.width * .35,
          size.height * .9, size.width * .65, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        front, Paint()..color = AppColors.authWaveDark.withValues(alpha: .8));
  }

  @override
  bool shouldRepaint(AppAuthWavePainter oldDelegate) => false;
}
