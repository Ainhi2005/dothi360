import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/resolved_incident_item_card.dart';

/// Màn hình danh sách toàn bộ các sự cố vừa giải quyết xong trong đô thị
class ResolvedIncidentsPage extends StatefulWidget {
  const ResolvedIncidentsPage({super.key});

  @override
  State<ResolvedIncidentsPage> createState() => _ResolvedIncidentsPageState();
}

class _ResolvedIncidentsPageState extends State<ResolvedIncidentsPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _incidents = [];

  @override
  void initState() {
    super.initState();
    _loadResolvedIncidents();
  }

  Future<void> _loadResolvedIncidents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await DioClient().dio.get(
        '/incidents',
        queryParameters: {
          'status': 'RESOLVED',
          'limit': 50,
        },
      );
      final rawList = res.data?['data'];
      if (rawList is List) {
        if (mounted) {
          setState(() {
            _incidents = List<Map<String, dynamic>>.from(
              rawList.map((e) => Map<String, dynamic>.from(e as Map)),
            );
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _incidents = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách sự cố đã giải quyết.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Vừa giải quyết xong',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadResolvedIncidents,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
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
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimens.spacingMd),
              ElevatedButton.icon(
                onPressed: _loadResolvedIncidents,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_incidents.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  size: 56,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: AppDimens.spacingSm),
                Text(
                  'Chưa có sự cố nào hoàn tất gần đây',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.spacingBase),
      itemCount: _incidents.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Banner thông tin trên đầu
          return Container(
            margin: const EdgeInsets.only(bottom: AppDimens.spacingMd),
            padding: const EdgeInsets.all(AppDimens.spacingSm + 4),
            decoration: BoxDecoration(
              color: AppColors.badgeGreenBg,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(
                color: AppColors.grabGreen.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.grabGreenDark,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Danh sách các sự cố đô thị đã được các đơn vị tiếp nhận và xử lý hoàn tất trên địa bàn.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grabGreenDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final item = _incidents[index - 1];
        final id = item['id']?.toString() ?? '';

        return ResolvedIncidentItemCard(
          incident: item,
          onTap: () {
            if (id.isNotEmpty) {
              context.push(AppRoutes.incidentDetailPath(id));
            }
          },
        );
      },
    );
  }
}
