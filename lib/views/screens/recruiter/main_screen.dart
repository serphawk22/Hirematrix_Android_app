import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/views/screens/recruiter/drawer/company_details_screen.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/widgets/main_drawer.dart';
import 'utils/theme_provider.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/applications_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';

import 'dashboard/dashboard_screen.dart';
import 'candidates/candidate_management_screen.dart';

import 'jobs/manage_jobs_screen.dart';
import 'jobs/post_job_screen.dart';
import 'notifications/notifications_screen.dart';

import 'package:hirematrix/views/screens/recruiter/widgets/hirematrix_logo.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _screens = [
      DashboardScreen(onSwitchTab: switchTab),
      const ManageJobsScreen(),
      const CandidateManagementScreen(),
      const CompanyDetailsScreen(isStandalone: true),
    ];
  }

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
      _isSearching = false;
    });
    final auth = Provider.of<AuthController>(context, listen: false);
    final recruiterId = auth.currentRecruiter?.id;
    if (recruiterId != null) {
      if (index == 0) {
        Provider.of<DashboardController>(
          context,
          listen: false,
        ).fetchDashboard(recruiterId, auth: auth);
      } else if (index == 1) {
        Provider.of<JobsController>(
          context,
          listen: false,
        ).fetchJobs(recruiterId);
      } else if (index == 2) {
        Provider.of<ApplicationsController>(
          context,
          listen: false,
        ).fetchApplications(recruiterId);
      }
    }
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_isSearching) {
        _performSearch(_searchController.text);
      }
    });
  }

  void _performSearch(String query) {
    final auth = Provider.of<AuthController>(context, listen: false);
    final recruiterId = auth.currentRecruiter?.id;
    if (recruiterId == null) return;

    switch (_currentIndex) {
      case 1: // Jobs
        Provider.of<JobsController>(
          context,
          listen: false,
        ).fetchJobs(recruiterId, query: query);
        break;
      case 2: // Talent
        Provider.of<ApplicationsController>(
          context,
          listen: false,
        ).fetchApplications(recruiterId, query: query);
        break;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.getPrimary(isDarkMode);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: _buildDynamicAppBar(isDarkMode, themeProvider),
      drawer: const MainDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.bgCardDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[200]!,
              width: 1,
            ),
          ),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 66, // Increased slightly to prevent 1px overflow
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: switchTab,
              backgroundColor: Colors.transparent,
              selectedItemColor: primary,
              unselectedItemColor: isDarkMode
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.grey[400],
              selectedLabelStyle: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: [
                _buildNavItem(
                  Icons.home_outlined,
                  Icons.home_rounded,
                  'Home',
                  primary,
                ),
                _buildNavItem(
                  Icons.business_center_outlined,
                  Icons.business_center_rounded,
                  'Jobs',
                  primary,
                ),
                _buildNavItem(
                  Icons.people_outline_rounded,
                  Icons.people_rounded,
                  'Talent',
                  primary,
                ),
                _buildNavItem(
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Profile',
                  primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    Color primary,
  ) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 22),
      activeIcon: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(activeIcon, size: 22, color: primary),
      ),
      label: label,
    );
  }

  PreferredSizeWidget? _buildDynamicAppBar(
    bool isDark,
    ThemeProvider themeProvider,
  ) {
    if (_isSearching) {
      return AppBar(
        backgroundColor: isDark ? AppColors.bgDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => setState(() => _isSearching = false),
        ),
        titleSpacing: 0,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search workspace...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: Colors.grey,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      );
    }

    // Header logic based on index
    switch (_currentIndex) {
      case 0: // Home
        return _buildHomeHeader(isDark, themeProvider);
      case 1: // Jobs
        return _buildPageHeader(isDark, 'Jobs', [
          _buildHeaderActionButton(context, isDark, '+ Post Role', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PostJobScreen()),
            );
          }),
          const SizedBox(width: 16),
        ]);
      case 2: // Talent
        return _buildPageHeader(isDark, 'Talent', [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              final auth = Provider.of<AuthController>(context, listen: false);
              final recruiterId = auth.currentRecruiter?.id;
              if (recruiterId != null) {
                Provider.of<ApplicationsController>(
                  context,
                  listen: false,
                ).fetchApplications(recruiterId);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            onPressed: () {},
          ),
        ]);
      case 3: // Account
        return null;
      default:
        return _buildHomeHeader(isDark, themeProvider);
    }
  }

  PreferredSizeWidget _buildHomeHeader(
    bool isDark,
    ThemeProvider themeProvider,
  ) {
    return AppBar(
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, size: 22),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: const HireMatrixLogo(height: 32),
      actions: [
        IconButton(
          icon: Icon(Icons.file_download_outlined,
              color: isDark ? Colors.white70 : Colors.black87),
          tooltip: 'Export Overview',
          onPressed: () async {
            final auth = Provider.of<AuthController>(context, listen: false);
            final recruiterId = auth.currentRecruiter?.id;
            if (recruiterId != null) {
              await Permission.storage.request();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Downloading report...', style: TextStyle(fontSize: 16)),
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
              );

              try {
                final apiService = ApiService();
                final baseUrl = await apiService.getBaseUrl();
                final url = Uri.parse('$baseUrl/export/excel?recruiter_id=$recruiterId');
                
                final response = await http.get(url);
                if (response.statusCode == 200) {
                  Directory? directory;
                  if (Platform.isAndroid) {
                    directory = Directory('/storage/emulated/0/Download');
                    if (!await directory.exists()) {
                      directory = await getExternalStorageDirectory();
                    }
                  } else {
                    directory = await getApplicationDocumentsDirectory();
                  }

                  if (directory != null) {
                    final fileName = 'recruitment_overview_${DateTime.now().millisecondsSinceEpoch}.xlsx';
                    final file = File('${directory.path}/$fileName');
                    await file.writeAsBytes(response.bodyBytes);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Saved to Downloads', style: TextStyle(fontSize: 16)),
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10))),
                        action: SnackBarAction(
                          label: 'OPEN',
                          textColor: Colors.white,
                          backgroundColor: Theme.of(context).primaryColor,
                          onPressed: () {
                            OpenFile.open(file.path);
                          },
                        ),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Failed to download report', style: TextStyle(fontSize: 16)),
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Error: $e', style: const TextStyle(fontSize: 16)),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                );
              }
            }
          },
        ),
        _buildNotificationIcon(),
        const SizedBox(width: 8)
      ],
    );
  }

  PreferredSizeWidget _buildPageHeader(
    bool isDark,
    String title,
    List<Widget> actions,
  ) {
    return AppBar(
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, size: 22),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
      ),
      actions: actions,
    );
  }

  Widget _buildHeaderActionButton(
    BuildContext context,
    bool isDark,
    String label,
    VoidCallback onTap,
  ) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.getPrimary(isDark).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors.getPrimary(isDark).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.getPrimary(isDark),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Consumer<DashboardController>(
      builder: (context, dashboard, child) {
        final count = dashboard.notificationCount;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.notifications_none_rounded, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
