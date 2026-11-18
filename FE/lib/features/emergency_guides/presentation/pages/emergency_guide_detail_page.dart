import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../providers/emergency_guide_provider.dart';
import '../widgets/guide_avoid_section.dart';
import '../widgets/guide_detail_app_bar.dart';
import '../widgets/guide_do_now_section.dart';
import '../widgets/guide_header_card.dart';
import '../widgets/guide_hotline_card.dart';

class EmergencyGuideDetailPage extends ConsumerWidget {
  const EmergencyGuideDetailPage({
    super.key,
    required this.guideId,
  });

  final String guideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(emergencyGuideDetailProvider(guideId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GuideDetailAppBar(
        onBack: () => context.pop(),
        onShare: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã sao chép liên kết chia sẻ quy trình xử lý.'),
            ),
          );
        },
      ),
      body: guideAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(emergencyGuideDetailProvider(guideId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại quy trình'),
          ),
        ),
        data: (guide) {
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingMd,
              vertical: AppDimens.spacingSm,
            ),
            children: [
              GuideHeaderCard(guide: guide),
              const SizedBox(height: AppDimens.spacingMd),
              GuideHotlineCard(guide: guide),
              const SizedBox(height: AppDimens.spacingMd),
              GuideDoNowSection(steps: guide.resolvedSteps),
              const SizedBox(height: AppDimens.spacingMd),
              GuideAvoidSection(items: guide.resolvedAvoidItems),
              const SizedBox(height: AppDimens.spacingLg),
            ],
          );
        },
      ),
    );
  }
}
