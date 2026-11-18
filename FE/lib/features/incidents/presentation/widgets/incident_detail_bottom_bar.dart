import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Thanh hành động đồng phản ánh (+1) cho cộng đồng
class IncidentDetailBottomBar extends StatefulWidget {
  final int reportCount;
  final VoidCallback onEndorse;

  const IncidentDetailBottomBar({
    super.key,
    required this.reportCount,
    required this.onEndorse,
  });

  @override
  State<IncidentDetailBottomBar> createState() =>
      _IncidentDetailBottomBarState();
}

class _IncidentDetailBottomBarState extends State<IncidentDetailBottomBar> {
  bool _hasEndorsed = false;
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.reportCount;
  }

  @override
  void didUpdateWidget(covariant IncidentDetailBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportCount != widget.reportCount) {
      setState(() {
        _count = widget.reportCount;
      });
    }
  }

  void _handleTap() {
    if (_hasEndorsed) return;
    setState(() {
      _hasEndorsed = true;
      _count++;
    });
    widget.onEndorse();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingMd,
        vertical: AppDimens.spacingSm + 4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: AppDimens.buttonHeight,
          child: ElevatedButton(
            onPressed: _handleTap,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _hasEndorsed ? AppColors.surface : AppColors.primary,
              foregroundColor: _hasEndorsed ? AppColors.primary : Colors.white,
              elevation: 0,
              side: _hasEndorsed
                  ? const BorderSide(color: AppColors.primary)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingMd,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _hasEndorsed
                      ? Icons.check_circle_rounded
                      : Icons.thumb_up_alt_outlined,
                  color: _hasEndorsed ? AppColors.primary : Colors.white,
                  size: AppDimens.iconSizeSm,
                ),
                const SizedBox(width: AppDimens.spacingSm),
                Flexible(
                  child: Text(
                    _hasEndorsed
                        ? 'Bạn đã đồng phản ánh sự cố này'
                        : 'Tôi cũng gặp sự cố này (+1)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.buttonText.copyWith(
                      color: _hasEndorsed ? AppColors.primary : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _hasEndorsed
                        ? AppColors.primaryLight
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    '$_count',
                    style: TextStyle(
                      color: _hasEndorsed ? AppColors.primary : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
