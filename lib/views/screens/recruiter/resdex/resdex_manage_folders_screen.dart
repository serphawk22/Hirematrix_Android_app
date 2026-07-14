import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';
import 'package:hirematrix/controllers/recruiter_controller/resdex_controller.dart';
import 'package:hirematrix/views/screens/recruiter/widgets/main_drawer.dart';
import 'package:hirematrix/views/screens/recruiter/resdex/resdex_folder_detail_screen.dart';

class ResdexManageFoldersScreen extends StatefulWidget {
  const ResdexManageFoldersScreen({super.key});

  @override
  State<ResdexManageFoldersScreen> createState() =>
      _ResdexManageFoldersScreenState();
}

class _ResdexManageFoldersScreenState extends State<ResdexManageFoldersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<int> _selectedIds = {};
  final TextEditingController _folderNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFolders();
  }

  @override
  void dispose() {
    _folderNameCtrl.dispose();
    super.dispose();
  }

  void _fetchFolders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      final resdex = Provider.of<ResdexController>(context, listen: false);
      if (auth.currentRecruiter?.id != null) {
        resdex.fetchFolders(auth.currentRecruiter!.id.toString());
      }
    });
  }

  void _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final auth = Provider.of<AuthController>(context, listen: false);
    final resdex = Provider.of<ResdexController>(context, listen: false);
    if (auth.currentRecruiter?.id == null) return;

    final response = await resdex.deleteFolders(
      auth.currentRecruiter!.id.toString(),
      _selectedIds.toList(),
    );

    if (mounted) {
      if (response['success'] == true) {
        setState(() {
          _selectedIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Folders deleted.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to delete folders.'),
          ),
        );
      }
    }
  }

  void _showCreateFolderDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.getCard(isDark),
          title: Text(
            'Create New Folder',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: AppColors.getText(isDark),
            ),
          ),
          content: TextField(
            controller: nameCtrl,
            style: GoogleFonts.inter(color: AppColors.getText(isDark)),
            decoration: InputDecoration(
              hintText: 'Folder Name',
              hintStyle: GoogleFonts.inter(
                color: AppColors.getTextMuted(isDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.getPrimary(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.getBorder(isDark)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.getTextMuted(isDark)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(context);

                final auth = Provider.of<AuthController>(
                  context,
                  listen: false,
                );
                final resdex = Provider.of<ResdexController>(
                  context,
                  listen: false,
                );
                if (auth.currentRecruiter?.id != null) {
                  final response = await resdex.createFolder(
                    auth.currentRecruiter!.id.toString(),
                    nameCtrl.text.trim(),
                  );
                  if (mounted && response['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Folder created.')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
              ),
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
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
          'My Folders',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.getText(isDark),
          ),
        ),
        backgroundColor: AppColors.getBackground(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getText(isDark)),
      ),
      body: Consumer<ResdexController>(
        builder: (context, resdex, child) {
          if (resdex.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _folderNameCtrl,
                          style: GoogleFonts.inter(
                            color: AppColors.getText(isDark),
                          ),
                          decoration: InputDecoration(
                            hintText: 'New folder name',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.getTextMuted(isDark),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide(
                                color: AppColors.getBorder(isDark),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (_folderNameCtrl.text.trim().isEmpty) return;
                          final auth = Provider.of<AuthController>(
                            context,
                            listen: false,
                          );
                          if (auth.currentRecruiter?.id != null) {
                            final response = await resdex.createFolder(
                              auth.currentRecruiter!.id.toString(),
                              _folderNameCtrl.text.trim(),
                            );
                            if (mounted && response['success'] == true) {
                              _folderNameCtrl.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Folder created.'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Create Folder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getPrimary(isDark),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (resdex.folders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: AppColors.getTextMuted(isDark),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No folders yet.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextMuted(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Checkbox(
                          value:
                              _selectedIds.length == resdex.folders.length &&
                              resdex.folders.isNotEmpty,
                          activeColor: AppColors.getPrimary(isDark),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIds.clear();
                                _selectedIds.addAll(
                                  resdex.folders.map(
                                    (f) => int.parse(f['id'].toString()),
                                  ),
                                );
                              } else {
                                _selectedIds.clear();
                              }
                            });
                          },
                        ),
                        Text(
                          'Select all',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextMuted(isDark),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedIds.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.getCard(isDark),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${_selectedIds.length} selected',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppColors.getPrimary(isDark),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                setState(() => _selectedIds.clear()),
                            child: Text(
                              'Clear',
                              style: GoogleFonts.inter(
                                color: AppColors.getTextMuted(isDark),
                                decoration: TextDecoration.underline,
                              ),
                            ),
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
                  ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 135,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildFolderCard(resdex.folders[index], isDark);
                    }, childCount: resdex.folders.length),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildFolderCard(Map<String, dynamic> folder, bool isDark) {
    final folderId = int.parse(folder['id'].toString());
    final isSelected = _selectedIds.contains(folderId);
    final candidateCount = folder['candidate_count'] ?? 0;

    return Stack(
      children: [
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResdexFolderDetailScreen(
                      folderId: folderId,
                      folderName: folder['folder_name'] ?? 'Untitled Folder',
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.getPrimary(isDark).withOpacity(0.05)
                      : AppColors.getCard(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.getPrimary(isDark)
                        : AppColors.getBorder(isDark),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.getPrimary(isDark),
                            AppColors.getPrimary(isDark).withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.folder,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      folder['folder_name'] ?? 'Untitled Folder',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getText(isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$candidateCount candidate${candidateCount == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.getTextMuted(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Checkbox(
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedIds.add(folderId);
                } else {
                  _selectedIds.remove(folderId);
                }
              });
            },
            activeColor: AppColors.getPrimary(isDark),
          ),
        ),
      ],
    );
  }
}
