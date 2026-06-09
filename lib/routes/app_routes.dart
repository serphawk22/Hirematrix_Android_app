import 'package:get/get.dart';
import 'package:hirematrix/views/screens/candidate/features_screen.dart';
import 'package:hirematrix/views/screens/landing_screen.dart';
import 'package:hirematrix/views/screens/candidate/dashboard_screen.dart';
import 'package:hirematrix/views/screens/login_screen.dart';
import 'package:hirematrix/views/screens/candidate/candidate_register_screen.dart'
    show RegisterScreen;
import 'package:hirematrix/views/screens/recruiter/recruiter_register_screen.dart';
import 'package:hirematrix/views/screens/candidate/onboarding_screen.dart';
import 'package:hirematrix/views/screens/candidate/smart_jobs_screen.dart';
import 'package:hirematrix/views/screens/candidate/job_search_strategy_screen.dart';
import 'package:hirematrix/views/screens/candidate/plans_screen.dart';
import 'package:hirematrix/views/screens/candidate/local_companies_screen.dart';
import 'package:hirematrix/views/screens/candidate/forgot_password_screen.dart';
import 'package:hirematrix/views/screens/candidate/reset_password_screen.dart';
import 'package:hirematrix/views/screens/candidate/career_transition_screen.dart';
import 'package:hirematrix/views/screens/candidate/resume_studio_screen.dart';
import 'package:hirematrix/views/screens/candidate/premium_mentor_screen.dart';
import 'package:hirematrix/views/screens/candidate/notification_screen.dart';
import 'package:hirematrix/views/screens/candidate/messages_screen.dart';

class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String recruiterRegister = '/recruiter/register';
  static const String jobs = '/jobs';
  static const String careerTransition = '/career-transition';
  static const String features = '/features';
  static const String dashboard = '/candidate/dashboard';
  static const String onboarding = '/candidate/onboarding';
  static const String jobSearchStrategy = '/candidate/job-search-strategy';
  static const String plans = '/premium/plans';
  static const String localCompanies = '/localcompany';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String resumeStudio = '/candidate/resume-studio';
  static const String premiumMentor = '/candidate/premium-mentor';
  static const String notifications = '/candidate/notifications';
  static const String messages = '/candidate/messages';

  static List<GetPage> pages = [
    GetPage(
      name: landing,
      page: () => const LandingScreen(),
      transition: Transition.fade,
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: register,
      page: () => const RegisterScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: recruiterRegister,
      page: () => const RecruiterRegisterScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: dashboard,
      page: () => const DashboardScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: jobs,
      page: () => const SmartJobsScreen(showBackButton: true),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: features,
      page: () => const FeaturesScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: jobSearchStrategy,
      page: () => const JobSearchStrategyScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: plans,
      page: () => const PlansScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: localCompanies,
      page: () => const LocalCompaniesScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: resetPassword,
      page: () => const ResetPasswordScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: careerTransition,
      page: () => const CareerTransitionScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: resumeStudio,
      page: () => const ResumeStudioScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: premiumMentor,
      page: () => const PremiumMentorScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: notifications,
      page: () => const NotificationScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: messages,
      page: () => const MessagesScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}
