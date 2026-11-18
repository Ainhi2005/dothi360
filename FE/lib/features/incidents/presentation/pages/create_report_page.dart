import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/create_report_controller.dart';
import '../widgets/stepper_widget.dart';
import '../widgets/warning_banner.dart';
import '../widgets/image_picker_card.dart';
import '../widgets/description_card.dart';
import '../widgets/location_card.dart';
import '../widgets/create_report_bottom_bar.dart';

/// Màn hình Tạo phản ánh sự cố đô thị (Citizen Flow)
class CreateReportPage extends ConsumerStatefulWidget {
  const CreateReportPage({super.key});

  @override
  ConsumerState<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends ConsumerState<CreateReportPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final c = ref.read(createReportProvider.notifier);
      await c.loadIncidentTypes();
      await c.loadDraft();
      // Tự động kiểm tra vị trí GPS khi mở màn hình nếu chưa có
      if (ref.read(createReportProvider).location == null) {
        c.getCurrentLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe lỗi nghiệp vụ để hiển thị cảnh báo
    ref.listen<CreateReportState>(createReportProvider, (previous, next) {
      if (next.error != null &&
          next.error != previous?.error &&
          next.analysisStage != 'failed') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: context.pop,
        ),
        title: Text(
          'Tạo phản ánh',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(createReportProvider.notifier).saveDraft();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.0,
                    ),
                  ),
                  content: Row(
                    children: [
                      const Icon(
                        Icons.cloud_done_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimens.spacingSm),
                      Expanded(
                        child: Text(
                          'Bản nháp đã lưu trên máy (sẵn sàng offline).',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  action: SnackBarAction(
                    label: 'Về trang chủ',
                    textColor: AppColors.primary,
                    onPressed: () => context.pop(),
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.bookmark_outline_rounded,
              size: AppDimens.iconSizeSm,
              color: AppColors.primary,
            ),
            label: Text(
              'Lưu nháp',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: const SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingMd,
                ),
                child: Column(
                  children: [
                    StepperWidget(currentStep: 1),
                    WarningBanner(),
                    SizedBox(height: AppDimens.spacingMd),
                    // Bước 1: Ảnh hiện trường
                    ImagePickerCard(),
                    SizedBox(height: AppDimens.spacingMd),
                    // Bước 2: Mô tả & Phân loại
                    DescriptionCard(),
                    SizedBox(height: AppDimens.spacingMd),
                    // Bước 3: Vị trí
                    LocationCard(),
                    SizedBox(height: AppDimens.spacingLg),
                  ],
                ),
              ),
            ),
            CreateReportBottomBar(),
          ],
        ),
      ),
    );
  }
}
