import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../data/models/incident_detail_model.dart';
import 'incident_status_chip.dart';

class IncidentDetailSummary extends StatelessWidget {
  final IncidentDetailModel incident;
  const IncidentDetailSummary({super.key, required this.incident});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Text(incident.incidentTypeName,
                    style: AppTextStyles.headingSmall)),
            IncidentStatusChip(status: incident.status),
          ]),
          const SizedBox(height: AppDimens.spacingSm),
          Text(incident.description, style: AppTextStyles.bodyLarge),
          const SizedBox(height: AppDimens.spacingMd),
          _InfoRow(
              icon: Icons.schedule,
              text: DateTimeFormatter.dateTime(incident.createdAt)),
          const SizedBox(height: AppDimens.spacingSm),
          _InfoRow(
              icon: Icons.groups_outlined,
              text: '${incident.reportCount} người cùng phản ánh'),
          if (incident.departmentName != null) ...[
            const SizedBox(height: AppDimens.spacingSm),
            _InfoRow(
                icon: Icons.apartment_outlined, text: incident.departmentName!),
          ],
          const SizedBox(height: AppDimens.spacingMd),
          Wrap(
              spacing: AppDimens.spacingSm,
              runSpacing: AppDimens.spacingSm,
              children: [
                _MetricChip(label: 'Mức độ ${incident.severityLevel}/5'),
                if (incident.priorityScore != null)
                  _MetricChip(
                      label:
                          'Ưu tiên ${incident.priorityScore!.toStringAsFixed(0)} điểm'),
              ]),
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: AppDimens.iconSizeSm, color: AppColors.primary),
        const SizedBox(width: AppDimens.spacingSm),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ]);
}

class _MetricChip extends StatelessWidget {
  final String label;
  const _MetricChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spacingSm, vertical: AppDimens.spacingXs),
        decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
        child: Text(label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
      );
}
