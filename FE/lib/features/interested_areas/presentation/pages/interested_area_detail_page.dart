import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../providers/interested_area_provider.dart';

final interestedAreaIncidentsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.read(interestedAreaDataSourceProvider).incidents(id),
);

class InterestedAreaDetailPage extends ConsumerWidget {
  const InterestedAreaDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interestedAreaIncidentsProvider(id));
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: const Text(
          'Sự cố trong khu vực',
          style: AppTextStyles.titleMedium,
        ),
        backgroundColor: AppColors.homeCanvas,
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(interestedAreaIncidentsProvider(id)),
            child: const Text('Tải lại'),
          ),
        ),
        data: (payload) {
          final area =
              Map<String, dynamic>.from(payload['area'] ?? const {});
          final items =
              List<Map<String, dynamic>>.from(payload['data'] ?? const []);
          return ListView(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            children: [
              Text(
                area['name']?.toString() ?? 'Khu vực',
                style: AppTextStyles.titleMedium,
              ),
              Text(
                'Bán kính ${(double.tryParse('${area['radius_m']}') ?? 0) / 1000} km · ${items.length} sự cố',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimens.spacingMd),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppDimens.spacingXl),
                  child: Text(
                    'Chưa có sự cố trong khu vực này.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ...items.map(
                (item) => Card(
                  color: AppColors.surface,
                  elevation: 0,
                  child: ListTile(
                    onTap: () =>
                        context.push(AppRoutes.incidentDetailPath('${item['id']}')),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: item['cover_url'] == null
                            ? const ColoredBox(
                                color: AppColors.homeMint,
                                child: Icon(Icons.image_outlined),
                              )
                            : AppCachedImage(
                                imageUrl: '${item['cover_url']}',
                                fit: BoxFit.cover,
                                memCacheWidth: 150,
                              ),
                      ),
                    ),
                    title: Text(
                      item['incident_type_name']?.toString() ?? 'Sự cố đô thị',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${item['distance_m'] ?? 0} m · ${item['description'] ?? ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
