import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class MapStatusLegend extends StatefulWidget {
  const MapStatusLegend({super.key});

  @override
  State<MapStatusLegend> createState() => _MapStatusLegendState();
}

class _MapStatusLegendState extends State<MapStatusLegend> {
  bool _isExpanded = false;

  static const _items = [
    (AppColors.mapPending, Icons.schedule_rounded, 'Chờ phân công'),
    (AppColors.mapAssigned, Icons.person_pin_circle_outlined, 'Đã tiếp nhận'),
    (AppColors.mapInProgress, Icons.construction_rounded, 'Đang xử lý'),
    (AppColors.mapVerification, Icons.fact_check_outlined, 'Chờ nghiệm thu'),
    (AppColors.mapResolved, Icons.check_rounded, 'Hoàn thành'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: _isExpanded ? 4 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(
        _isExpanded ? AppDimens.radiusMd : AppDimens.radiusFull,
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(
          _isExpanded ? AppDimens.radiusMd : AppDimens.radiusFull,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topLeft,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal:
                  _isExpanded ? AppDimens.spacingBase : AppDimens.spacingSm + 2,
              vertical:
                  _isExpanded ? AppDimens.spacingSm : AppDimens.spacingXs + 1,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                _isExpanded ? AppDimens.radiusMd : AppDimens.radiusFull,
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: _isExpanded ? _expandedContent() : _collapsedContent(),
          ),
        ),
      ),
    );
  }

  Widget _collapsedContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.layers_outlined,
            size: 14, color: AppColors.textPrimary),
        const SizedBox(width: AppDimens.spacingXs),
        Text(
          'Chú giải',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _expandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ký hiệu bản đồ',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppDimens.spacingMd),
            const Icon(Icons.close_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
        const SizedBox(height: AppDimens.spacingSm),
        ..._items.map(
          (item) => _LegendItem(color: item.$1, icon: item.$2, label: item.$3),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(
      {required this.color, required this.icon, required this.label});

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spacing2Xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 11, color: AppColors.surface),
          ),
          const SizedBox(width: AppDimens.spacingSm),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

