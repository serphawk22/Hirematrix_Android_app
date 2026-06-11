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

    return Obx(() {
      final isDark = themeController.isDarkMode;
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: SafeArea(
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
                                      : Text(step == 4 ? 'Finish & Go to Dashboard' : 'Save & Continue'),
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
                      _buildSkillsStep(controller, isDark),
                      _buildEducationStep(controller, isDark),
                      _buildExperienceStep(controller, isDark),
                      _buildReviewStep(controller, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(bool isDark, int currentStep) {
    int percent = ((currentStep / 4) * 100).toInt();
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
      title: Text('Personal Details', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fast-Track Section
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.getPrimary(isDark).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.getPrimary(isDark).withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.getPrimary(isDark), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Fast-Track Your Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload your resume and we\'ll automatically fill in your details, skills, education, and experience.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => controller.uploadAndParseResume(Get.context!),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Upload Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimary(isDark),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(() => Text(
                        controller.selectedResumeName.value.isEmpty 
                            ? 'No file selected' 
                            : controller.selectedResumeName.value,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextField(controller: controller.nameController, decoration: _inputDeco('Full Name *', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          TextField(controller: controller.phoneController, decoration: _inputDeco('Phone *', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black), keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          TextField(controller: controller.locationController, decoration: _inputDeco('Current Location *', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: _inputDeco('Gender *', isDark),
            dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            value: controller.gender.value.isEmpty ? null : controller.gender.value,
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
            decoration: _inputDeco('Date of Birth *', isDark).copyWith(
              suffixIcon: Icon(Icons.calendar_today, color: isDark ? Colors.white54 : Colors.black54),
            ), 
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            readOnly: true,
            onTap: () => controller.selectDateOfBirth(Get.context!),
          ),
          const SizedBox(height: 12),
          TextField(controller: controller.bioController, maxLines: 4, decoration: _inputDeco('Professional Summary (Bio) *', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        ],
      ),
      isActive: controller.currentStep.value >= 0,
    );
  }

  Step _buildSkillsStep(OnboardingController controller, bool isDark) {
    return Step(
      title: Text('Skills', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      content: Column(
        children: [
          TextField(
            controller: controller.skillsController, 
            maxLines: 3, 
            decoration: _inputDeco('Skills * (Comma separated, e.g. PHP, Flutter, Dart)', isDark), 
            style: TextStyle(color: isDark ? Colors.white : Colors.black)
          ),
        ],
      ),
      isActive: controller.currentStep.value >= 1,
    );
  }

  Step _buildEducationStep(OnboardingController controller, bool isDark) {
    return Step(
      title: Text('Education', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
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
                      if (i > 0) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => controller.removeEducation(i)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: controller.educations[i]['degree'], decoration: _inputDeco('Degree *', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 8),
                  TextField(controller: controller.educations[i]['field_of_study'], decoration: _inputDeco('Field of Study *', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 8),
                  TextField(controller: controller.educations[i]['institution'], decoration: _inputDeco('Institution *', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: controller.educations[i]['start_year'], decoration: _inputDeco('Start Year *', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: controller.educations[i]['end_year'], decoration: _inputDeco('End Year *', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: controller.educations[i]['grade'], decoration: _inputDeco('Grade / GPA (Optional)', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: controller.addEducation,
            icon: const Icon(Icons.add),
            label: const Text('Add Education'),
          ),
        ],
      )),
      isActive: controller.currentStep.value >= 2,
    );
  }

  Step _buildExperienceStep(OnboardingController controller, bool isDark) {
    return Step(
      title: Text('Experience', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      content: Obx(() => Column(
        children: [
          CheckboxListTile(
            title: Text('I am a fresher / I do not have work experience yet', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14)),
            value: controller.isFresher.value,
            onChanged: (v) => controller.isFresher.value = v ?? false,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.getPrimary(isDark),
          ),
          if (!controller.isFresher.value) ...[
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
                        if (i > 0) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => controller.removeExperience(i)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: controller.experiences[i]['job_title'], decoration: _inputDeco('Job Title *', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 8),
                    TextField(controller: controller.experiences[i]['company_name'], decoration: _inputDeco('Company Name *', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: _inputDeco('Employment Type', isDark),
                      dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      value: controller.experiences[i]['employment_type'],
                      items: ['Full-time', 'Part-time', 'Contract', 'Internship', 'Freelance'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) {
                        controller.experiences[i]['employment_type'] = v ?? 'Full-time';
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: controller.experiences[i]['location'], decoration: _inputDeco('Location (Optional)', isDark), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.experiences[i]['start_date'], 
                            decoration: _inputDeco('Start Date *', isDark).copyWith(
                              suffixIcon: Icon(Icons.calendar_today, color: isDark ? Colors.white54 : Colors.black54),
                            ), 
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            readOnly: true,
                            onTap: () => controller.selectExperienceDate(Get.context!, controller.experiences[i]['start_date']),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!(controller.experiences[i]['is_current'] == true))
                          Expanded(
                            child: TextField(
                              controller: controller.experiences[i]['end_date'], 
                              decoration: _inputDeco('End Date', isDark).copyWith(
                                suffixIcon: Icon(Icons.calendar_today, color: isDark ? Colors.white54 : Colors.black54),
                              ), 
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              readOnly: true,
                              onTap: () => controller.selectExperienceDate(Get.context!, controller.experiences[i]['end_date']),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text('I currently work here', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14)),
                      value: controller.experiences[i]['is_current'] == true,
                      onChanged: (v) {
                        // Rebuild experience step to hide/show end_date dynamically
                        controller.experiences[i]['is_current'] = v;
                        if (v) {
                          controller.experiences[i]['end_date'].text = '';
                        }
                        controller.experiences.refresh();
                      },
                      activeColor: AppColors.getPrimary(isDark),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.experiences[i]['description'], 
                      decoration: _inputDeco('Job Description (Optional)', isDark), 
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: controller.addExperience,
              icon: const Icon(Icons.add),
              label: const Text('Add Experience'),
            ),
          ],
        ],
      )),
      isActive: controller.currentStep.value >= 3,
    );
  }

  Step _buildReviewStep(OnboardingController controller, bool isDark) {
    final stepLabels = [
      'Personal Details',
      'Skills',
      'Education',
      'Experience',
    ];
    
    final stepDescriptions = [
      'Add the key identity and contact details recruiters need first.',
      'List your strongest skills in a recruiter-friendly format.',
      'Add at least one education record to complete your academic background.',
      'Add work experience, or mark yourself as a fresher.',
    ];

    // Reactive complete check helper
    bool isStepComplete(int index) {
      if (index == 0) {
        return controller.nameController.text.isNotEmpty &&
            controller.phoneController.text.isNotEmpty &&
            controller.locationController.text.isNotEmpty &&
            controller.gender.value.isNotEmpty &&
            controller.dateOfBirthController.text.isNotEmpty &&
            controller.bioController.text.isNotEmpty;
      } else if (index == 1) {
        return controller.skillsController.text.isNotEmpty;
      } else if (index == 2) {
        return controller.educations.isNotEmpty;
      } else if (index == 3) {
        return controller.isFresher.value || controller.experiences.isNotEmpty;
      }
      return false;
    }

    return Step(
      title: Text('Review', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      content: Obx(() => Column(
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
                          color: isStepComplete(i) 
                              ? Colors.green.withOpacity(0.1) 
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isStepComplete(i) ? 'Done' : 'Pending',
                          style: TextStyle(
                            color: isStepComplete(i) ? Colors.green : Colors.orange,
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
      )),
      isActive: controller.currentStep.value >= 4,
    );
  }
}
