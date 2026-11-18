import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../data/models/incident_list_item_model.dart';
import 'incident_status_chip.dart';

class IncidentListCard extends StatelessWidget {
  final IncidentListItemModel incident;
  final VoidCallback onTap;
  const IncidentListCard(
      {super.key, required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child:
                        Text(incident.title, style: AppTextStyles.titleMedium)),
                IncidentStatusChip(status: incident.status),
              ]),
              const SizedBox(height: AppDimens.spacingSm),
              Text(incident.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppDimens.spacingSm),
              Row(children: [
                const Icon(Icons.schedule,
                    size: AppDimens.iconSizeSm, color: AppColors.textSecondary),
                const SizedBox(width: AppDimens.spacingXs),
                Text(DateTimeFormatter.dateTime(incident.createdAt),
                    style: AppTextStyles.bodySmall),
                const Spacer(),
                Text('${incident.reportCount} lượt báo',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primary)),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ]),
            ]),
          ),
        ),
      );
}
