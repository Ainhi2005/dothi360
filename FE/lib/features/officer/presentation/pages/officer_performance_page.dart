import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/officer_provider.dart';

class OfficerPerformancePage extends ConsumerWidget {
  const OfficerPerformancePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      appBar: AppBar(title: const Text('Hiệu suất cá nhân')),
      body: FutureBuilder<Map<String, dynamic>>(
          future: ref.read(officerRemoteDataSourceProvider).getPerformance(),
          builder: (context, s) {
            if (!s.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final d = Map<String, dynamic>.from(s.data!['summary']),
                trend = List<Map<String, dynamic>>.from(s.data!['trend'] ?? []);
            return ListView(
                padding: const EdgeInsets.all(AppDimens.spacingMd),
                children: [
                  const Text(
                      'Dữ liệu giúp bạn cải thiện quy trình, không dùng để xếp hạng.',
                      style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppDimens.spacingMd),
                  GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.7,
                      children: [
                        _Metric('Đang xử lý', '${d['active'] ?? 0}'),
                        _Metric('Hoàn thành', '${d['completed'] ?? 0}'),
                        _Metric('Đúng SLA', '${d['sla_rate'] ?? 100}%'),
                        _Metric('Tiếp nhận TB',
                            '${d['avg_accept_minutes'] ?? 0} phút'),
                        _Metric('Bị trả lại', '${d['reworked'] ?? 0}')
                      ]),
                  const SizedBox(height: AppDimens.spacingLg),
                  const Text('12 tuần gần đây',
                      style: AppTextStyles.titleMedium),
                  ...trend.map((x) => ListTile(
                      title: Text('${x['period']}'),
                      subtitle: LinearProgressIndicator(
                          value: (x['completed'] ?? 0) /
                              ((x['total'] ?? 0) == 0 ? 1 : x['total'])),
                      trailing: Text('${x['completed']}/${x['total']}')))
                ]);
          }));
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingMd),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(value, style: AppTextStyles.headingMedium),
            Text(label, style: AppTextStyles.bodySmall)
          ])));
}
