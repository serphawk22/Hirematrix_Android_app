import 'package:flutter/material.dart';
import 'package:hirematrix/core/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hirematrix/controllers/onboarding_controller.dart';
import 'package:hirematrix/controllers/theme_controller.dart';
import 'package:hirematrix/views/widgets/animated_gradient_background.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      body: Obx(() {
        final isDark = themeController.isDarkMode;
        return AnimatedGradientBackground(
          isDark: isDark,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark, controller.currentStep.value),
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.transparent,
                      colorScheme: ColorScheme.fromSwatch().copyWith(
                        primary: AppColors.getPrimary(isDark),
                      ),
                    ),
                    child: Stepper(
                      type: StepperType.vertical,
                      currentStep: controller.currentStep.value,
                      onStepContinue: controller.nextStep,
                      onStepCancel: controller.previousStep,
                      controlsBuilder: (BuildContext context, ControlsDetails details) {
                        final step = controller.currentStep.value;
                        return Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: <Widget>[
                                  ElevatedButton(
                                    onPressed: details.onStepContinue,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.getPrimary(isDark),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: controller.isLoading.value
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : Text(step == 6 ? 'Finish & Go to Dashboard' : 'Save & Continue'),
                                  ),
                                  if (step > 0) ...[
                                    const SizedBox(width: 12),
                                    TextButton(
                                      onPressed: details.onStepCancel,
                                      style: TextButton.styleFrom(
                                        foregroundColor: isDark ? Colors.white70 : Colors.black54,
                                      ),
                                      child: const Text('Back'),
                                    ),
                                  ],
                                ],
                              ),
                              // Show skip button on all optional steps (step 1 onward)
                              if (step > 0) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: controller.skipToDashboard,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isDark ? Colors.white24 : Colors.black26,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.skip_next_rounded,
                                          size: 18,
                                          color: isDark ? Colors.white54 : Colors.black45,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Skip & Go to Dashboard',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? Colors.white54 : Colors.black45,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                      steps: [
                        _buildPersonalStep(controller, isDark),
                        _buildResumeStep(controller, isDark),
                        _buildSkillsStep(controller, isDark),
                        _buildEducationStep(controller, isDark),
                        _buildExperienceStep(controller, isDark),
                        _buildPreferencesStep(controller, isDark),
                        _buildReviewStep(controller, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(bool isDark, int currentStep) {
    int percent = ((currentStep / 6) * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add, color: isDark ? Colors.white : Colors.black, size: 24),
              const SizedBox(width: 10),
              Text(
                'Complete Your Profile',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currentStep == 0
                ? '✦ Personal Details are required to get started. All other steps are optional.'
                : 'You can complete remaining steps anytime from your profile.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: currentStep == 0
                  ? AppColors.getPrimary(isDark)
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: isDark ? Colors.white12 : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.getPrimary(isDark)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '$percent% Complete',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
      ),
    );
  }

  Step _buildPersonalStep(OnboardingController controller, bool isDark) {
    return Step(
      title: Text('Personal Details', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      content: Column(
        children: [
          TextField(controller: controller.nameController, decoration: _inputDeco('Full Name', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          TextField(controller: controller.phoneController, decoration: _inputDeco('Phone', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          TextField(controller: controller.locationController, decoration: _inputDeco('Current Location', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: _inputDeco('Gender', isDark),
            dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
              DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
            ],
            onChanged: (v) => controller.gender.value = v ?? '',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.dateOfBirthController, 
            decoration: _inputDeco('Date of Birth', isDark).copyWith(
              suffixIcon: Icon(Icons.calendar_today, color: isDark ? Colors.white54 : Colors.black54),
            ), 
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            readOnly: true,
            onTap: () => controller.selectDateOfBirth(Get.context!),
          ),
          const SizedBox(height: 12),
          TextField(controller: controller.bioController, maxLines: 4, decoration: _inputDeco('Professional Summary', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        ],
      ),
      isActive: controller.currentStep.value >= 0,
    );
  }

  Step _buildResumeStep(OnboardingController controller, bool isDark) {
    return Step(
      title: Text('Resume Upload', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      content: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(Icons.upload_file, size: 50, color: isDark ? Colors.white54 : Colors.black54),
            const SizedBox(height: 10),
            Text('Upload Resume is required. Upload a PDF, DOC, or DOCX file.', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: controller.pickResume,
              icon: Icon(Icons.attach_file),
              label: const Text('Select File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                foregroundColor: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Obx(() => Text(
              controller.selectedResumeName.value.isEmpty ? 'No file selected' : controller.selectedResumeName.value,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontStyle: FontStyle.italic),
            )),
          ],
        ),
      ),
      isActive: controller.currentStep.value >= 1,
    );
  }

  Step _buildSkillsStep(OnboardingController controller, bool isDark) {
    return Step(
      title: Text('Skills', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      content: Column(
        children: [
          TextField(
            controller: controller.skillsController, 
            maxLines: 3, 
            decoration: _inputDeco('Skills (Comma separated, e.g. PHP, Flutter, Dart)', isDark), 
            style: TextStyle(color: isDark ? Colors.white : Colors.black)
          ),
        ],
      ),
      isActive: controller.currentStep.value >= 2,
    );
  }

  Step _buildEducationStep(OnboardingController controller, bool isDark) {
    return Step(
      title: Text('Education', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      content: Obx(() => Column(
        children: [
          for (int i = 0; i < controller.educations.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.white24 : Colors.black12), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Education ${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      if (i > 0) IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => controller.removeEducation(i)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: controller.educations[i]['degree'], decoration: _inputDeco('Degree', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 8),
                  TextField(controller: controller.educations[i]['field_of_study'], decoration: _inputDeco('Field of Study', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 8),
                  TextField(controller: controller.educations[i]['institution'], decoration: _inputDeco('Institution', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: controller.educations[i]['start_year'], decoration: _inputDeco('Start Year', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: controller.educations[i]['end_year'], decoration: _inputDeco('End Year', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                    ],
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: controller.addEducation,
            icon: Icon(Icons.add),
            label: const Text('Add Education'),
          ),
        ],
      )),
      isActive: controller.currentStep.value >= 3,
    );
  }

  Step _buildExperienceStep(OnboardingController controller, bool isDark) {
    return Step(
      title: Text('Experience', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      content: Obx(() => Column(
        children: [
          CheckboxListTile(
            title: Text('I am a fresher / I do not have work experience yet', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            value: controller.isFresher.value,
            onChanged: (v) => controller.isFresher.value = v ?? false,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (!controller.isFresher.value)
            for (int i = 0; i < controller.experiences.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.white24 : Colors.black12), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Experience ${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        if (i > 0) IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => controller.removeExperience(i)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: controller.experiences[i]['job_title'], decoration: _inputDeco('Job Title', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 8),
                    TextField(controller: controller.experiences[i]['company_name'], decoration: _inputDeco('Company', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: _inputDeco('Employment Type', isDark),
                      dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      value: controller.experiences[i]['employment_type'],
                      items: ['Full-time', 'Part-time', 'Contract', 'Internship', 'Freelance'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => controller.experiences[i]['employment_type'] = v ?? 'Full-time',
                    ),
                  ],
                ),
              ),
          if (!controller.isFresher.value)
            TextButton.icon(
              onPressed: controller.addExperience,
              icon: Icon(Icons.add),
              label: const Text('Add Experience'),
            ),
        ],
      )),
      isActive: controller.currentStep.value >= 4,
    );
  }

  Step _buildPreferencesStep(OnboardingController controller, bool isDark) {
    return Step(
      title: Text('Preferences', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      content: Column(
        children: [
          TextField(controller: controller.resumeHeadlineController, decoration: _inputDeco('Resume Headline', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          TextField(controller: controller.preferredJobTitlesController, decoration: _inputDeco('Preferred Job Titles', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          TextField(controller: controller.preferredLocationsController, decoration: _inputDeco('Preferred Locations', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: _inputDeco('Preferred Employment Type', isDark),
            dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            items: ['Full-time', 'Part-time', 'Contract', 'Internship', 'Freelance'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) => controller.preferredEmploymentType.value = v ?? '',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: _inputDeco('Notice Period', isDark),
            dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            items: ['Immediate', '1 Month', '2 Months', '3 Months', 'More than 3 Months'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) => controller.noticePeriod.value = v ?? '',
          ),
          const SizedBox(height: 12),
          TextField(controller: controller.expectedSalaryController, decoration: _inputDeco('Expected Salary (LPA)', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black), keyboardType: TextInputType.number),
        ],
      ),
      isActive: controller.currentStep.value >= 5,
    );
  }

  Step _buildReviewStep(OnboardingController controller, bool isDark) {
    final stepLabels = [
      'Personal Details',
      'Resume Upload',
      'Skills',
      'Education',
      'Experience',
      'Preferences',
    ];
    final stepDescriptions = [
      'Add the key identity and contact details recruiters need first.',
      'Upload your resume so the portal can use it for jobs and matching.',
      'List your strongest skills in a recruiter-friendly format.',
      'Add at least one education record to complete your academic background.',
      'Add work experience, or mark yourself as a fresher.',
      'Capture work preferences that improve job recommendations.',
    ];

    return Step(
      title: Text('Review', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      content: Column(
        children: [
          for (int i = 0; i < stepLabels.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          stepLabels[i],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stepDescriptions[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Text(
            'Confirm everything before entering the portal.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      isActive: controller.currentStep.value >= 6,
    );
  }
}
