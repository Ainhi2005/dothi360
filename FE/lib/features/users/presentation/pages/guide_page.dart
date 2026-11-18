import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../emergency_guides/presentation/providers/emergency_guide_provider.dart';
import '../../../emergency_guides/presentation/widgets/emergency_guide_card.dart';
import '../../../emergency_guides/presentation/widgets/emergency_guide_header.dart';

class GuidePage extends ConsumerWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guides = ref.watch(emergencyGuidesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const EmergencyGuideHeader(),
            Expanded(
              child: guides.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: FilledButton.icon(
                    onPressed: () => ref.invalidate(emergencyGuidesProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại hướng dẫn'),
                  ),
                ),
                data: (items) => RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(emergencyGuidesProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spacingMd,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return EmergencyGuideCard(
                        guide: item,
                        onTap: () => context.push(
                          AppRoutes.emergencyGuidePath(item.id),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
