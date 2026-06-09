import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/app_constants.dart';
import '../../services/api_service.dart';
import '../../controllers/auth_controller.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _members = [];
  List<dynamic> _invites = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
    if (recruiterId != null) {
      final response = await _apiService.fetchTeam(recruiterId);
      if (response['success'] == true) {
        setState(() {
          _members = response['members'] ?? [];
          _invites = response['invites'] ?? [];
        });
      }
    }
    setState(() => _isLoading = false);
  }

  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    String selectedRole = 'Recruiter';
    final roles = ['HR Manager', 'Recruiter', 'Hiring Manager', 'Interview Panel', 'Talent Acquisition'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Invite Team Member', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email Address', hintText: 'recruiter@company.com'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => selectedRole = val!,
              decoration: const InputDecoration(labelText: 'Assign Role'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              final recruiterId = Provider.of<AuthController>(context, listen: false).currentRecruiter?.id;
              final resp = await _apiService.inviteMember(recruiterId!, emailCtrl.text.trim(), selectedRole);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(resp['message'] ?? 'Action completed'),
                  backgroundColor: resp['success'] == true ? AppColors.success : AppColors.error,
                ));
                _loadData();
              }
            }, 
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Team Management', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded, size: 20)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(isDark),
                const SizedBox(height: 24),
                _buildSectionTitle('Active Recruiters', _members.length),
                const SizedBox(height: 12),
                ..._members.map((m) => _buildMemberTile(m, isDark, false)),
                if (_invites.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle('Pending Invitations', _invites.length),
                  const SizedBox(height: 12),
                  ..._invites.map((i) => _buildMemberTile(i, isDark, true)),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Invite Member'),
        backgroundColor: AppColors.getPrimary(isDark),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.getPrimary(isDark), AppColors.getPrimary(isDark).withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Build your hiring team', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Manage recruiter access and collaboration workspace.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.1)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(count.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member, bool isDark, bool isPending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (isPending ? Colors.orange : AppColors.getPrimary(isDark)).withValues(alpha: 0.1),
            child: Icon(isPending ? Icons.hourglass_empty_rounded : Icons.person_rounded, size: 20, color: isPending ? Colors.orange : AppColors.getPrimary(isDark)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member['full_name'] ?? member['email'], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(member['role'] ?? 'Recruiter', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('PENDING', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.orange)),
            )
          else
             const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
