import 'package:flutter/material.dart';

/// Hệ thống token màu sắc Đô thị 360 (Civic Harmony Design System)
class AppColors {
  const AppColors._();

  // ==========================================
  // 1. PRIMARY BRAND TOKENS
  // ==========================================
  /// Xanh đậm thương hiệu chủ đạo (Civic Emerald)
  static const Color primary = Color(0xFF006B4D);

  /// Trạng thái tương tác nhấn/hover
  static const Color primaryDark = Color(0xFF00543C);

  /// Nền nhẹ cho chip, badge, selected state
  static const Color primaryLight = Color(0xFFE6F4EE);

  /// Container viền hoặc khối nhấn trung tính
  static const Color primaryContainer = Color(0xFFD3EAE0);

  // ==========================================
  // 2. NEUTRAL GROUNDS & SURFACES
  // ==========================================
  /// Nền toàn màn hình (Civic Canvas - dịu mắt, tránh chói lóa)
  static const Color background = Color(0xFFF6F8F7);

  /// Bề mặt thẻ, card, modal, bottom sheet
  static const Color surface = Color(0xFFFFFFFF);

  /// Bề mặt phụ, thanh công cụ, ô input mờ
  static const Color surfaceSubtle = Color(0xFFF0F4F2);

  // ==========================================
  // 3. TEXT & INK TOKENS (Độ tương phản chuẩn WCAG 2.1 AA)
  // ==========================================
  /// Chữ tiêu đề đậm, nội dung chính (Contrast 12:1)
  static const Color textPrimary = Color(0xFF152C24);

  /// Chữ mô tả phụ, nhãn thứ cấp (Contrast 5.2:1)
  static const Color textSecondary = Color(0xFF566A62);

  /// Chữ mờ, timestamp, hint text
  static const Color textTertiary = Color(0xFF8A9E96);

  /// Chữ cho trạng thái vô hiệu hóa
  static const Color textDisabled = Color(0xFFB0BFB9);

  // ==========================================
  // 4. BORDER & DIVIDER TOKENS
  // ==========================================
  /// Đường viền tiêu chuẩn cho thẻ, input, dropdown
  static const Color border = Color(0xFFDCE5E0);

  /// Đường viền khi hover hoặc input có giá trị
  static const Color borderStrong = Color(0xFFB8CBC3);

  /// Đường kẻ phân cách giữa các mục
  static const Color divider = Color(0xFFE7ECE9);

  // ==========================================
  // 5. SEMANTIC STATUS TOKENS
  // ==========================================
  // Success / Resolved (Đã hoàn thành / Nghiệm thu)
  static const Color success = Color(0xFF108558);
  static const Color successLight = Color(0xFFEBF8F2);
  static const Color successBorder = Color(0xFFB8E5D2);
  static const Color successText = Color(0xFF085437);

  // Warning / Pending (Chờ phân công / Chờ nghiệm thu)
  static const Color warning = Color(0xFFC07706);
  static const Color warningLight = Color(0xFFFEF8EC);
  static const Color warningBorder = Color(0xFFF6DC9F);
  static const Color warningText = Color(0xFF784902);

  // Info / In Progress (Đã tiếp nhận / Đang xử lý)
  static const Color info = Color(0xFF1D6CB5);
  static const Color infoLight = Color(0xFFEEF5FC);
  static const Color infoBorder = Color(0xFFBCD8F3);
  static const Color infoText = Color(0xFF124575);

  // Error / Danger (Khẩn cấp / Quá hạn / Từ chối / Đã hủy) - Gam màu basic
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color errorBorder = Color(0xFFFECACA);
  static const Color errorText = Color(0xFF991B1B);

  // Map incident states. Colour is reserved for operational meaning on maps.
  static const Color mapEmergency = Color(0xFFC62828);
  static const Color mapHighPriority = Color(0xFFEA6A12);
  static const Color mapPending = Color(0xFFE09A12);
  static const Color mapAssigned = Color(0xFF2878B5);
  static const Color mapInProgress = primary;
  static const Color mapVerification = Color(0xFF0B8793);
  static const Color mapResolved = success;
  static const Color mapClosed = Color(0xFF718078);

  // Basic Alert Palette (Đỏ basic dứt khoát, chuẩn hành chính, không dùng pastel AI)
  static const Color alertRed = Color(0xFFDC2626);
  static const Color alertRedLight = Color(0xFFFEE2E2);
  static const Color alertRedBorder = Color(0xFFFECACA);
  static const Color alertRedBg = Color(0xFFFFFFFF);
  static const Color alertRedText = Color(0xFF991B1B);

  // ==========================================
  // 6. BACKWARD COMPATIBILITY ALIASES
  // Giữ nguyên cho các feature hiện có không bị lỗi
  // ==========================================
  static const Color homeGreen = primary;
  static const Color homeGreenDark = primaryDark;
  static const Color homeMint = primaryLight;
  static const Color homeMintStrong = primaryContainer;
  static const Color homeNavy = Color(0xFF0E2147);
  static const Color homeCanvas = background;
  static const Color homeYellow = Color(0xFFFFE07A);
  static const Color homeOrange = Color(0xFFFF5A1F);
  static const Color shadow = Color(0x1A006B4D);
  static const Color overlayDark = Color(0x660E2147);

  // Emergency guide palette compatibility
  static const Color emergencyAlertBg = Color(0xFFFFF1F2);
  static const Color emergencyAlertBorder = Color(0xFFFFD2D2);
  static const Color emergencyAlertText = Color(0xFF7F1D1D);
  static const Color emergencyPillBg = Color(0xFFDC2626);
  static const Color emergencyHotlineBg = Color(0xFF0F766E);
  static const Color emergencySuccessBorder = successBorder;
  static const Color emergencySuccessBg = successLight;
  static const Color emergencySuccessText = successText;

  // Emergency category colors compatibility
  static const Color categoryMedicalBg = Color(0xFFFFE4E6);
  static const Color categoryMedical = Color(0xFFF43F5E);
  static const Color categoryFloodBg = Color(0xFFE0F2FE);
  static const Color categoryFlood = Color(0xFF0284C7);
  static const Color categoryElectricBg = Color(0xFFFEF3C7);
  static const Color categoryElectric = Color(0xFFD97706);
  static const Color categoryTreeBg = Color(0xFFDCFCE7);
  static const Color categoryTree = Color(0xFF16A34A);
  static const Color categoryChemicalBg = Color(0xFFF3E8FF);
  static const Color categoryChemical = Color(0xFF9333EA);
  static const Color categoryTrafficBg = Color(0xFFEDE9FE);
  static const Color categoryTraffic = Color(0xFF6366F1);
  static const Color categoryElevatorBg = Color(0xFFE0F7FA);
  static const Color categoryElevator = Color(0xFF0891B2);
  static const Color categoryFireBg = Color(0xFFFEE2E2);
  static const Color categoryFire = Color(0xFFEF4444);

  static const Color emergencyTeal = Color(0xFF0D9488);
  static const Color searchBg = surfaceSubtle;
  static const Color starGold = Color(0xFFF59E0B);

  // ==========================================
  // 7. GRAB DESIGN TOKENS
  // ==========================================
  static const Color grabGreen = Color(0xFF00B14F);
  static const Color grabGreenDark = Color(0xFF00853B);
  static const Color grabMintBg = Color(0xFFE7F8EE);
  static const Color grabGreenLight = Color(0xFFE7F8EE);
  static const Color grabHeaderTop = Color(0xFF50D492);
  static const Color grabHeaderMid = Color(0xFF87E5B5);
  static const Color grabHeaderLight = Color(0xFFD4F5E2);

  // Utility category pastel palettes
  static const Color utilityRedBg = Color(0xFFFFEBEE);
  static const Color utilityRed = Color(0xFFD32F2F);
  static const Color utilityBlueBg = Color(0xFFE1F5FE);
  static const Color utilityBlue = Color(0xFF0288D1);
  static const Color utilityAmberBg = Color(0xFFFFF8E1);
  static const Color utilityAmber = Color(0xFFF57C00);
  static const Color utilityGreenBg = Color(0xFFE8F5E9);
  static const Color utilityGreen = Color(0xFF2E7D32);
  static const Color utilityYellowBg = Color(0xFFFFFDE7);
  static const Color utilityYellow = Color(0xFFFBC02D);
  static const Color utilityTealBg = Color(0xFFE0F2F1);
  static const Color utilityTeal = Color(0xFF00796B);
  static const Color utilityPinkBg = Color(0xFFFCE4EC);
  static const Color utilityPink = Color(0xFFC2185B);
  static const Color utilityAllBg = Color(0xFFE8F8F0);
  static const Color utilityAll = Color(0xFF00B14F);

  // Status badge tags
  static const Color badgeAmberBg = Color(0xFFFEF3C7);
  static const Color badgeAmberText = Color(0xFFB45309);
  static const Color badgeBlueBg = Color(0xFFE0F2FE);
  static const Color badgeBlueText = Color(0xFF0369A1);
  static const Color badgeGreenBg = Color(0xFFDCFCE7);
  static const Color badgeGreenText = Color(0xFF15803D);

  // Subtle utility, shadow and border tokens
  static const Color shadowSubtle = Color(0x0A000000);
  static const Color shadowSearch = Color(0x14000000);
  static const Color shadowFab = Color(0x5900B14F);
  static const Color shadowGold = Color(0x3DF59E0B);
  static const Color arrowBadgeBg = Color(0xFFF1F3F5);
  static const Color imagePlaceholderBg = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF3F4F6);
  static const Color navBorderTop = Color(0xFFEAECEF);
  static const Color navInactive = Color(0xFF8C98A4);

  // Hanoi authentication surfaces.
  static const Color authCanvas = Color(0xFFFCFAF7);
  static const Color authInk = Color(0xFF084F3C);
  static const Color authGreen = Color(0xFF008361);
  static const Color authBorder = Color(0xFFD6DDD8);
  static const Color authWaveLight = Color(0xFFD8E9D7);
  static const Color authWaveMedium = Color(0xFF9BCBAD);
  static const Color authWaveDark = Color(0xFF58AB89);
}
