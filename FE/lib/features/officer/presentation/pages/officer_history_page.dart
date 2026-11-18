import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_dimens.dart';
import '../providers/officer_provider.dart';
import '../widgets/officer_assignment_card.dart';

class OfficerHistoryPage extends ConsumerWidget {
  const OfficerHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(officerAssignmentsProvider('history'));
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử công việc')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
            child: TextButton(
          onPressed: () =>
              ref.invalidate(officerAssignmentsProvider('history')),
          child: Text('Thử lại: $error'),
        )),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Chưa có lịch sử tiếp nhận'))
            : ListView.separated(
                padding: const EdgeInsets.all(AppDimens.spacingMd),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimens.spacingSm),
                itemBuilder: (_, index) => OfficerAssignmentCard(
                  assignment: items[index],
                  onTap: () => context.push(
                    AppRoutes.officerAssignmentPath(items[index].id),
                    extra: items[index],
                  ),
                ),
              ),
      ),
    );
  }
}
