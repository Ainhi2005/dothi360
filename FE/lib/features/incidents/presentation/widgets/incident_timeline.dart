import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../data/models/incident_detail_model.dart';
import '../../../../core/constants/incident_status.dart';

class IncidentTimeline extends StatelessWidget {
  final IncidentDetailModel incident;
  const IncidentTimeline({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    final events = <IncidentUpdateModel>[
      IncidentUpdateModel(
          status: IncidentStatus.pendingAssignment,
          note: 'Phản ánh đã được hệ thống ghi nhận.',
          createdAt: incident.createdAt),
      ...incident.updates,
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Lịch sử xử lý', style: AppTextStyles.titleMedium),
      const SizedBox(height: AppDimens.spacingMd),
      ...List.generate(
          events.length,
          (index) => _TimelineItem(
              event: events[index], isLast: index == events.length - 1)),
    ]);
  }
}

class _TimelineItem extends StatelessWidget {
  final IncidentUpdateModel event;
  final bool isLast;
  const _TimelineItem({required this.event, required this.isLast});

  String get _label => event.status == null
      ? 'Cập nhật xử lý'
      : event.status == IncidentStatus.pendingAssignment
          ? 'Đã ghi nhận'
          : IncidentStatus.label(event.status!);

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            const Icon(Icons.check_circle,
                color: AppColors.primary, size: AppDimens.iconSizeMd),
            if (!isLast)
              Expanded(child: Container(width: 2, color: AppColors.divider)),
          ]),
          const SizedBox(width: AppDimens.spacingMd),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.spacingLg),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label,
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppDimens.spacingXs),
                    Text(DateTimeFormatter.dateTime(event.createdAt),
                        style: AppTextStyles.bodySmall),
                    if (event.note?.isNotEmpty == true) ...[
                      const SizedBox(height: AppDimens.spacingXs),
                      Text(event.note!, style: AppTextStyles.bodyMedium),
                    ],
                    if (event.mediaUrls.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.spacingSm),
                      Row(
                        children: [
                          const Icon(Icons.photo_library_outlined,
                              size: AppDimens.iconSizeSm,
                              color: AppColors.primary),
                          const SizedBox(width: AppDimens.spacingXs),
                          Text(
                            'Ảnh cập nhật từ cán bộ (${event.mediaUrls.length}):',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.spacingSm),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: event.mediaUrls.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppDimens.spacingSm),
                          itemBuilder: (context, i) {
                            final url = event.mediaUrls[i];
                            return GestureDetector(
                              onTap: () => _showImageDialog(context, url),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusSm),
                                child: AppCachedImage(
                                  imageUrl: url,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 160,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ]),
            ),
          ),
        ]),
      );

  void _showImageDialog(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppDimens.spacingMd),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: AppCachedImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  memCacheWidth: 1024,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
