class ApiConstants {
  // Local network testing setup (Uncomment to use local backend)
  static const String baseUrl =
      "http://10.32.221.26/ai-job-portal/public/api/mobile";

  // Live Backend URL (Comment this out if using local backend)
  // static const String baseUrl = "https://hirematrix.serphawk.in/api/mobile";

  // Mobile Endpoints
  static const String login = "login";
  static const String signup = "signup";
  static const String onboarding = "onboarding";
  static const String dashboard = "dashboard";
  static const String jobs = "jobs";
  static const String applications = "applications";
  static const String candidates = "candidates";
  static const String inviteCandidate = "candidates/invite";
  static const String interviews = "interviews";
  static const String interviewSlots = "interview_slots";
  static const String interviewBookings = "interview_bookings";
  static const String notifications = "notifications";
  static const String profile = "profile";
  static const String company = "company";
  static const String team = "team";
  static const String verification = "verification";
  static const String session = "validate_session";
  static const String forgotPassword = "forgot_password";
  static const String resetPassword = "reset_password";
  static const String resendVerification = "resend_verification";
  static const String supportChat = "support/chat";
  static const String leaderboard = "dashboard/leaderboard";
  static const String updateJobStatus = "jobs/update-status";
  static const String chatbotAsk = "chatbot/ask";
  static const String chatbotSuggestions = "chatbot/suggestions";
  static const String chatbotBrief = "chatbot/brief";
  static const String exportJobsReport = "export-jobs-report";

  // Resdex Endpoints
  static const String resdexSearch = "resdex/search";
  static const String resdexCandidate = "resdex/candidate"; // + /id
  static const String resdexFolders = "resdex/folders";
  static const String resdexCreateFolder = "resdex/folders/create";
  static const String resdexDeleteFolders = "resdex/folders/delete";
  static const String resdexAddToFolder = "resdex/folders/add";
  static const String resdexBulkAddToFolder = "resdex/folders/bulk-add";
  static const String resdexRemoveFromFolder = "resdex/folders/remove";
  static const String resdexSearches = "resdex/searches";
  static const String resdexSaveSearch = "resdex/searches/save";
  static const String resdexDeleteSearches = "resdex/searches/delete";
  static const String resdexBulkInvite = "candidates/bulk_invite";
}
