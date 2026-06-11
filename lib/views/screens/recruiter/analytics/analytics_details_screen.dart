import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';

class AnalyticsDetailsScreen extends StatefulWidget {
  const AnalyticsDetailsScreen({super.key});

  @override
  State<AnalyticsDetailsScreen> createState() => _AnalyticsDetailsScreenState();
}

class _AnalyticsDetailsScreenState extends State<AnalyticsDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Overview', 'Funnel', 'Hiring', 'Reports'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Insights', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey[100]!))),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.getPrimary(isDark),
              labelColor: AppColors.getPrimary(isDark),
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(isDark),
          _buildFunnelTab(isDark),
          _buildHiringTab(isDark),
          _buildReportsTab(isDark),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    return Consumer<DashboardController>(
      builder: (context, dashboard, child) {
        final stats = (dashboard.dashboardData['stats'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        final trends = (stats['application_trends'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Key Metrics', isDark),
              const SizedBox(height: 12),
              _buildPerformanceGrid(isDark, stats),
              const SizedBox(height: 24),
              _buildSectionTitle('Application Trends', isDark),
              const SizedBox(height: 12),
              _buildChartContainer(isDark, _HiringLineChart(trends: trends)),
              const SizedBox(height: 24),
              _buildSectionTitle('Source Analysis', isDark),
              const SizedBox(height: 12),
              _buildChartContainer(isDark, const _SourcePieChart()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHiringTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Recruiter Productivity', isDark),
          const SizedBox(height: 12),
          _buildProductivityCard(isDark, 'Time to Hire', '12 Days', 0.7, Colors.blue),
          const SizedBox(height: 10),
          _buildProductivityCard(isDark, 'Interview Rate', '4.2/day', 0.85, Colors.orange),
          const SizedBox(height: 10),
          _buildProductivityCard(isDark, 'Offer Success', '92%', 0.92, Colors.green),
          const SizedBox(height: 24),
          _buildSectionTitle('Active Jobs Performance', isDark),
          const SizedBox(height: 12),
          _buildJobPerfItem(isDark, 'Senior UI Designer', '48 Apps', '12 Intv', Colors.blue),
          _buildJobPerfItem(isDark, 'Backend Developer', '124 Apps', '8 Intv', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildReportsTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: AppColors.getPrimary(isDark).withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Monthly Hiring Report', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          Text('Generated on March 1st, 2024', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Export PDF Report'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 44)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textLight));
  }

  Widget _buildPerformanceGrid(bool isDark, Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.85, // Compact horizontal rectangle
      children: [
        _buildMiniDetailCard('Time to Hire', stats['time_to_hire'] ?? 'N/A', 'Optimal', Icons.timer_outlined, Colors.blue, isDark),
        _buildMiniDetailCard('Offer Accept', stats['conversion_rate'] ?? '0%', 'Healthy', Icons.check_circle_outline, Colors.green, isDark),
        _buildMiniDetailCard('Need Review', (stats['need_review'] ?? 0).toString(), 'Pending', Icons.pending_actions_rounded, Colors.orange, isDark),
        _buildMiniDetailCard('Active Roles', (stats['open_jobs'] ?? 0).toString(), 'High', Icons.business_center_rounded, Colors.purple, isDark),
      ],
    );
  }

  Widget _buildMiniDetailCard(String label, String val, String status, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  val,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getText(isDark),
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextMuted(isDark),
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(bool isDark, Widget chart) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: chart,
    );
  }

  Widget _buildFunnelTab(bool isDark) {
    return Consumer<DashboardController>(
      builder: (context, dashboard, child) {
        final pipeline = (dashboard.dashboardData['pipeline_stats'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        
        int applied = pipeline['Applied'] ?? 0;
        int screening = pipeline['Screening'] ?? 0;
        int interview = pipeline['Interview'] ?? 0;
        int offer = pipeline['Offer'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Recruitment Funnel', isDark),
              const SizedBox(height: 12),
              _buildConversionCard(isDark, applied, screening, interview, offer),
              const SizedBox(height: 24),
              _buildSectionTitle('Stage Drop-offs', isDark),
              const SizedBox(height: 12),
              _buildDropOffList(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversionCard(bool isDark, int applied, int screening, int interview, int offer) {
    double sRate = applied > 0 ? (screening / applied) : 0.0;
    double iRate = screening > 0 ? (interview / screening) : 0.0;
    double oRate = interview > 0 ? (offer / interview) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildProgressRow('Applied → Screening', sRate, '${(sRate * 100).toInt()}%', Colors.blue),
          const SizedBox(height: 12),
          _buildProgressRow('Screening → Interview', iRate, '${(iRate * 100).toInt()}%', Colors.orange),
          const SizedBox(height: 12),
          _buildProgressRow('Interview → Offer', oRate, '${(oRate * 100).toInt()}%', Colors.green),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double val, String pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(pct, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: val, minHeight: 4, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(color)),
        ),
      ],
    );
  }

  Widget _buildDropOffList(bool isDark) {
    final items = [
      {'stage': 'Screening', 'reason': 'Skill Mismatch', 'pct': '32%'},
      {'stage': 'Interview', 'reason': 'Salary Expectations', 'pct': '18%'},
      {'stage': 'Offer', 'reason': 'Competing Offers', 'pct': '8%'},
    ];
    return Column(
      children: items.map((i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: Colors.redAccent.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i['stage']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(i['reason']!, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ],
            )),
            Text(i['pct']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.redAccent)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildProductivityCard(bool isDark, String label, String val, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(val, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          )),
          SizedBox(width: 40, height: 40, child: CircularProgressIndicator(value: progress, strokeWidth: 4, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(color))),
        ],
      ),
    );
  }

  Widget _buildJobPerfItem(bool isDark, String title, String app, String intv, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700))),
          Text(app, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(width: 12),
          Text(intv, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _HiringLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> trends;
  const _HiringLineChart({required this.trends});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];
    if (trends.isEmpty) {
      spots = [const FlSpot(0, 0), const FlSpot(6, 0)];
    } else {
      for (int i = 0; i < trends.length; i++) {
        spots.add(FlSpot(i.toDouble(), double.tryParse(trends[i]['count'].toString()) ?? 0.0));
      }
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }
}

class _SourcePieChart extends StatelessWidget {
  const _SourcePieChart();

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(color: Colors.blue, value: 40, title: 'LinkedIn', radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: Colors.green, value: 30, title: 'Referral', radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: Colors.orange, value: 20, title: 'Indeed', radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: Colors.grey, value: 10, title: 'Others', radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
