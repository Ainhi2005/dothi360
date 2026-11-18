import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Thang kiểu chữ chuẩn Đô thị 360 (Civic Harmony Design System)
class AppTextStyles {
  const AppTextStyles._();

  // ==========================================
  // 1. DISPLAY & HEADINGS (Tiêu đề chính)
  // ==========================================
  /// Tiêu đề rất lớn (Hero screen, Auth Welcome)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    height: 1.25,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Tiêu đề lớn (Page Topbar, Main Title)
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    height: 1.33,
    letterSpacing: -0.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Tiêu đề vừa (Section Header, Modal Dialog)
  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    height: 1.4,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Tiêu đề nhỏ (Panel Header, Card Header lớn)
  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    height: 1.44,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Tiêu đề card, nhóm danh sách
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ==========================================
  // 2. BODY TEXT (Nội dung)
  // ==========================================
  /// Văn bản chính, mô tả dài, nội dung input
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    height: 1.46,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  /// Văn bản phụ, thông tin thứ cấp, ô bảng
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  /// Văn bản nhỏ, metadata, khoảng cách, timestamp
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  /// Nhãn phụ, tag, status badge (11px)
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    height: 1.27,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  // ==========================================
  // 3. INTERACTIVE (Nút bấm & Liên kết)
  // ==========================================
  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    height: 1.33,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ==========================================
  // 4. METRICS & COUNTERS (Số liệu thống kê Tabular)
  // ==========================================
  static const TextStyle metricLarge = TextStyle(
    fontSize: 28,
    height: 1.14,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle metricMedium = TextStyle(
    fontSize: 20,
    height: 1.2,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle authBrand = TextStyle(
      fontSize: 30,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: .4,
      color: AppColors.authInk);
  static const TextStyle authHeading = TextStyle(
      fontSize: 26,
      height: 1.25,
      fontWeight: FontWeight.w800,
      letterSpacing: -.6,
      color: AppColors.authInk);
  static const TextStyle authRegisterHeading = TextStyle(
      fontSize: 23,
      height: 1.3,
      fontWeight: FontWeight.w800,
      letterSpacing: -.5,
      color: AppColors.authInk);
  static const TextStyle authBody =
      TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary);
  static const TextStyle authField =
      TextStyle(fontSize: 14, height: 1.3, color: AppColors.textPrimary);
  static const TextStyle authLink = TextStyle(
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w700,
      color: AppColors.authInk);
  static const TextStyle authButton = TextStyle(
      fontSize: 16,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: AppColors.surface);
}
