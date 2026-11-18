import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

class HomeIncidentSection extends StatelessWidget {
  const HomeIncidentSection(
      {super.key, required this.title, required this.items});
  final String title;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppDimens.spacingSm),
          if (items.isEmpty)
            const Text('Chưa có dữ liệu', style: AppTextStyles.bodyMedium),
          ...items.map((item) => Card(
              child: ListTile(
                  onTap: () => context.push(
                      AppRoutes.incidentDetailPath(item['id'].toString())),
                  title: Text(item['incident_type']?['name']?.toString() ??
                      'Sự cố đô thị'),
                  subtitle: Text(item['description']?.toString() ?? '',
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right)))),
        ],
      );
}
