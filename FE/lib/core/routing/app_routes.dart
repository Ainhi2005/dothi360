class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/';
  static const discover = '/discover';
  static const history = '/history';
  static const account = '/account';
  static const createReport = '/create-report';
  static const reportLocation = '/create-report/location';
  static const confirmReport = '/confirm-report';
  static const resolvedIncidents = '/incidents/resolved';
  static const incidentDetail = '/incidents/:id';
  static const personalInfo = '/account/personal-info';
  static const changePassword = '/account/change-password';
  static const guide = '/account/guide';
  static const emergencyGuideDetail = '/account/guide/:id';
  static const emergencyContacts = '/emergency-contacts';
  static const interestedAreas = '/interested-areas';
  static const interestedAreaDetail = '/interested-areas/:id';
  static const feedbacks = '/feedbacks';
  static const createFeedback = '/feedbacks/create';
  static const floodPoints = '/utilities/flood-points';
  static const departments = '/utilities/departments';
  static const weatherAqi = '/utilities/weather-aqi';
  static const privacy = '/account/privacy';
  static const contact = '/account/contact';
  static const notifications = '/notifications';
  static const chat = '/ai-assistant';
  static const officerWork = '/officer/work';
  static const officerOverview = '/officer/overview';
  static const officerHistory = '/officer/history';
  static const officerMap = '/officer/map';
  static const officerAccount = '/officer/account';
  static const officerAssignment = '/officer/assignments/:id';
  static const officerUpdate = '/officer/incidents/:id/update';
  static const officerPerformance = '/officer/performance';

  static String incidentDetailPath(String id) => '/incidents/$id';
  static String officerAssignmentPath(String id) => '/officer/assignments/$id';
  static String officerUpdatePath(String id) => '/officer/incidents/$id/update';
  static String emergencyGuidePath(String id) => '/account/guide/$id';
  static String interestedAreaDetailPath(String id) => '/interested-areas/$id';

  const AppRoutes._();
}
