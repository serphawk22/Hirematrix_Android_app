import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/resdex_controller.dart';
import 'package:hirematrix/views/screens/recruiter/widgets/main_drawer.dart';

class ResdexManageSearchesScreen extends StatefulWidget {
  const ResdexManageSearchesScreen({super.key});

  @override
  State<ResdexManageSearchesScreen> createState() => _ResdexManageSearchesScreenState();
}

class _ResdexManageSearchesScreenState extends State<ResdexManageSearchesScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchData();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _selectedIds.clear();
      _fetchData();
    }
  }

  void _fetchData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final resdex = Provider.of<ResdexController>(context, listen: false);
      if (auth.currentRecruiter?.id != null) {
        final tab = _tabController.index == 0 ? 'saved' : 'recent';
        resdex.fetchSearches(auth.currentRecruiter!.id.toString(), tab);
      }
    });
  }

  void _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    
    final auth = Provider.of<AuthController>(context, listen: false);
    final resdex = Provider.of<ResdexController>(context, listen: false);
    if (auth.currentRecruiter?.id == null) return;

    final response = await resdex.deleteSearches(auth.currentRecruiter!.id.toString(), _selectedIds.toList());
    
    if (mounted) {
      if (response['success'] == true) {
        setState(() {
          _selectedIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Searches deleted.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to delete searches.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: Text(
          'Manage Searches',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.getText(isDark)),
        ),
        backgroundColor: AppColors.getBackground(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getText(isDark)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.getPrimary(isDark),
          unselectedLabelColor: AppColors.getTextMuted(isDark),
          indicatorColor: AppColors.getPrimary(isDark),
          tabs: const [
            Tab(text: 'Saved Searches'),
            Tab(text: 'Recent Searches'),
          ],
        ),
      ),
      body: Consumer<ResdexController>(
        builder: (context, resdex, child) {
          if (resdex.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (resdex.savedSearches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: AppColors.getTextMuted(isDark)),
                  const SizedBox(height: 16),
                  Text(
                    'No searches found',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getText(isDark),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _selectedIds.length == resdex.savedSearches.length && resdex.savedSearches.isNotEmpty,
                      activeColor: AppColors.getPrimary(isDark),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.clear();
                            _selectedIds.addAll(resdex.savedSearches.map((s) => int.parse(s['id'].toString())));
                          } else {
                            _selectedIds.clear();
                          }
                        });
                      },
                    ),
                    Text('Select all', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.getTextMuted(isDark), fontSize: 13)),
                  ],
                ),
              ),
              if (_selectedIds.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.getCard(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${_selectedIds.length} selected',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.getPrimary(isDark)),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _selectedIds.clear()),
                        child: Text('Clear', style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark), decoration: TextDecoration.underline)),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete, size: 16),
                        onPressed: _deleteSelected,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        label: const Text('Delete Selected'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: resdex.savedSearches.length,
                  itemBuilder: (context, index) {
                    final search = resdex.savedSearches[index];
                    return _buildSearchCard(search, isDark);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchCard(Map<String, dynamic> search, bool isDark) {
    final searchId = int.parse(search['id'].toString());
    final isSelected = _selectedIds.contains(searchId);
    
    final date = DateTime.tryParse(search['created_at'] ?? '');
    final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : '';
    final alertFreq = search['alert_frequency'] ?? 'none';
    final isSavedTab = _tabController.index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.getPrimary(isDark).withOpacity(0.05) : AppColors.getCard(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.getPrimary(isDark) : AppColors.getBorder(isDark),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedIds.add(searchId);
                    } else {
                      _selectedIds.remove(searchId);
                    }
                  });
                },
                activeColor: AppColors.getPrimary(isDark),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          search['search_name'] ?? 'Untitled Search',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getText(isDark),
                          ),
                        ),
                        if (isSavedTab && alertFreq != 'none')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.getPrimary(isDark).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications, size: 10, color: AppColors.getPrimary(isDark)),
                                const SizedBox(width: 4),
                                Text(
                                  alertFreq.toString().toUpperCase(),
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.getPrimary(isDark)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created on $dateStr',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.getTextMuted(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 14),
                  onPressed: () {
                    Navigator.pop(context); // Would route to Resdex and fill
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.getBorder(isDark)),
                    foregroundColor: AppColors.getText(isDark),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                  label: const Text('Fill'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search, size: 14),
                  onPressed: () {
                    // Would route to Resdex and search
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                  label: const Text('Search'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  final auth = Provider.of<AuthController>(context, listen: false);
                  final resdex = Provider.of<ResdexController>(context, listen: false);
                  if (auth.currentRecruiter?.id != null) {
                    final res = await resdex.deleteSearches(auth.currentRecruiter!.id.toString(), [searchId]);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Deleted')));
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
                child: const Icon(Icons.delete, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
