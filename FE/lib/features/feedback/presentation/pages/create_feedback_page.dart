import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/feedback_provider.dart';

class CreateFeedbackPage extends ConsumerStatefulWidget {
  const CreateFeedbackPage({super.key});

  @override
  ConsumerState<CreateFeedbackPage> createState() => _CreateFeedbackPageState();
}

class _CreateFeedbackPageState extends ConsumerState<CreateFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();

  String _category = 'GENERAL';
  bool _submitting = false;

  static const _categoryOptions = [
    {'key': 'TRAFFIC', 'label': 'Giao thông & Đi lại'},
    {'key': 'GREENERY', 'label': 'Cây xanh & Công viên'},
    {'key': 'LIGHTING', 'label': 'Chiếu sáng & Cột điện'},
    {'key': 'DRAINAGE', 'label': 'Thoát nước & Hố ga'},
    {'key': 'ENVIRONMENT', 'label': 'Môi trường & Rác thải'},
    {'key': 'GENERAL', 'label': 'Kiến nghị đô thị chung'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(feedbackDataSourceProvider).create(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            category: _category,
            locationName: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi hiến kế thành công. Cảm ơn đóng góp của bạn!'),
            backgroundColor: AppColors.grabGreen,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi gửi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gửi hiến kế đô thị'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.spacingBase),
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.spacingSm + 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary),
                  const SizedBox(width: AppDimens.spacingSm),
                  Expanded(
                    child: Text(
                      'Ý kiến và giải pháp của bạn sẽ được chuyển trực tiếp tới các cơ quan chuyên trách nghiên cứu triển khai.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.spacingLg),
            Text(
              'Lĩnh vực góp ý',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppDimens.spacingSm),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: _categoryOptions.map((opt) {
                return DropdownMenuItem(
                  value: opt['key'],
                  child: Text(opt['label']!, style: AppTextStyles.bodyMedium),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: AppDimens.spacingLg),
            Text(
              'Tiêu đề sáng kiến',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppDimens.spacingSm),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'VD: Lắp đặt gương cầu lồi tại ngã ba...',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 5) {
                  return 'Tiêu đề ít nhất 5 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimens.spacingLg),
            Text(
              'Nội dung đề xuất giải pháp',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppDimens.spacingSm),
            TextFormField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Nêu rõ thực trạng, ý tưởng và giải pháp cụ thể...',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 10) {
                  return 'Nội dung ít nhất 10 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimens.spacingLg),
            Text(
              'Vị trí / Tuyến đường (không bắt buộc)',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppDimens.spacingSm),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'VD: Cổng trường THCS Chu Văn An, đường Thụy Khuê',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimens.spacingXl),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_submitting ? 'Đang gửi...' : 'Gửi hiến kế'),
            ),
          ],
        ),
      ),
    );
  }
}

