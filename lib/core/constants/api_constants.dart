class ApiConstants {
  // ── Base URLs ─────────────────────────────────────────────────────────────
  // Using the machine's specific local IPv4 address so that a physical
  // device on the same Wi-Fi/Network can connect to XAMPP.

  // Candidate API  (general /api)
  static const String baseUrl =
      'http://10.32.221.26/ai-job-portal/public/api';

  // Recruiter mobile API  (/api/mobile)
  static const String recruiterBaseUrl =
      'http://10.32.221.26/ai-job-portal/public/api/mobile';

  // Live URLs — uncomment and comment out the local ones above to switch:
  // static const String baseUrl          = 'https://hirematrix.serphawk.in/api';
  // static const String recruiterBaseUrl = 'https://hirematrix.serphawk.in/api/mobile';

  // ── Image URL resolver ────────────────────────────────────────────────────

  static String resolveImageUrl(String path) {
    var trimmed = path.trim();
    if (trimmed.isEmpty) return '';

    // Extract target authority/host from baseUrl
    String targetAuthority = 'localhost';
    try {
      final uri = Uri.parse(baseUrl);
      targetAuthority = uri.authority;
    } catch (_) {}

    if (trimmed.contains('localhost')) {
      trimmed = trimmed.replaceAll('localhost', targetAuthority);
    } else if (trimmed.contains('127.0.0.1')) {
      trimmed = trimmed.replaceAll('127.0.0.1', targetAuthority);
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    final base = baseUrl.replaceAll('/api', '');
    return '$base/$cleanPath';
  }

  // ── Candidate endpoints ───────────────────────────────────────────────────

  static const String companyDiscovery = 'company-discovery';
  static const String premiumMentorChat = 'premium-mentor/chat';

  // ── Recruiter mobile endpoints ────────────────────────────────────────────

  static const String login = 'login';
  static const String signup = 'signup';
  static const String onboarding = 'onboarding';
  static const String dashboard = 'dashboard';
  static const String jobs = 'jobs';
  static const String applications = 'applications';
  static const String candidates = 'candidates';
  static const String inviteCandidate = 'candidates/invite';
  static const String interviews = 'interviews';
  static const String interviewSlots = 'interview_slots';
  static const String interviewBookings = 'interview_bookings';
  static const String notifications = 'notifications';
  static const String profile = 'profile';
  static const String company = 'company';
  static const String team = 'team';
  static const String verification = 'verification';
  static const String session = 'validate_session';
  static const String forgotPassword = 'forgot_password';
  static const String resetPassword = 'reset_password';
  static const String resendVerification = 'resend_verification';
  static const String supportChat = 'support/chat';
  static const String leaderboard = 'dashboard/leaderboard';
  static const String updateJobStatus = 'jobs/update-status';
  static const String exportJobsReport = 'export-jobs-report';

  // ── Chatbot endpoints (shared by candidate & recruiter) ───────────────────

  static const String chatbotAsk = 'chatbot/ask';
  static const String chatbotSuggestions = 'chatbot/suggestions';
  static const String chatbotBrief = 'chatbot/brief';

  // ── Resdex endpoints ──────────────────────────────────────────────────────

  static const String resdexSearch = 'resdex/search';
  static const String resdexCandidate = 'resdex/candidate'; // + /id
  static const String resdexFolders = 'resdex/folders';
  static const String resdexCreateFolder = 'resdex/folders/create';
  static const String resdexDeleteFolders = 'resdex/folders/delete';
  static const String resdexAddToFolder = 'resdex/folders/add';
  static const String resdexBulkAddToFolder = 'resdex/folders/bulk-add';
  static const String resdexRemoveFromFolder = 'resdex/folders/remove';
  static const String resdexSearches = 'resdex/searches';
  static const String resdexSaveSearch = 'resdex/searches/save';
  static const String resdexDeleteSearches = 'resdex/searches/delete';
  static const String resdexBulkInvite = 'candidates/bulk_invite';
}
