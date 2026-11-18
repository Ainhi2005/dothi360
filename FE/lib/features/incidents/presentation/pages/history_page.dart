import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/incident_code_formatter.dart';
import '../../data/models/report_history_model.dart';
import '../providers/incident_history_provider.dart';
import '../widgets/history_empty_state.dart';
import '../widgets/history_filter_bar.dart';
import '../widgets/history_header.dart';
import '../widgets/history_report_card.dart';
import '../widgets/history_search_field.dart';
import '../widgets/history_verified_banner.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _filter = 'ALL';
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReportHistoryModel> _filterReports(List<ReportHistoryModel> reports) {
    return reports.where((item) {
      if (_filter == 'RESOLVED' && item.status != 'RESOLVED') {
        return false;
      }
      if (_filter == 'PROCESSING' &&
          {'RESOLVED', 'REJECTED', 'CANCELLED'}.contains(item.status)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final code = IncidentCodeFormatter.format(
          item.incidentId.isNotEmpty ? item.incidentId : item.reportId,
          item.createdAt,
        ).toLowerCase();
        final q = _searchQuery.toLowerCase();
        final matchCode = code.contains(q);
        final matchType = item.incidentTypeName.toLowerCase().contains(q);
        final matchDesc = item.description.toLowerCase().contains(q);
        if (!matchCode && !matchType && !matchDesc) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(incidentHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: reportsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.spacingXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: AppDimens.spacingMd),
                  const Text('Không tải được lịch sử',
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppDimens.spacingSm),
                  Text('$error',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: AppDimens.spacingLg),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(incidentHistoryProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
          data: (allItems) {
            final filtered = _filterReports(allItems);
            final allCount = allItems.length;
            final processingCount = allItems
                .where((i) =>
                    !{'RESOLVED', 'REJECTED', 'CANCELLED'}.contains(i.status))
                .length;
            final resolvedCount =
                allItems.where((i) => i.status == 'RESOLVED').length;

            return RefreshIndicator(
              onRefresh: () async =>
                  ref.refresh(incidentHistoryProvider.future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.spacingMd,
                  AppDimens.spacingSm,
                  AppDimens.spacingMd,
                  AppDimens.spacingXl,
                ),
                children: [
                  HistoryHeader(
                    totalCount: allCount,
                    onRefresh: () => ref.invalidate(incidentHistoryProvider),
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                  HistorySearchField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                  HistoryFilterBar(
                    selected: _filter,
                    onSelected: (val) => setState(() => _filter = val),
                    allCount: allCount,
                    processingCount: processingCount,
                    resolvedCount: resolvedCount,
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppDimens.spacingXl),
                      child: HistoryEmptyState(
                        onCreateReport: () =>
                            context.push(AppRoutes.createReport),
                      ),
                    )
                  else ...[
                    for (final report in filtered) ...[
                      HistoryReportCard(
                        report: report,
                        onTap: () => context.push(
                          AppRoutes.incidentDetailPath(report.incidentId),
                        ),
                      ),
                      const SizedBox(height: AppDimens.spacingSm + 2),
                    ],
                    const SizedBox(height: AppDimens.spacingSm),
                    const HistoryVerifiedBanner(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
