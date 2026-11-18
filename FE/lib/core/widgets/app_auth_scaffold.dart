import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'app_auth_sheet_clipper.dart';
import 'app_auth_wave_painter.dart';

class AppAuthScaffold extends StatelessWidget {
  const AppAuthScaffold(
      {required this.header,
      required this.child,
      this.isRegister = false,
      super.key});
  final Widget header;
  final Widget child;
  final bool isRegister;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.authWaveMedium,
        ),
        child: Scaffold(
          backgroundColor: AppColors.authCanvas,
          body: LayoutBuilder(builder: (context, viewport) {
            final height = MediaQuery.sizeOf(context).height;
            final heroHeight = isRegister
                ? (height * .27).clamp(AppDimens.authRegisterHeroMin,
                    AppDimens.authRegisterHeroMax)
                : (height * .46)
                    .clamp(AppDimens.authHeroMin, AppDimens.authHeroMax);
            final offset = heroHeight - AppDimens.authSheetOverlap;
            return Center(
                child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppDimens.authMaxWidth),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Stack(children: [
                  SizedBox(
                      height: heroHeight,
                      width: double.infinity,
                      child: header),
                  Padding(
                      padding: EdgeInsets.only(top: offset),
                      child: ClipPath(
                        clipper: const AppAuthSheetClipper(),
                        child: Container(
                          constraints: BoxConstraints(
                              minHeight: (viewport.maxHeight - offset)
                                  .clamp(0, double.infinity)),
                          color: AppColors.authCanvas,
                          child: Stack(children: [
                            Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: AppDimens.authFooterHeight,
                                child: const IgnorePointer(
                                    child: CustomPaint(
                                        painter: AppAuthWavePainter()))),
                            Padding(
                                padding: EdgeInsets.fromLTRB(
                                    AppDimens.spacingLg,
                                    isRegister
                                        ? AppDimens.spacingXl
                                        : AppDimens.authSheetTopPadding,
                                    AppDimens.spacingLg,
                                    (isRegister
                                            ? AppDimens.spacingXl
                                            : AppDimens.authFooterHeight) +
                                        MediaQuery.paddingOf(context).bottom),
                                child: child),
                          ]),
                        ),
                      )),
                ]),
              ),
            ));
          }),
        ),
      );
}
