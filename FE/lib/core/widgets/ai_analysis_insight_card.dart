import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

/// Thẻ hiển thị đánh giá AI và biện pháp đề xuất (có khả năng mở rộng chi tiết nâng cao)
class AiAnalysisInsightCard extends StatefulWidget {
  const AiAnalysisInsightCard({
    super.key,
    required this.aiAnalysis,
    this.title = 'Đánh giá AI & Biện pháp đề xuất',
    this.isOfficer = false,
    this.onActionCopied,
  });

  final Map<String, dynamic> aiAnalysis;
  final String title;
  final bool isOfficer;
  final VoidCallback? onActionCopied;

  @override
  State<AiAnalysisInsightCard> createState() => _AiAnalysisInsightCardState();
}

class _AiAnalysisInsightCardState extends State<AiAnalysisInsightCard> {
  bool _isExpanded = false;

  String _translateRisk(String rawRisk) {
    switch (rawRisk.toUpperCase()) {
      case 'EMERGENCY':
        return 'Khẩn cấp';
      case 'HIGH':
        return 'Mức độ cao';
      case 'MEDIUM':
        return 'Mức độ trung bình';
      case 'LOW':
        return 'Mức độ thấp';
      default:
        return 'Chưa xác định';
    }
  }

  Color _riskColor(String rawRisk) {
    switch (rawRisk.toUpperCase()) {
      case 'EMERGENCY':
        return AppColors.error;
      case 'HIGH':
        return Colors.deepOrange;
      case 'MEDIUM':
        return AppColors.warning;
      case 'LOW':
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiAnalysis = widget.aiAnalysis;
    final reason = aiAnalysis['reason']?.toString() ?? '';
    final rawRisk = aiAnalysis['risk_level']?.toString() ?? 'MEDIUM';
    final recommendedAction =
        aiAnalysis['recommended_action']?.toString() ?? '';
    final signals =
        List<String>.from(aiAnalysis['detected_signals'] ?? const []);
    final slaHours = aiAnalysis['suggested_sla_hours']?.toString();
    final suggestedType = aiAnalysis['suggested_incident_type']?.toString();

    final translatedRisk = _translateRisk(rawRisk);
    final riskColor = _riskColor(rawRisk);

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      backgroundColor: AppColors.primaryLight,
      borderColor: AppColors.primary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header gọn gàng
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: AppDimens.iconSizeBase,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimens.spacingSm),
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingSm,
                  vertical: AppDimens.spacing2Xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'Gợi ý tham khảo',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSm),

          // 2. Tóm tắt AI ngắn (tối đa 3 dòng)
          if (reason.isNotEmpty) ...[
            Text(
              reason.trim(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimens.spacingSm),
          ],

          // 3. Biện pháp xử lý đề xuất nổi bật
          if (recommendedAction.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.spacingSm + 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: AppDimens.iconSizeSm,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimens.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biện pháp xử lý đề xuất:',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recommendedAction.trim(),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.spacingSm),
          ],

          // 4. Chi tiết nâng cao có thể mở rộng (Collapsible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppDimens.radiusXs),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded
                        ? 'Thu gọn chi tiết phân tích'
                        : 'Xem thêm chi tiết phân tích AI',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const SizedBox(height: AppDimens.spacingSm),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppDimens.spacingSm),
            Wrap(
              spacing: AppDimens.spacingSm,
              runSpacing: AppDimens.spacingXs,
              children: [
                _buildInfoPill(
                  icon: Icons.shield_outlined,
                  label: 'Rủi ro: $translatedRisk',
                  color: riskColor,
                ),
                if (slaHours != null)
                  _buildInfoPill(
                    icon: Icons.timer_outlined,
                    label: 'SLA đề xuất: $slaHours giờ',
                    color: AppColors.textSecondary,
                  ),
                if (suggestedType != null)
                  _buildInfoPill(
                    icon: Icons.category_outlined,
                    label: 'Nhận diện: $suggestedType',
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
            if (signals.isNotEmpty) ...[
              const SizedBox(height: AppDimens.spacingSm),
              Text(
                'Dấu hiệu nhận diện: ${signals.join(', ')}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingSm,
        vertical: AppDimens.spacing2Xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusXs),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
