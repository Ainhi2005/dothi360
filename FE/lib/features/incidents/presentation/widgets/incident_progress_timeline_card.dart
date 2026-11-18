import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../data/models/incident_detail_model.dart';

/// Thẻ dòng thời gian tiến độ xử lý sự cố (Khối quan trọng nhất)
class IncidentProgressTimelineCard extends StatelessWidget {
  final IncidentDetailModel incident;
  final String formattedCode;

  const IncidentProgressTimelineCard({
    super.key,
    required this.incident,
    required this.formattedCode,
  });

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: AppCachedImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              memCacheWidth: 1024,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updates = incident.updates;
    final hasDepartment =
        incident.departmentName != null && incident.departmentName!.isNotEmpty;
    final isResolved = incident.status == 'RESOLVED';

    final rawItems = <_TimelineItemData>[];

    // 1. Mốc tạo phản ánh ban đầu
    rawItems.add(
      _TimelineItemData(
        title: 'Hệ thống tiếp nhận phản ánh',
        time: DateTimeFormatter.dateTime(incident.createdAt),
        description: 'Phản ánh được ghi nhận với mã hồ sơ $formattedCode.',
        timestamp: incident.createdAt,
        sortPriority: 0,
      ),
    );

    // 2. Đơn vị chuyên trách tiếp nhận (nếu có đơn vị và chưa có log phân công trong updates)
    final hasAssignedUpdate = updates.any((u) => u.status == 'ASSIGNED');
    if (hasDepartment && !hasAssignedUpdate) {
      rawItems.add(
        _TimelineItemData(
          title: 'Đơn vị chuyên trách tiếp nhận',
          time: DateTimeFormatter.dateTime(incident.createdAt),
          description:
              'Phản ánh đã được chuyển giao cho ${incident.departmentName} để điều phối lực lượng.',
          timestamp: incident.createdAt.add(const Duration(seconds: 1)),
          sortPriority: 1,
        ),
      );
    }

    // 3. Các cập nhật thực tế từ đội ngũ xử lý hiện trường
    for (final u in updates) {
      if (u.status == 'RESOLVED') continue; // Đã gộp vào khối nghiệm thu hoàn thành
      rawItems.add(
        _TimelineItemData(
          title: _mapUpdateStatusTitle(u.status),
          time: DateTimeFormatter.dateTime(u.createdAt),
          description: [
            if (u.note?.isNotEmpty == true) u.note!,
            if (u.progressPercent != null)
              'Tiến độ hoàn thành: ${u.progressPercent}%',
            if (u.blocker?.isNotEmpty == true) 'Lưu ý: ${u.blocker}',
          ].join('\n'),
          mediaUrl: u.mediaUrls.isNotEmpty ? u.mediaUrls.first : null,
          timestamp: u.createdAt,
          sortPriority: u.status == 'ASSIGNED' ? 1 : 2,
        ),
      );
    }

    // 4. Nếu đã hoàn thành
    if (isResolved) {
      final resolvedTime = incident.resolvedAt ?? DateTime.now();
      final note = incident.verificationNote?.trim();
      final desc = note != null && note.isNotEmpty
          ? 'Ý kiến nghiệm thu: $note'
          : 'Sự cố đã được khắc phục hoàn toàn theo tiêu chuẩn an toàn đô thị.';
      rawItems.add(
        _TimelineItemData(
          title: 'Đã hoàn thành & Nghiệm thu',
          time: DateTimeFormatter.dateTime(resolvedTime),
          description: desc,
          timestamp: resolvedTime,
          sortPriority: 3,
        ),
      );
    }

    // Sắp xếp dòng thời gian từ mới nhất đến cũ nhất (DESCENDING)
    rawItems.sort((a, b) {
      final cmp = b.timestamp.compareTo(a.timestamp);
      if (cmp != 0) return cmp;
      return b.sortPriority.compareTo(a.sortPriority);
    });

    // Mốc mới nhất ở trên cùng là active (nếu chưa hoàn thành), các mốc trước đó là completed
    final timelineItems = <_TimelineItemData>[];
    for (int i = 0; i < rawItems.length; i++) {
      final isTop = i == 0;
      timelineItems.add(
        rawItems[i].copyWith(
          isActive: isTop && !isResolved,
          isCompleted: !isTop || isResolved,
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timeline_rounded,
                    size: AppDimens.iconSizeBase,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimens.spacingSm),
                  Text(
                    'Tiến độ xử lý hiện trường',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingSm,
                  vertical: AppDimens.spacing2Xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
                child: Text(
                  'Thời gian thực',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingMd),

          // Danh sách các mốc timeline
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: timelineItems.length,
            itemBuilder: (context, index) {
              final item = timelineItems[index];
              final isLast = index == timelineItems.length - 1;
              return _buildTimelineRow(context, item, isLast);
            },
          ),
        ],
      ),
    );
  }

  String _mapUpdateStatusTitle(String? status) {
    switch (status) {
      case 'RESOLVED':
        return 'Đã hoàn thành hiện trường';
      case 'PENDING_VERIFICATION':
        return 'Chờ nghiệm thu kết quả';
      case 'IN_PROGRESS':
        return 'Đang triển khai khắc phục';
      case 'ASSIGNED':
        return 'Đã tiếp nhận nhiệm vụ';
      default:
        return 'Cập nhật tiến độ mới';
    }
  }

  Widget _buildTimelineRow(
    BuildContext context,
    _TimelineItemData item,
    bool isLast,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột icon & đường nối
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: item.isActive
                        ? AppColors.primaryLight
                        : (item.isCompleted
                            ? AppColors.primary
                            : AppColors.background),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.isActive
                          ? AppColors.primary
                          : (item.isCompleted
                              ? AppColors.primary
                              : AppColors.border),
                      width: item.isActive ? 2.0 : 1.0,
                    ),
                  ),
                  child: item.isActive
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : (item.isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Colors.white,
                            )
                          : null),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.0,
                      margin: const EdgeInsets.symmetric(vertical: 2.0),
                      color: item.isCompleted
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.spacingSm + 4),

          // Cột nội dung
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppDimens.spacingMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: item.isActive
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        item.time,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: item.isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (item.mediaUrl != null) ...[
                    const SizedBox(height: AppDimens.spacingSm),
                    GestureDetector(
                      onTap: () => _showImageDialog(context, item.mediaUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        child: Stack(
                          children: [
                            AppCachedImage(
                              imageUrl: item.mediaUrl!,
                              width: 110,
                              height: 72,
                              fit: BoxFit.cover,
                              memCacheWidth: 220,
                            ),
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusXs),
                                ),
                                child: Text(
                                  'Ảnh hiện trường',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItemData {
  final String title;
  final String time;
  final String description;
  final String? mediaUrl;
  final bool isCompleted;
  final bool isActive;
  final DateTime timestamp;
  final int sortPriority;

  const _TimelineItemData({
    required this.title,
    required this.time,
    required this.description,
    required this.timestamp,
    this.sortPriority = 0,
    this.mediaUrl,
    this.isCompleted = false,
    this.isActive = false,
  });

  _TimelineItemData copyWith({
    bool? isCompleted,
    bool? isActive,
  }) {
    return _TimelineItemData(
      title: title,
      time: time,
      description: description,
      timestamp: timestamp,
      sortPriority: sortPriority,
      mediaUrl: mediaUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
    );
  }
}
