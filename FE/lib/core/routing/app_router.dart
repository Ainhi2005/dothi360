import 'package:go_router/go_router.dart';
import '../../features/main/presentation/pages/main_layout.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/users/presentation/pages/personal_info_page.dart';
import '../../features/users/presentation/pages/guide_page.dart';
import '../../features/emergency_guides/presentation/pages/emergency_guide_detail_page.dart';
import '../../features/emergency_contacts/presentation/pages/emergency_contacts_page.dart';
import '../../features/users/presentation/pages/privacy_policy_page.dart';
import '../../features/users/presentation/pages/contact_support_page.dart';
import '../../features/incidents/presentation/pages/create_report_page.dart';
import '../../features/incidents/presentation/pages/incident_location_picker_page.dart';
import '../../features/incidents/data/models/incident_location_selection.dart';
import '../../features/incidents/presentation/pages/confirm_report_page.dart';
import '../../features/incidents/presentation/pages/history_page.dart';
import '../../features/incidents/presentation/pages/resolved_incidents_page.dart';
import '../../features/incidents/presentation/pages/incident_detail_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/main/presentation/pages/discover_page.dart';
import '../../features/users/presentation/pages/account_page.dart';
import '../../features/users/presentation/pages/notifications_page.dart';
import '../../features/officer/data/models/officer_assignment_model.dart';
import '../../features/officer/presentation/pages/officer_assignment_detail_page.dart';
import '../../features/officer/presentation/pages/officer_history_page.dart';
import '../../features/officer/presentation/pages/officer_layout.dart';
import '../../features/officer/presentation/pages/officer_update_status_page.dart';
import '../../features/officer/presentation/pages/officer_work_page.dart';
import '../../features/officer/presentation/pages/officer_account_page.dart';
import '../../features/officer/presentation/pages/officer_map_page.dart';
import '../../features/officer/presentation/pages/officer_overview_page.dart';
import '../../features/officer/presentation/pages/officer_performance_page.dart';
import 'app_routes.dart';
import '../utils/token_storage.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/interested_areas/presentation/pages/interested_areas_page.dart';
import '../../features/interested_areas/presentation/pages/interested_area_detail_page.dart';
import '../../features/feedback/presentation/pages/feedbacks_page.dart';
import '../../features/feedback/presentation/pages/create_feedback_page.dart';
import '../../features/utilities/presentation/pages/flood_points_page.dart';
import '../../features/utilities/presentation/pages/weather_aqi_page.dart';
import '../../features/utilities/presentation/pages/departments_directory_page.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  refreshListenable: TokenStorage(),
  redirect: (context, state) async {
    final token = await TokenStorage().getToken();
    final role = await TokenStorage().getRole();
    final isLoggedIn = token != null && token.isNotEmpty;
    if (isLoggedIn && await TokenStorage().passwordChangeRequired()) {
      return state.matchedLocation == AppRoutes.changePassword
          ? null
          : AppRoutes.changePassword;
    }

    final isAuthRoute = state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register ||
        state.matchedLocation == AppRoutes.forgotPassword;

    // 1. Nếu đã đăng nhập mà vào trang Login/Register -> Chuyển thẳng vào app
    if (isLoggedIn && isAuthRoute) {
      return role == 'OFFICER' ? AppRoutes.officerOverview : AppRoutes.home;
    }

    // 2. Nếu chưa đăng nhập mà vào các trang nội bộ -> Đẩy ra Login
    if (!isLoggedIn &&
        !isAuthRoute &&
        state.matchedLocation != AppRoutes.privacy) {
      return AppRoutes.login;
    }

    // 3. Phân quyền: Người dùng thường không được vào route của Cán bộ
    if (state.matchedLocation.startsWith('/officer') && role != 'OFFICER') {
      return AppRoutes.home;
    }

    return null; // Hợp lệ, cho phép đi tiếp
  },
  routes: [
    GoRoute(
      path: AppRoutes.createReport,
      builder: (context, state) => const CreateReportPage(),
    ),
    GoRoute(
      path: AppRoutes.reportLocation,
      builder: (context, state) => IncidentLocationPickerPage(
        initial: state.extra is IncidentLocationSelection
            ? state.extra as IncidentLocationSelection
            : null,
      ),
    ),
    GoRoute(
      path: AppRoutes.confirmReport,
      builder: (context, state) => const ConfirmReportPage(),
    ),
    GoRoute(
      path: AppRoutes.resolvedIncidents,
      builder: (context, state) => const ResolvedIncidentsPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainLayout(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomePage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: AppRoutes.discover,
              builder: (context, state) => const DiscoverPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: AppRoutes.history,
              builder: (context, state) => const HistoryPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: AppRoutes.account,
              builder: (context, state) => const AccountPage()),
        ]),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          OfficerLayout(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.officerOverview,
            builder: (context, state) => const OfficerOverviewPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.officerWork,
            builder: (context, state) => const OfficerWorkPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.officerMap,
            builder: (context, state) => const OfficerMapPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.officerAccount,
            builder: (context, state) => const OfficerAccountPage(),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: AppRoutes.officerAssignment,
      builder: (context, state) => OfficerAssignmentDetailPage(
        assignmentId: state.pathParameters['id']!,
        initialAssignment: state.extra is OfficerAssignmentModel
            ? state.extra! as OfficerAssignmentModel
            : null,
      ),
    ),
    GoRoute(
      path: AppRoutes.officerUpdate,
      redirect: (context, state) =>
          state.extra is OfficerAssignmentModel ? null : AppRoutes.officerWork,
      builder: (context, state) => OfficerUpdateStatusPage(
        assignment: state.extra! as OfficerAssignmentModel,
      ),
    ),
    GoRoute(
        path: AppRoutes.officerHistory,
        builder: (context, state) => const OfficerHistoryPage()),
    GoRoute(
        path: AppRoutes.officerPerformance,
        builder: (context, state) => const OfficerPerformancePage()),
    GoRoute(
      path: AppRoutes.incidentDetail,
      builder: (context, state) =>
          IncidentDetailPage(incidentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) => const ChatPage(),
    ),
    GoRoute(
      path: AppRoutes.personalInfo,
      builder: (context, state) => const PersonalInfoPage(),
    ),
    GoRoute(
      path: AppRoutes.changePassword,
      builder: (context, state) => const ChangePasswordPage(),
    ),
    GoRoute(
      path: AppRoutes.guide,
      builder: (context, state) => const GuidePage(),
    ),
    GoRoute(
      path: AppRoutes.emergencyGuideDetail,
      builder: (context, state) => EmergencyGuideDetailPage(
        guideId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: AppRoutes.privacy,
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
    GoRoute(
      path: AppRoutes.contact,
      builder: (context, state) => const ContactSupportPage(),
    ),
    GoRoute(
      path: AppRoutes.emergencyContacts,
      builder: (context, state) => const EmergencyContactsPage(),
    ),
    GoRoute(
      path: AppRoutes.interestedAreas,
      builder: (context, state) => const InterestedAreasPage(),
    ),
    GoRoute(
      path: AppRoutes.interestedAreaDetail,
      builder: (context, state) => InterestedAreaDetailPage(
        id: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: AppRoutes.feedbacks,
      builder: (context, state) => const FeedbacksPage(),
    ),
    GoRoute(
      path: AppRoutes.createFeedback,
      builder: (context, state) => const CreateFeedbackPage(),
    ),
    GoRoute(
      path: AppRoutes.floodPoints,
      builder: (context, state) => const FloodPointsPage(),
    ),
    GoRoute(
      path: AppRoutes.weatherAqi,
      builder: (context, state) => const WeatherAqiPage(),
    ),
    GoRoute(
      path: AppRoutes.departments,
      builder: (context, state) => const DepartmentsDirectoryPage(),
    ),
  ],
);
