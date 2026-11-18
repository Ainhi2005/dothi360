2. Màu sắc
Không hardcode Color(0xFF...) trực tiếp trong widget.
Khai báo hết trong core/theme/app_colors.dart (static const).
Đặt tên theo ngữ nghĩa, không theo mã màu: primary, secondary, background, surface, textPrimary, textSecondary, border, divider, error, success, warning.
Ưu tiên dùng qua Theme.of(context).colorScheme nếu map được vào ColorScheme chuẩn của Material, còn lại dùng AppColors.xxx.
3. Typography / Font
Khai báo trong core/theme/app_text_styles.dart: headingLarge, headingMedium, titleMedium, bodyLarge, bodyMedium, caption, buttonText...
Font family khai báo 1 lần duy nhất trong AppTheme (ThemeData), không set fontFamily lẻ tẻ trong từng Text.
Không magic number cho fontSize, fontWeight, height — luôn qua style có sẵn.
4. Spacing & Kích thước
core/theme/app_dimens.dart: spacingXs/sm/md/lg/xl, radiusSm/md/lg, iconSizeSm/md/lg.
Tránh EdgeInsets.all(16) rải rác khắp nơi — dùng AppDimens.spacingMd.
5. Component dùng chung (core/widgets)
Nếu 1 component lặp lại ≥2 màn hình → đưa vào core/widgets.
Đặt tên thống nhất 1 prefix: AppButton, AppTextField, AppCard, AppChip, AppAvatar...
Biến thể xử lý qua parameter/enum, không tạo nhiều widget riêng cho từng biến thể.
Ví dụ: AppButton(type: AppButtonType.primary | secondary | outline | text, size: ...)
Widget core không chứa business logic, chỉ nhận data/callback qua props (onPressed, label, isLoading...).
6. Chia nhỏ Widget (Widget Decomposition)
Không viết 1 màn hình dồn hết vào 1 file xxx_screen.dart. Nhìn ảnh, xác định các khối UI rõ ràng (header, banner, danh sách, item, bottom bar, form...) rồi mỗi khối tách thành 1 widget riêng, nằm trong 1 file .dart riêng, sau đó import về file screen chính để ráp lại. File screen chính lúc đó chỉ còn nhiệm vụ bố cục tổng (layout/ghép các widget con lại), không chứa chi tiết UI bên trong từng khối.
Cấm dùng hàm helper kiểu Widget _buildHeader() nằm chung trong file screen — bắt buộc tách thành class riêng + file riêng. Lý do: hàm helper vẫn nằm trong build() của widget cha nên không cô lập được rebuild, không đặt const được, không tái sử dụng/không import sang màn khác được, và file screen vẫn dài như cũ.
Vị trí file: mỗi widget con của 1 màn hình nằm trong features/<ten_man_hinh>/presentation/widgets/, đặt tên file theo widget: header_section.dart → chứa class HeaderSection, product_card.dart → chứa class ProductCard... (1 file = 1 widget chính, đúng mục 8).
Mỗi widget con chỉ đảm nhiệm 1 nhiệm vụ UI rõ ràng (Single Responsibility) — đặt tên đúng theo thứ đang hiển thị: ProductCard, RatingBadge, SectionHeader, EmptyState...
Widget con nhận dữ liệu qua constructor, không tự đọc mock data/global state bên trong — nhờ vậy widget này vẫn dùng lại được ở màn khác trong cùng feature, hoặc dễ "thăng cấp" lên core/widgets sau này nếu feature khác cũng cần.
Item trong danh sách (ListView.builder/GridView.builder) luôn tách thành 1 widget riêng + file riêng (VD: product_card.dart), không viết inline trong itemBuilder.
Giới hạn độ lồng nhau: nếu 1 cây widget lồng quá ~4 cấp (Column > Row > Column > Row...) thì đó là dấu hiệu cần tách thêm 1 file widget con nữa, không cố nhồi vào 1 file.
Dùng const constructor cho widget con bất cứ khi nào có thể (không phụ thuộc state/callback động) để tối ưu rebuild.
Nếu 1 widget con trong feature sau này thấy lặp lại ở ≥2 màn hình khác → move file đó lên core/widgets/ thay vì copy-paste (xem mục 5).
Nếu Antigravity code xong mà 1 file xxx_screen.dart vẫn còn > 150-200 dòng, yêu cầu nó tách tiếp thành widget/file con thay vì để nguyên.
7. Mock Data
Model riêng trong data/models/ (class thuần Dart, có fromJson/toJson sẵn dù chưa dùng API để sau này thay bằng thật dễ dàng).
Mock data để riêng data/mock/xxx_mock.dart, dạng static List<...> hoặc static method.
Đặt tên rõ nghĩa: mockUserList, mockProductList.
Không hardcode data thẳng trong widget UI.
8. Đặt tên & tổ chức file
File: snake_case.dart. Class: PascalCase.
1 file = 1 widget/class chính. Widget UI quá ~150-200 dòng thì tách nhỏ (xem mục 6).
Không magic number/string — đưa vào constants.
9. Responsive
Ưu tiên Expanded/Flexible/LayoutBuilder/MediaQuery thay vì width/height cố định toàn màn hình.
Nếu ảnh thiết kế có tỉ lệ cố định (Figma export) và cần bám sát pixel, có thể dùng flutter_screenutil để scale theo design size.
10. State (giai đoạn làm mock UI)
Giai đoạn này ưu tiên StatefulWidget + setState đơn giản, chưa cần gắn state management phức tạp — refactor sang Bloc/Riverpod/Provider sau khi UI chốt và có API thật.
11. Điều hướng (Navigation) — go_router
Dùng go_router cho toàn bộ điều hướng, không dùng Navigator.push(MaterialPageRoute(...)) trực tiếp rải rác trong widget.
Khai báo router tập trung 1 chỗ: core/router/app_router.dart (file GoRouter chính), không khai báo route lẻ tẻ trong từng feature.
Đường dẫn route (path) và tên route để hằng số riêng, không hardcode string path khi navigate: core/router/app_routes.dart — VD: AppRoutes.home = '/home', AppRoutes.productDetail = '/product/:id'. Khi cần điều hướng thì dùng context.push(AppRoutes.home) / context.goNamed(AppRoutes.homeName), không gõ tay '/home' ở nơi gọi.
Mỗi feature có 1 khối route riêng (list GoRoute) định nghĩa trong file route của chính feature đó (VD: features/product/presentation/product_routes.dart), sau đó gom lại (routes: [...appProductRoutes, ...appHomeRoutes]) trong app_router.dart — tránh 1 file router phình to chứa hết mọi feature.
Dùng context.push() khi muốn giữ lại màn cũ trong stack (có thể back về), dùng context.go() khi muốn thay thế toàn bộ stack (VD: sau khi login xong chuyển qua Home). Không dùng lẫn lộn tuỳ tiện.
Truyền dữ liệu giữa các màn qua extra (object) hoặc path/query params (:id, ?type=) tuỳ dữ liệu đơn giản hay phức tạp — không dùng biến global để truyền data giữa 2 màn.
Nếu có luồng cần bottom navigation bar (nhiều tab), dùng StatefulShellRoute của go_router thay vì tự dựng IndexedStack + logic điều hướng thủ công.
Nếu có luồng cần chặn/redirect (VD: chưa login thì đá về /login), viết trong redirect của GoRouter/GoRoute, không check điều kiện điều hướng rải rác trong từng screen.
Ở giai đoạn mock UI, nếu 1 số route chưa có màn thật, tạo screen tạm (placeholder) và vẫn khai theo cấu trúc route ở trên — không tạm dùng Navigator.push "cho nhanh" rồi quên sửa lại.
12. Asset & Icon
Icon custom để assets/icons/, khai báo qua AppIcons (constant path), không hardcode string path trong widget.
Ảnh mock để assets/images/, đặt tên rõ nghĩa theo màn hình/mục đích.