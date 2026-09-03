import 'package:staynest_mobile/features/ai/presentation/ai_chat_screen.dart';
import 'package:staynest_mobile/features/messaging/presentation/messages_screen.dart';
import 'package:staynest_mobile/features/messaging/presentation/chat_thread_screen.dart';
// app/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── Auth ────────────────────────────────────────────
import 'package:staynest_mobile/features/auth/presentation/splash_screen.dart';
import 'package:staynest_mobile/features/auth/presentation/onboarding_screen.dart';
import 'package:staynest_mobile/features/auth/presentation/welcome_screen.dart';
import 'package:staynest_mobile/features/auth/presentation/register_screen.dart';
import 'package:staynest_mobile/features/auth/presentation/login_screen.dart';
import 'package:staynest_mobile/features/auth/presentation/phone_otp_screen.dart';
import 'package:staynest_mobile/features/auth/presentation/email_verification_screen.dart';
import 'package:staynest_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:staynest_mobile/features/auth/presentation/complete_profile_screen.dart';
import 'package:staynest_mobile/features/auth/presentation/owner_login_screen.dart';

// ── Student ─────────────────────────────────────────
import 'package:staynest_mobile/features/discovery/presentation/student_shell.dart';
import 'package:staynest_mobile/features/discovery/presentation/home_screen.dart';
import 'package:staynest_mobile/features/discovery/presentation/search_results_screen.dart';
import 'package:staynest_mobile/features/discovery/presentation/hostel_details_screen.dart';
import 'package:staynest_mobile/features/discovery/presentation/gallery_screen.dart';
import 'package:staynest_mobile/features/discovery/presentation/room_details_screen.dart';
import 'package:staynest_mobile/features/discovery/presentation/explore_screen.dart';
import 'package:staynest_mobile/features/discovery/presentation/saved_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/select_bed_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/booking_review_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/bed_taken_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/booking_confirmation_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/booking_detail_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/digital_agreement_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/qr_checkin_screen.dart';
import 'package:staynest_mobile/features/payment/presentation/payment_history_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/refund_timeline_screen.dart';
import 'package:staynest_mobile/features/discovery/presentation/search_history_screen.dart';
import 'package:staynest_mobile/features/discovery/presentation/compare_hostels_screen.dart';
import 'package:staynest_mobile/features/discovery/presentation/recently_viewed_screen.dart';
import 'package:staynest_mobile/features/stays/presentation/move_in_schedule_screen.dart';
import 'package:staynest_mobile/features/payment/presentation/utility_bills_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/report_issue_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/installment_schedule_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/visitors_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/visitor_pass_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/community_board_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/announcements_screen.dart';
import 'package:staynest_mobile/features/booking/presentation/reviews_screen.dart';
import 'package:staynest_mobile/features/payment/presentation/payment_webview_screen.dart';
import 'package:staynest_mobile/features/stays/presentation/my_stays_screen.dart';
import 'package:staynest_mobile/features/account/presentation/notifications_screen.dart';
import 'package:staynest_mobile/features/account/presentation/settings_screen.dart';
import 'package:staynest_mobile/features/account/presentation/profile_screen.dart';
import 'package:staynest_mobile/features/account/presentation/edit_profile_screen.dart';

// ── Owner ───────────────────────────────────────────
import 'package:staynest_mobile/features/owner/presentation/owner_shell.dart';
import 'package:staynest_mobile/features/owner/presentation/owner_dashboard_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/manage_hostels_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/tenant_management_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/booking_requests_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/owner_settings_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/room_management_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/bed_management_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/add_hostel_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/payment_tracking_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/owner_messages_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/owner_profile_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/revenue_reports_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/staff_management_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/staff_attendance_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/maintenance_dashboard_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/ai_insights_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/security_center_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/revenue_reports_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/staff_management_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/staff_attendance_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/maintenance_dashboard_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/ai_insights_screen.dart';
import 'package:staynest_mobile/features/owner/presentation/security_center_screen.dart';

// ── Dev ─────────────────────────────────────────────
import 'package:staynest_mobile/features/gallery/component_gallery.dart';

/// Route path constants.
abstract class Routes {
  // Auth
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const register = '/register';
  static const login = '/login';
  static const phoneOtp = '/phone-otp';
  static const emailVerification = '/email-verification';
  static const forgotPassword = '/forgot-password';
  static const completeProfile = '/complete-profile';
  static const ownerLogin = '/owner-login';

  // Student shell tabs
  static const home = '/home';
  static const explore = '/explore';
  static const myStays = '/my-stays';
  static const saved = '/saved';
  static const profile = '/profile';

  // Discovery (relative — pushed in Home branch)
  static const searchResults = 'search-results';
  static const hostelDetails = 'hostel/:id';
  static const gallery = 'hostel/:id/gallery';
  static const roomDetails = 'room/:id';
  static const selectBed = 'select-bed';

  // Owner
  static const ownerDashboard = '/owner';
  static const ownerRequests = '/owner/requests';
  static const ownerRevenue = '/owner/revenue';
  static const ownerStaff = '/owner/staff';
  static const ownerAttendance = '/owner/attendance';
  static const ownerMaintenance = '/owner/maintenance';
  static const ownerInsights = '/owner/insights';
  static const ownerSecurity = '/owner/security';
  static const ownerProfile = '/owner/profile';

  // Standalone
  static const bookingConfirmation = '/booking-confirmation';
  static const bedTaken = '/bed-taken';
  static const digitalAgreement = '/digital-agreement';
  static const qrCheckin = '/qr-checkin';
  static const paymentHistory = '/payment-history';
  static const refundTimeline = '/refund-timeline';
  static const searchHistory = '/profile/search-history';
  static const compareHostels = '/compare-hostels';
  static const recentlyViewed = '/recently-viewed';
  static const moveInSchedule = '/move-in-schedule';
  static const utilityBills = '/utility-bills';
  static const installmentSchedule = '/installment-schedule';
  static const visitors = '/visitors';
  static const visitorPass = '/visitor-pass';
  static const communityBoard = '/community-board';
  static const announcements = '/announcements';
  static const reviews = '/reviews';
  static const reportIssue = '/report-issue';
  static const notifications = '/notifications';
  static const aiChat = '/ai-chat';
  static const messages = '/messages';
  static const chatThread = '/messages/:id';
  static const settings = '/settings';
  static const gallery_ = '/dev/gallery';
}

// ── Navigator keys ──────────────────────────────────
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _exploreNavKey = GlobalKey<NavigatorState>(debugLabel: 'explore');
final _staysNavKey = GlobalKey<NavigatorState>(debugLabel: 'stays');
final _savedNavKey = GlobalKey<NavigatorState>(debugLabel: 'saved');
final _profileNavKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.splash,
  routes: [
    // ── Auth flow ───────────────────────────────────
    GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: Routes.welcome, builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: Routes.register, builder: (_, __) => const RegisterScreen()),
    GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
    GoRoute(path: Routes.phoneOtp, builder: (_, __) => const PhoneOtpScreen()),
    GoRoute(path: Routes.emailVerification, builder: (_, __) => const EmailVerificationScreen()),
    GoRoute(path: Routes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: Routes.completeProfile, builder: (_, __) => const CompleteProfileScreen()),
    GoRoute(path: Routes.ownerLogin, builder: (_, __) => const OwnerLoginScreen()),
    GoRoute(path: Routes.aiChat, builder: (context, state) => AiChatScreen(initialPrompt: state.uri.queryParameters['q'])),
    GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
    GoRoute(path: '/messages/:id', builder: (context, state) {
      final extra = state.extra;
      final hostelName = extra is Map ? extra['hostelName'] as String? : extra as String?;
      final userId = extra is Map ? extra['userId'] as String? : null;
      return ChatThreadScreen(
        conversationId: state.pathParameters['id']!,
        hostelName: hostelName,
        currentUserId: userId,
      );
    }),

    // ── Student shell (tabbed) ──────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return StudentShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _homeNavKey,
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, __) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: Routes.searchResults,
                  builder: (context, state) => SearchResultsScreen(
                    query: state.uri.queryParameters['q'],
                  ),
                ),
                GoRoute(
                  path: Routes.hostelDetails,
                  builder: (context, state) => HostelDetailsScreen(
                    hostelId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'gallery',
                      builder: (context, state) => GalleryScreen(imageUrls: state.extra as List<String>? ?? [],
                        hostelId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: Routes.roomDetails,
                  builder: (context, state) => RoomDetailsScreen(
                    roomId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: Routes.selectBed,
                      builder: (context, state) => SelectBedScreen(
                        roomId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _exploreNavKey,
          routes: [
            GoRoute(path: Routes.explore, builder: (_, __) => const ExploreScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _staysNavKey,
          routes: [
            GoRoute(path: Routes.myStays, builder: (_, __) => const MyStaysScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _savedNavKey,
          routes: [
            GoRoute(path: Routes.saved, builder: (_, __) => const SavedScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _profileNavKey,
          routes: [
            GoRoute(
              path: Routes.profile,
              builder: (_, __) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'search-history', builder: (_, __) => const SearchHistoryScreen()),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── Owner shell (tabbed) ────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return OwnerShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: Routes.ownerDashboard, builder: (_, __) => const OwnerDashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/owner/hostels', builder: (_, __) => const ManageHostelsScreen()),
          GoRoute(path: '/owner/hostels/add', builder: (_, __) => const AddHostelScreen()),
          GoRoute(
            path: '/owner/hostels/:hostelId/edit',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AddHostelScreen(
                hostelId: state.pathParameters['hostelId'],
                initialData: extra,
              );
            },
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/owner/messages', builder: (_, __) => const OwnerMessagesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/owner/tenants', builder: (_, __) => const TenantManagementScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/owner/settings', builder: (_, __) => const OwnerSettingsScreen()),
          GoRoute(
            path: '/owner/hostels/:hostelId/rooms',
            builder: (_, state) => RoomManagementScreen(
              hostelId: state.pathParameters['hostelId']!,
              hostelName: state.uri.queryParameters['name'] ?? 'Rooms',
            ),
          ),
          GoRoute(
            path: '/owner/rooms/:roomId/beds',
            builder: (_, state) => BedManagementScreen(
              roomId: state.pathParameters['roomId']!,
              hostelId: state.uri.queryParameters['hostelId'] ?? '',
            ),
          ),
        ]),
      ],
    ),

    // ── Owner standalone screens (pushed over shell) ─
    GoRoute(
      path: Routes.ownerRequests,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const BookingRequestsScreen(),
    ),
    GoRoute(path: Routes.ownerRevenue, parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const RevenueReportsScreen()),
    GoRoute(path: Routes.ownerStaff, parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const StaffManagementScreen()),
    GoRoute(path: Routes.ownerAttendance, parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const StaffAttendanceScreen()),
    GoRoute(path: Routes.ownerMaintenance, parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const MaintenanceDashboardScreen()),
    GoRoute(path: Routes.ownerInsights, parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const AIInsightsScreen()),
    GoRoute(path: Routes.ownerSecurity, parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const SecurityCenterScreen()),
    GoRoute(path: Routes.ownerProfile, parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const OwnerProfileScreen()),
    GoRoute(
      path: '/owner/reports',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const PaymentTrackingScreen(),
    ),

    // ── Standalone routes ───────────────────────────
    GoRoute(
      path: '/booking-review',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BookingReviewScreen(
          bedId: extra['bedId'] as String,
          bedLabel: extra['bedLabel'] as String,
          roomNumber: extra['roomNumber'] as String,
          roomType: extra['roomType'] as String,
          pricePesewas: extra['pricePesewas'] as int,
          hostelName: extra['hostelName'],
          securityDepositPesewas: extra['securityDepositPesewas'] as int? ?? 0,
          hostelId: extra['hostelId'] as String?,
          roomId: extra['roomId'] as String?,
          bookingMode: extra['bookingMode'] as String? ?? 'FLEXIBLE',
          semesterPricePesewas: extra['semesterPricePesewas'] as int?,
          hostelImageUrl: extra['hostelImageUrl'] as String?,
        );
      },
    ),
    GoRoute(
      path: Routes.bookingConfirmation,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return BookingConfirmationScreen(
          reference: extra['reference'] as String? ?? '',
          hostelName: extra['hostelName'] as String? ?? '',
          roomLabel: extra['roomLabel'] as String? ?? '',
          bedLabel: extra['bedLabel'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: Routes.digitalAgreement,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return DigitalAgreementScreen(
          bookingId: extra['bookingId'] as String? ?? '',
          bookingReference: extra['bookingReference'] as String? ?? '',
          hostelName: extra['hostelName'] as String? ?? '',
          roomLabel: extra['roomLabel'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: Routes.qrCheckin,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return QrCheckinScreen(
          bookingReference: extra['bookingReference'] as String? ?? '',
          hostelName: extra['hostelName'] as String? ?? '',
          roomId: extra['roomId'] as String? ?? '',
          validUntil: extra['validUntil'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: Routes.reportIssue,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ReportIssueScreen(bookingId: extra['bookingId'] as String? ?? '');
      },
    ),
    GoRoute(path: Routes.paymentHistory, builder: (_, __) => const PaymentHistoryScreen()),
    GoRoute(path: Routes.compareHostels, builder: (context, state) {
      final ids = (state.extra as List<String>?) ?? state.uri.queryParameters['ids']?.split(',') ?? [];
      return CompareHostelsScreen(hostelIds: ids);
    }),
    GoRoute(path: Routes.recentlyViewed, builder: (_, __) => const RecentlyViewedScreen()),
    GoRoute(path: Routes.moveInSchedule, builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      return MoveInScheduleScreen(
        bookingId: extra['bookingId'] as String? ?? '',
        moveInDate: extra['moveInDate'] as DateTime?,
        hostelName: extra['hostelName'] as String?,
      );
    }),
    GoRoute(path: Routes.utilityBills, builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return UtilityBillsScreen(bookingId: extra?['bookingId'] as String?);
    }),
    GoRoute(path: Routes.refundTimeline, builder: (context, state) {
      final bookingId = state.uri.queryParameters['bookingId'] ?? '';
      return RefundTimelineScreen(bookingId: bookingId);
    }),
    GoRoute(path: Routes.installmentSchedule, builder: (_, state) {
      final extra = state.extra as Map<String, dynamic>;
      return InstallmentScheduleScreen(
        bookingId: extra['bookingId'] as String,
        hostelName: extra['hostelName'] as String,
        roomLabel: extra['roomLabel'] as String,
      );
    }),
    GoRoute(path: Routes.visitors, builder: (_, state) {
      final extra = state.extra as Map<String, dynamic>;
      return VisitorsScreen(
        bookingId: extra['bookingId'] as String,
        hostelName: extra['hostelName'] as String,
      );
    }),
    GoRoute(path: Routes.visitorPass, builder: (_, state) {
      final extra = state.extra as Map<String, dynamic>;
      return VisitorPassScreen(
        visitorName: extra['visitorName'] as String,
        hostelName: extra['hostelName'] as String,
        qrToken: extra['qrToken'] as String,
        validUntil: extra['validUntil'] as String,
        purpose: extra['purpose'] as String? ?? '',
        visitorPhone: extra['visitorPhone'] as String? ?? '',
      );
    }),

    GoRoute(path: Routes.communityBoard, builder: (_, state) {
      final extra = state.extra as Map<String, dynamic>;
      return CommunityBoardScreen(
        hostelId: extra['hostelId'] as String,
        hostelName: extra['hostelName'] as String,
      );
    }), 
    GoRoute(path: Routes.announcements, builder: (_, state) {
      final extra = state.extra as Map<String, dynamic>;
      return AnnouncementsScreen(
        hostelId: extra['hostelId'] as String,
        hostelName: extra['hostelName'] as String,
      );
    }), 
    GoRoute(path: Routes.reviews, builder: (_, state) {
      final extra = state.extra as Map<String, dynamic>;
      return ReviewsScreen(
        hostelId: extra['hostelId'] as String,
        hostelName: extra['hostelName'] as String,
        bookingId: extra['bookingId'] as String?,
      );
    }),  GoRoute(path: Routes.notifications, builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: Routes.settings, builder: (_, __) => const SettingsScreen()),
    GoRoute(path: "/edit-profile", builder: (_, __) => const EditProfileScreen()),
    GoRoute(
      path: Routes.bedTaken,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return BedTakenScreen(roomId: extra['roomId'] as String?, hostelId: extra['hostelId'] as String?);
      },
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return PaymentWebViewScreen(
          authorizationUrl: extra['authorizationUrl'] as String,
          reference: extra['reference'] as String,
          bookingId: extra['bookingId'] as String,
          hostelName: extra['hostelName'] as String? ?? '',
          roomLabel: extra['roomLabel'] as String? ?? '',
          bedLabel: extra['bedLabel'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/hostel/:id',
      builder: (context, state) => HostelDetailsScreen(
        hostelId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/hostel/:id',
      builder: (context, state) => HostelDetailsScreen(
        hostelId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/booking/:id',
      builder: (context, state) => BookingDetailScreen(
        bookingId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(path: Routes.gallery_, builder: (_, __) => const ComponentGallery()),
  ],
);
