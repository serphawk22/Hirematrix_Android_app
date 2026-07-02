import 'dart:convert';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/controllers/plans_controller.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  late final PlansController _plansController;
  final PageController _pageController = PageController(
    viewportFraction: 0.88,
    initialPage: 0,
  );
  int _currentPlanPage = 0;

  @override
  void initState() {
    super.initState();
    _plansController = Get.put(PlansController());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.getBackground(isDark)
          : AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.getBackground(isDark)
            : Colors.white,
        elevation: 0,
        title: Text(
          'Premium Services',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.getText(isDark),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.getText(isDark),
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (_plansController.isLoading.value &&
            _plansController.plansList.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.getPrimary(isDark),
              ),
            ),
          );
        }

        final hasSub =
            _plansController.currentSubscription.isNotEmpty &&
            _plansController.currentSubscription['status']
                    ?.toString()
                    .toLowerCase() ==
                'active';
        final subPlanName = hasSub
            ? (_plansController.currentSubscription['plan_name'] ?? 'Pro')
            : '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.diamond,
                        color: Color(0xFFFBBF24),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'One subscription unlocks all three AI services',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        color: AppColors.getText(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock Career Transition AI and Resume Studio from one shared plan.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (hasSub) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your active subscription: $subPlanName plan is active. You can now use all premium services!',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 3 Premium Services Cards
              _buildServiceDetailsList(isDark),

              const SizedBox(height: 40),

              // Plans Title
              Center(
                child: Column(
                  children: [
                    Text(
                      'Choose a plan to unlock every premium service',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.getText(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your subscription works across Career Transition AI and Resume Studio.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // dynamic carousel of plans
              if (_plansController.plansList.isNotEmpty) ...[
                SizedBox(
                  height: 560,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _plansController.plansList.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPlanPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final plan = _plansController.plansList[index];
                      final planId =
                          int.tryParse(plan['id']?.toString() ?? '') ?? 0;
                      final planName = plan['name'] ?? 'Premium Plan';
                      final priceStr = plan['price']?.toString() ?? '0';
                      final price = double.tryParse(priceStr) ?? 0.0;
                      final durationDays =
                          int.tryParse(
                            plan['duration_days']?.toString() ?? '',
                          ) ??
                          30;
                      final desc = plan['description'] ?? '';

                      final featuresData = plan['features'];
                      List<dynamic> features = [];
                      if (featuresData != null) {
                        if (featuresData is String) {
                          try {
                            features = jsonDecode(featuresData);
                          } catch (_) {
                            features = [featuresData];
                          }
                        } else if (featuresData is List) {
                          features = featuresData;
                        }
                      }

                      final isPopular = planName
                          .toString()
                          .toLowerCase()
                          .contains('pro monthly');
                      final isCurrentActive =
                          hasSub &&
                          _plansController.currentSubscription['plan_id']
                                  ?.toString() ==
                              planId.toString();

                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = _pageController.page! - index;
                            value = (1 - (value.abs() * 0.05)).clamp(0.0, 1.0);
                          }
                          return Center(
                            child: SizedBox(
                              height: Curves.easeOut.transform(value) * 540,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          child: _buildPlanCard(
                            planId: planId,
                            name: planName,
                            price: price,
                            durationDays: durationDays,
                            description: desc,
                            features: features,
                            isPopular: isPopular,
                            isActive: isCurrentActive,
                            isDark: isDark,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_plansController.plansList.length, (
                    index,
                  ) {
                    final isActive = _currentPlanPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.getPrimary(isDark)
                            : (isDark ? Colors.grey[700] : Colors.grey[300]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],

              const SizedBox(height: 40),
              Center(
                child: Text(
                  'One subscription unlocks all three services. Cancel anytime.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildServiceDetailsList(bool isDark) {
    return Column(
      children: [
        _buildServiceInfoCard(
          icon: Icons.route,
          title: 'Career Transition AI',
          accentColor: AppColors.getPrimary(isDark),
          summary:
              'Build a structured learning path from your current role to your target role.',
          points: [
            'Personalized roadmap',
            'Daily actionable tasks',
            'Skill gap analysis',
            'Course modules and exercises',
          ],
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildServiceInfoCard(
          icon: Icons.description,
          title: 'Resume Studio',
          accentColor: const Color(0xFF10B981),
          summary:
              'Create AI-assisted resume versions for roles, jobs, and career pivots.',
          points: [
            'ATS-friendly resumes',
            'Job-specific versions',
            'Career transition resumes',
            'Unlimited updates',
          ],
          isDark: isDark,
        ),

      ],
    );
  }

  Widget _buildServiceInfoCard({
    required IconData icon,
    required String title,
    required Color accentColor,
    required String summary,
    required List<String> points,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.getText(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: points.map((pt) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    pt,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required int planId,
    required String name,
    required double price,
    required int durationDays,
    required String description,
    required List<dynamic> features,
    required bool isPopular,
    required bool isActive,
    required bool isDark,
  }) {
    final popularBorderColor = AppColors.getPrimary(isDark);
    final isFree = price <= 0.0;

    String durationText = '/month';
    if (durationDays == 90) {
      durationText = '/quarter';
    } else if (durationDays == 365) {
      durationText = '/year';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.getCard(isDark) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFF10B981)
              : (isPopular
                    ? popularBorderColor
                    : (isDark ? Colors.grey[800]! : Colors.grey[200]!)),
          width: (isActive || isPopular) ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Text(
                'YOUR ACTIVE PLAN',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.getPrimary(isDark),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.getText(isDark),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (isFree)
                      Text(
                        'Free',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: const Color(0xFF10B981),
                        ),
                      )
                    else ...[
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: AppColors.getPrimary(isDark),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        durationText,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                Column(
                  children: features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isActive
                        ? null
                        : () {
                            if (isFree) {
                              Get.back();
                            } else {
                              _plansController.startPaymentFlow(planId, name);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? Colors.grey
                          : (isPopular
                                ? AppColors.getPrimary(isDark)
                                : Colors.transparent),
                      foregroundColor: isActive
                          ? Colors.white
                          : (isPopular
                                ? Colors.white
                                : AppColors.getPrimary(isDark)),
                      elevation: 0,
                      side: (isActive || isPopular)
                          ? null
                          : BorderSide(
                              color: AppColors.getPrimary(isDark),
                              width: 1.5,
                            ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isActive
                          ? 'Active Plan'
                          : (isFree
                                ? 'Get Started Free'
                                : 'Subscribe ₹${price.toStringAsFixed(0)}'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
