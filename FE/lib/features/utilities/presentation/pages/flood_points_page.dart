import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/providers/utility_providers.dart';
import '../widgets/flood_point_card.dart';

class FloodPointsPage extends ConsumerStatefulWidget {
  const FloodPointsPage({super.key});

  @override
  ConsumerState<FloodPointsPage> createState() => _FloodPointsPageState();
}

class _FloodPointsPageState extends ConsumerState<FloodPointsPage> {
  int _selectedFilter = 0; // 0: Tất cả, 1: Đang ngập, 2: Đã rút

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(floodPointsProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Điểm ngập úng đô thị',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.homeNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push(AppRoutes.createReport),
        icon: const Icon(Icons.add_location_alt_outlined, color: AppColors.surface),
        label: Text(
          'Báo điểm ngập',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                    const SizedBox(height: AppDimens.spacingSm),
                    Text('Không thể tải danh sách điểm ngập', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppDimens.spacingMd),
                    FilledButton(
                      onPressed: () => ref.invalidate(floodPointsProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (points) {
                final filtered = points.where((p) {
                  if (_selectedFilter == 1) return p.status != 'RESOLVED';
                  if (_selectedFilter == 2) return p.status == 'RESOLVED';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.water_drop_outlined,
                          size: 48,
                          color: AppColors.categoryFlood,
                        ),
                        const SizedBox(height: AppDimens.spacingMd),
                        Text(
                          'Không có điểm ngập nào',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.homeNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimens.spacingXs),
                        Text(
                          'Khu vực hiện tại không ghi nhận ngập úng.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(floodPointsProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.spacingMd,
                      AppDimens.spacingSm,
                      AppDimens.spacingMd,
                      80,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final point = filtered[index];
                      return FloodPointCard(
                        point: point,
                        onTap: () => context.push(AppRoutes.incidentDetailPath(point.id)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = ['Tất cả', 'Đang ngập', 'Đã tiêu thoát'];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingMd,
        vertical: AppDimens.spacingSm,
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedFilter == i;
          return Padding(
            padding: const EdgeInsets.only(right: AppDimens.spacingSm),
            child: ChoiceChip(
              label: Text(tabs[i]),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = i),
              selectedColor: AppColors.categoryFloodBg,
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.categoryFlood : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.categoryFlood : AppColors.border,
              ),
            ),
          );
        }),
      ),
    );
  }
}
