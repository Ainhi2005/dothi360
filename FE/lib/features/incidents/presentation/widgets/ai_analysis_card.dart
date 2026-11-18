import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import 'editable_ai_summary.dart';

/// Thẻ trình bày kết quả AI phân tích và cho phép người dân xác nhận/chỉnh sửa
class AiAnalysisCard extends StatelessWidget {
  const AiAnalysisCard({
    super.key,
    required this.analysis,
    required this.incidentTypes,
    required this.selectedTypeId,
    required this.onTypeChanged,
    required this.onSeverityChanged,
    this.onReasonChanged,
    this.onRecommendationChanged,
    this.isConfirmed = false,
    this.onConfirm,
    this.isRetrying = false,
    this.onRetry,
  });

  final Map<String, dynamic>? analysis;
  final List<Map<String, dynamic>> incidentTypes;
  final String? selectedTypeId;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<int> onSeverityChanged;
  final ValueChanged<String>? onReasonChanged;
  final ValueChanged<String>? onRecommendationChanged;
  final bool isConfirmed;
  final VoidCallback? onConfirm;
  final bool isRetrying;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isManualFallback = analysis?['analysis_status'] == 'MANUAL_FALLBACK';
    final analysisFailed = analysis?['analysis_status'] == 'FAILED' ||
        analysis?['telemetry']?['error'] == true;
    final confidence = ((analysis?['confidence'] as num?)?.toDouble() ?? 0.0);
    final severity = (analysis?['confirmed_severity'] as num?)?.toInt() ?? 2;
    final suggestedSeverity =
        (analysis?['suggested_severity'] as num?)?.toInt() ?? severity;
    final suggestedType =
        analysis?['suggested_incident_type']?.toString() ?? 'Chưa xác định';

    // Tóm tắt AI súc tích (tối đa 3 dòng)
    final rawReason = analysis?['reason']?.toString() ?? '';
    final reasonText = rawReason.trim().isNotEmpty
        ? rawReason.trim()
        : 'AI đã nhận diện đặc điểm sự cố từ hình ảnh hiện trường và vị trí bạn cung cấp.';

    // Chỉ hiển thị nút phân tích lại khi thất bại hoặc độ tin cậy thấp (< 60%)
    final shouldShowRetry =
        (analysisFailed || (confidence < 0.6 && !isManualFallback)) &&
            onRetry != null;

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      backgroundColor:
          isManualFallback ? AppColors.surface : AppColors.primaryLight,
      borderColor: isManualFallback
          ? AppColors.border
          : AppColors.primary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: AI hiểu thế nào & Độ tin cậy
          Row(
            children: [
              Icon(
                isManualFallback
                    ? Icons.assignment_turned_in_outlined
                    : Icons.auto_awesome_rounded,
                color: isManualFallback
                    ? AppColors.textPrimary
                    : AppColors.primary,
                size: AppDimens.iconSizeMd,
              ),
              const SizedBox(width: AppDimens.spacingSm),
              Expanded(
                child: Text(
                  isManualFallback
                      ? 'Xác nhận phân loại thủ công'
                      : 'AI hiểu phản ánh của bạn',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isManualFallback) _buildConfidenceBadge(confidence),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSm),

          // 2. Tóm tắt AI ngắn gọn (Tối đa 3 dòng)
          if (!isManualFallback) ...[
            if (onReasonChanged != null)
              EditableAiSummary(
                value: reasonText,
                onSaved: onReasonChanged!,
              )
            else
              Text(reasonText, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppDimens.spacingSm),
          ],

          // Câu khẩu hiệu định hướng: "AI gợi ý, bạn là người xác nhận cuối cùng"
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingSm + 2,
              vertical: AppDimens.spacing2Xs + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusXs),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isManualFallback
                        ? 'Bạn trực tiếp chọn loại và mức độ phù hợp với hiện trường.'
                        : 'AI gợi ý, bạn là người xác nhận cuối cùng.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spacingMd),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppDimens.spacingMd),

          // 3. Loại sự cố và Mức độ AI đề xuất
          if (!isManualFallback) ...[
            _buildAiSuggestionSummary(suggestedType, suggestedSeverity),
            const SizedBox(height: AppDimens.spacingMd),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppDimens.spacingMd),
          ],

          // 4. Những trường người dân thực sự cần xác nhận / chỉnh sửa
          Text(
            'Thông tin bạn xác nhận:',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingSm),

          // Trường A: Loại sự cố xác nhận
          DropdownButtonFormField<String>(
            key: ValueKey(selectedTypeId),
            initialValue: selectedTypeId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Loại sự cố',
              labelStyle: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.category_outlined,
                size: AppDimens.iconSizeSm,
                color: AppColors.textSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingMd,
                vertical: AppDimens.spacingSm + 2,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            items: incidentTypes
                .map((item) => DropdownMenuItem(
                      value: item['id']?.toString(),
                      child: Text(
                        item['name']?.toString() ?? 'Khác',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ))
                .toList(),
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: AppDimens.spacingMd),

          // Trường B: Mức độ nghiêm trọng bạn xác nhận (1 đến 5)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Mức độ nghiêm trọng: ',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  _getSeverityDescription(severity),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: _getSeverityColor(severity),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingXs + 2),
          Wrap(
            spacing: AppDimens.spacingSm,
            runSpacing: AppDimens.spacing2Xs,
            children: List.generate(5, (index) {
              final level = index + 1;
              final isSelected = severity == level;
              return ChoiceChip(
                label: Text('Mức $level'),
                selected: isSelected,
                selectedColor: _getSeverityColor(level).withValues(alpha: 0.18),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color:
                      isSelected ? _getSeverityColor(level) : AppColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
                labelStyle: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? _getSeverityColor(level)
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (_) => onSeverityChanged(level),
              );
            }),
          ),

          // 5. Nút phân tích lại (Chỉ xuất hiện khi thất bại hoặc độ tin cậy thấp)
          if (shouldShowRetry) ...[
            const SizedBox(height: AppDimens.spacingMd),
            Center(
              child: OutlinedButton.icon(
                onPressed: isRetrying ? null : onRetry,
                icon: isRetrying
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  isRetrying
                      ? 'Đang phân tích lại...'
                      : 'Phân tích lại bằng AI',
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final isHigh = confidence >= 0.7;
    final percent = (confidence * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingSm,
        vertical: AppDimens.spacing2Xs,
      ),
      decoration: BoxDecoration(
        color: isHigh ? AppColors.successLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        border: Border.all(
          color: isHigh
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        isHigh ? 'Độ tin cậy $percent%' : 'Cần kiểm tra kỹ',
        style: AppTextStyles.caption.copyWith(
          color: isHigh ? AppColors.success : AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAiSuggestionSummary(String type, int severity) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingSm + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI đề xuất loại sự cố:',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: AppColors.divider,
            margin: const EdgeInsets.symmetric(horizontal: AppDimens.spacingSm),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI đề xuất mức độ:',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mức $severity (${_getSeverityLabel(severity)})',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _getSeverityColor(severity),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _getSeverityLabel(int level) {
    switch (level) {
      case 1:
        return 'Rất nhẹ';
      case 2:
        return 'Ít nghiêm trọng';
      case 3:
        return 'Trung bình';
      case 4:
        return 'Nghiêm trọng';
      case 5:
        return 'Khẩn cấp';
      default:
        return 'Bình thường';
    }
  }

  static String _getSeverityDescription(int level) {
    switch (level) {
      case 1:
        return 'Mức 1 - Rất nhẹ (theo dõi thêm)';
      case 2:
        return 'Mức 2 - Ít nghiêm trọng (ảnh hưởng nhỏ)';
      case 3:
        return 'Mức 3 - Trung bình (cản trở cục bộ)';
      case 4:
        return 'Mức 4 - Nghiêm trọng (nguy cơ mất an toàn)';
      case 5:
        return 'Mức 5 - Khẩn cấp (nguy hiểm tức thì)';
      default:
        return 'Mức $level';
    }
  }

  static Color _getSeverityColor(int level) {
    switch (level) {
      case 1:
        return AppColors.success;
      case 2:
        return Colors.blue;
      case 3:
        return AppColors.warning;
      case 4:
        return Colors.deepOrange;
      case 5:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}
