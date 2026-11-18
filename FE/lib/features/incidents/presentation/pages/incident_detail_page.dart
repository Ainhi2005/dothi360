import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/incident_code_formatter.dart';
import '../../../../core/widgets/ai_analysis_insight_card.dart';
import '../providers/incident_history_provider.dart';
import '../widgets/incident_detail_app_bar.dart';
import '../widgets/incident_detail_bottom_bar.dart';
import '../widgets/incident_detail_overview_card.dart';
import '../widgets/incident_location_card.dart';
import '../widgets/incident_progress_timeline_card.dart';
import '../widgets/incident_scene_photos_card.dart';

/// Màn hình Chi tiết phản ánh sự cố đô thị (Citizen Detail View)
class IncidentDetailPage extends ConsumerWidget {
  final String incidentId;
  const IncidentDetailPage({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(incidentDetailProvider(incidentId));

    return detailAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppDimens.spacingMd),
                Text(
                  'Không thể tải thông tin phản ánh',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimens.spacingXs),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.spacingMd),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(incidentDetailProvider(incidentId)),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Thử lại'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (incident) {
        final formattedCode = IncidentCodeFormatter.format(
          incident.id,
          incident.createdAt,
        );

        final myReports =
            ref.watch(incidentHistoryProvider).asData?.value ?? [];
        final isMyReport = incident.isMine ||
            myReports.any(
                (r) => r.incidentId == incidentId || r.reportId == incidentId);
        final showEndorsementBar = !isMyReport && incident.status != 'RESOLVED';

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: IncidentDetailAppBar(
            formattedCode: formattedCode,
            status: incident.status,
            onShare: () {
              Clipboard.setData(
                ClipboardData(
                  text:
                      'Phản ánh $formattedCode: ${incident.description} (${incident.incidentTypeName}) - Đô thị 360',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Đã sao chép thông tin sự cố $formattedCode vào bộ nhớ tạm'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          bottomNavigationBar: showEndorsementBar
              ? IncidentDetailBottomBar(
                  reportCount: incident.reportCount,
                  onEndorse: () async {
                    try {
                      final res = await ref
                          .read(incidentHistoryDataSourceProvider)
                          .endorseIncident(incidentId);
                      final msg = res['message']?.toString() ??
                          'Đã ghi nhận đóng góp đồng phản ánh (+1) của bạn!';
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      ref.invalidate(incidentDetailProvider(incidentId));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Không thể đồng phản ánh: $e'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                )
              : null,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                ref.refresh(incidentDetailProvider(incidentId).future),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingMd,
                vertical: AppDimens.spacingSm,
              ),
              children: [
                // 1. Trả lời ngay 3 câu hỏi & Summary gọn
                IncidentDetailOverviewCard(incident: incident),
                const SizedBox(height: AppDimens.spacingMd),

                // 2. Timeline là khối quan trọng nhất
                IncidentProgressTimelineCard(
                  incident: incident,
                  formattedCode: formattedCode,
                ),
                const SizedBox(height: AppDimens.spacingMd),

                // 3. Ảnh hiện trường ở dạng gallery trước/sau
                if (incident.imageUrls.isNotEmpty ||
                    incident.officerImageUrls.isNotEmpty) ...[
                  IncidentScenePhotosCard(
                    reporterImages: incident.imageUrls,
                    officerImages: incident.officerImageUrls,
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                ],

                // 4. AI tóm tắt ngắn và biện pháp đề xuất (chi tiết có thể mở rộng)
                if (incident.aiAnalysis != null &&
                    incident.aiAnalysis!['analysis_status'] != 'FAILED') ...[
                  AiAnalysisInsightCard(
                    aiAnalysis: incident.aiAnalysis!,
                    title: 'Đánh giá AI & Biện pháp đề xuất',
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                ],

                // 5. Bản đồ là khối phụ, không chiếm quá nhiều chiều cao
                if (incident.latitude != null &&
                    incident.longitude != null) ...[
                  IncidentLocationCard(
                    latitude: incident.latitude!,
                    longitude: incident.longitude!,
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                ],

                const SizedBox(height: AppDimens.spacingLg),
              ],
            ),
          ),
        );
      },
    );
  }
}
