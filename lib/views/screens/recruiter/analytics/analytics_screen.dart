import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';
import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';
import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive().init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabs(isDark),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, isDark),
              _buildAcquisitionTab(context, isDark),
              _buildEfficiencyTab(context, isDark),
              _buildReportingTab(context, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      width: double.infinity,
      height: Responsive.scale(42),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey[100]!))),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.getPrimary(isDark),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.getPrimary(isDark),
        unselectedLabelColor: AppColors.getTextMuted(isDark),
        labelStyle: GoogleFonts.inter(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w700),
        tabs: const [Tab(text: 'Overview'), Tab(text: 'Acquisition'), Tab(text: 'Efficiency'), Tab(text: 'Reports')],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, bool isDark) {
    return Consumer<DashboardController>(
      builder: (context, dashboard, child) {
        final stats = (dashboard.dashboardData['stats'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        final pipeline = (dashboard.dashboardData['pipeline_stats'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        final trends = (stats['application_trends'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        return ListView(
          padding: EdgeInsets.all(Responsive.paddingH),
          children: [
            Row(
              children: [
                _buildMetricMiniCard('Time to Hire', stats['time_to_hire'] ?? 'N/A', Icons.timer_outlined, Colors.blue, isDark),
                SizedBox(width: Responsive.spacing(12)),
                _buildMetricMiniCard('Offer Accept', stats['conversion_rate'] ?? '0%', Icons.check_circle_outline_rounded, Colors.green, isDark),
              ],
            ),
            SizedBox(height: Responsive.spacing(24)),
            _buildSectionTitle('Hiring Velocity Trend', isDark),
            SizedBox(height: Responsive.spacing(12)),
            _buildChartCard(context, isDark, _VelocityLineChart(trends: trends)),
            SizedBox(height: Responsive.spacing(24)),
            _buildSectionTitle('Pipeline Funnel Conversion', isDark),
            SizedBox(height: Responsive.spacing(12)),
            _buildFunnelAnalysis(isDark, pipeline),
          ],
        );
      },
    );
  }

  Widget _buildMetricMiniCard(String label, String val, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(Responsive.spacing(16)),
        decoration: BoxDecoration(
          color: isDark ? AppColors.getCard(isDark) : Colors.white,
          borderRadius: BorderRadius.circular(Responsive.cardRadius),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.spacing(8)),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: Responsive.scale(16), color: color),
            ),
            SizedBox(height: Responsive.spacing(12)),
            Text(val, style: GoogleFonts.inter(fontSize: Responsive.fontSize(22), fontWeight: FontWeight.w800)),
            Text(label, style: GoogleFonts.inter(fontSize: Responsive.fontSize(11), fontWeight: FontWeight.w500, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(title, style: GoogleFonts.inter(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.w700, color: AppColors.getText(isDark)));
  }

  Widget _buildChartCard(BuildContext context, bool isDark, Widget chart) {
    return Container(
      height: Responsive.scale(200),
      padding: EdgeInsets.fromLTRB(Responsive.spacing(12), Responsive.spacing(20), Responsive.spacing(16), Responsive.spacing(12)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(Responsive.cardRadius),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: chart,
    );
  }

  Widget _buildFunnelAnalysis(bool isDark, Map<String, dynamic> pipeline) {
    final stages = [
      {'l': 'Applied', 'v': pipeline['Applied']?.toString() ?? '0', 'p': 1.0, 'c': Colors.blue},
      {'l': 'Screening', 'v': pipeline['Screening']?.toString() ?? '0', 'p': 0.75, 'c': Colors.orange},
      {'l': 'Interview', 'v': pipeline['Interview']?.toString() ?? '0', 'p': 0.35, 'c': Colors.indigo},
      {'l': 'Hired', 'v': pipeline['Hired']?.toString() ?? '0', 'p': 0.1, 'c': Colors.green},
    ];

    return Container(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(Responsive.cardRadius),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        children: stages.map((s) => Padding(
          padding: EdgeInsets.only(bottom: Responsive.spacing(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s['l'] as String, style: GoogleFonts.inter(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600)),
                  Text(s['v'] as String, style: GoogleFonts.inter(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w800)),
                ],
              ),
              SizedBox(height: Responsive.spacing(6)),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: s['p'] as double,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(s['c'] as Color),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildAcquisitionTab(BuildContext context, bool isDark) {
    return ListView(
      padding: EdgeInsets.all(Responsive.paddingH),
      children: [
        _buildSectionTitle('Source Performance', isDark),
        SizedBox(height: Responsive.spacing(12)),
        _buildSourceGrid(isDark),
        SizedBox(height: Responsive.spacing(24)),
        _buildSectionTitle('Candidate Acquisition Mix', isDark),
        SizedBox(height: Responsive.spacing(12)),
        _buildChartCard(context, isDark, const _AcquisitionPieChart()),
      ],
    );
  }

  Widget _buildSourceGrid(bool isDark) {
    final sources = [
      {'n': 'LinkedIn', 'a': '84', 'h': '3', 'cr': '3.5%', 'col': Colors.blue},
      {'n': 'Referral', 'a': '12', 'h': '4', 'cr': '33%', 'col': Colors.green},
      {'n': 'Indeed', 'a': '42', 'h': '1', 'cr': '2.3%', 'col': Colors.indigo},
      {'n': 'Company Site', 'a': '15', 'h': '0', 'cr': '0%', 'col': Colors.orange},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isTablet ? 4 : 2,
        crossAxisSpacing: Responsive.spacing(10),
        mainAxisSpacing: Responsive.spacing(10),
        childAspectRatio: Responsive.gridRatio(1.3),
      ),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final s = sources[index];
        return Container(
          padding: EdgeInsets.all(Responsive.spacing(12)),
          decoration: BoxDecoration(
            color: isDark ? AppColors.getCard(isDark) : Colors.white,
            borderRadius: BorderRadius.circular(Responsive.cardRadius),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: s['col'] as Color, shape: BoxShape.circle)),
                  SizedBox(width: Responsive.spacing(8)),
                  Text(s['n'] as String, style: GoogleFonts.inter(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w700)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Apps', style: GoogleFonts.inter(fontSize: Responsive.fontSize(9), color: Colors.grey)),
                      Text(s['a'] as String, style: GoogleFonts.inter(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.w800)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Conv.', style: GoogleFonts.inter(fontSize: Responsive.fontSize(9), color: Colors.grey)),
                      Text(s['cr'] as String, style: GoogleFonts.inter(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.w800, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEfficiencyTab(BuildContext context, bool isDark) => _buildPlaceholder('Recruiter Productivity', isDark);
  Widget _buildReportingTab(BuildContext context, bool isDark) => _buildPlaceholder('Custom Reports', isDark);

  Widget _buildPlaceholder(String title, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_rounded, size: Responsive.scale(48), color: Colors.grey.withValues(alpha: 0.2)),
          SizedBox(height: Responsive.spacing(16)),
          Text(title, style: GoogleFonts.inter(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.w700, color: Colors.grey)),
          SizedBox(height: Responsive.spacing(8)),
          Text('Enterprise reporting engine loading...', style: GoogleFonts.inter(fontSize: Responsive.fontSize(12), color: Colors.grey)),
        ],
      ),
    );
  }
}

class _VelocityLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> trends;
  const _VelocityLineChart({required this.trends});

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
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                if (trends.isEmpty || val.toInt() >= trends.length) return const SizedBox();
                final dateStr = trends[val.toInt()]['date'];
                final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(DateFormat('E').format(date), style: TextStyle(fontSize: Responsive.fontSize(9), color: Colors.grey)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.getPrimary(Theme.of(context).brightness == Brightness.dark),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: AppColors.getPrimary(Theme.of(context).brightness == Brightness.dark).withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }
}

class _AcquisitionPieChart extends StatelessWidget {
  const _AcquisitionPieChart();

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: Responsive.scale(40),
        sections: [
          PieChartSectionData(color: Colors.blue, value: 45, title: 'LinkedIn', radius: Responsive.scale(45), titleStyle: TextStyle(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: Colors.green, value: 25, title: 'Ref.', radius: Responsive.scale(45), titleStyle: TextStyle(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: Colors.indigo, value: 20, title: 'Indeed', radius: Responsive.scale(45), titleStyle: TextStyle(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: Colors.orange, value: 10, title: 'Direct', radius: Responsive.scale(45), titleStyle: TextStyle(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
