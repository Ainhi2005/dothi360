import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/providers/utility_providers.dart';
import '../widgets/department_contact_card.dart';

class DepartmentsDirectoryPage extends ConsumerStatefulWidget {
  const DepartmentsDirectoryPage({super.key});

  @override
  ConsumerState<DepartmentsDirectoryPage> createState() => _DepartmentsDirectoryPageState();
}

class _DepartmentsDirectoryPageState extends ConsumerState<DepartmentsDirectoryPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(departmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Đơn vị phụ trách địa bàn',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.homeNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm đơn vị (Thoát nước, Cây xanh, CSGT...)',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.searchBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                    const SizedBox(height: AppDimens.spacingSm),
                    Text('Không thể tải danh bạ đơn vị', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppDimens.spacingMd),
                    FilledButton(
                      onPressed: () => ref.invalidate(departmentsProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (departments) {
                final filtered = departments.where((d) {
                  if (_searchQuery.isEmpty) return true;
                  final inName = d.name.toLowerCase().contains(_searchQuery);
                  final inAddress = d.address.toLowerCase().contains(_searchQuery);
                  final inTypes = d.managedIncidentTypes.any(
                    (t) => t.toLowerCase().contains(_searchQuery),
                  );
                  return inName || inAddress || inTypes;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Không tìm thấy đơn vị phù hợp',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(departmentsProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimens.spacingMd),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return DepartmentContactCard(department: filtered[index]);
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
}
