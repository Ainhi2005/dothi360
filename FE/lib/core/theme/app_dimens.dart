/// Hệ thống kích thước và khoảng cách Đô thị 360 (Civic Harmony Design System)
class AppDimens {
  const AppDimens._();

  // Decode local previews at display scale instead of full camera resolution.
  static const int mediaPreviewDecodeWidth = 1200;
  static const int mediaThumbnailDecodeWidth = 384;

  // ==========================================
  // 1. SPACING SCALE (Hệ thống khoảng cách 4px)
  // ==========================================
  static const double spacing2Xs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingBase = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ==========================================
  // 2. RADIUS SCALE (Hệ thống bo góc có thứ bậc)
  // ==========================================
  static const double radiusNone = 0.0;
  static const double radiusXs = 4.0; // Micro indicator, status dot
  static const double radiusSm = 8.0; // Button, TextField, Dropdown, Search
  static const double radiusMd = 12.0; // Standard Card, Panel, Image thumbnail
  static const double radiusLg =
      16.0; // Modal dialog, Bottom sheet, Featured card
  static const double radiusXl = 24.0; // Prominent rounded surface, large pill
  static const double radiusFull = 9999.0; // Avatar tròn, FAB, pill badge

  // ==========================================
  // 3. ICON SIZES
  // ==========================================
  static const double iconSizeXs = 12.0;
  static const double iconSizeSm = 16.0;
  static const double iconSizeBase = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 40.0;

  // ==========================================
  // 4. CONTROL & TOUCH TARGET HEIGHTS
  // ==========================================
  static const double buttonHeight = 48.0;
  static const double inputHeight = 48.0;
  static const double minTouchTarget = 48.0;

  // ==========================================
  // 5. BACKWARD COMPATIBILITY CONSTANTS
  // (Giữ cho các màn hình feature hiện tại)
  // ==========================================
  static const double emergencyIconBoxSize = 48.0;
  static const double homeHeroHeight = 200.0;
  static const double homeSearchHeight = 52.0;
  static const double accountMenuIconSize = 36.0;
  static const double homeServiceIconSize = 38.0;
  static const double homeActionIconSize = 74.0;
  static const double homeActionCompactIconSize = 52.0;
  static const double homeActionHeight = 184.0;
  static const double homeActionRowBreakpoint = 330.0;
  static const double homeActionCardBreakpoint = 220.0;
  static const double centerNavButtonSize = 36.0;
  static const double homeReportImageWidth = 96.0;
  static const double homeReportImageHeight = 60.0;
  static const double homeNewsImageHeight = 92.0;
  static const double homeIncidentCardWidth = 172.0;
  static const double homeIncidentImageHeight = 88.0;
  static const double homeCarouselHeight = 156.0;
  static const double officerTaskThumbnail = 76.0;
  static const double officerSummaryHeight = 70.0;
  static const double mapMarkerSize = 42.0;
  static const double mapClusterSize = 46.0;

  static const double authMaxWidth = 520;
  static const double authLogoSize = 64;
  static const double authHeroMin = 280;
  static const double authHeroMax = 430;
  static const double authRegisterHeroMin = 210;
  static const double authRegisterHeroMax = 300;
  static const double authSheetOverlap = 32;
  static const double authSheetTopPadding = 42;
  static const double authFooterHeight = 64;
  static const double authControlHeight = 50;
  static const double authButtonRadius = 18;
}
