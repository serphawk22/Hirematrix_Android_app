class Job {
  final String jobId;
  final String recruiterId;
  final String? companyId;
  final String jobTitle;
  final String? department;
  final String jobType;
  final String workMode;
  final String? location;
  final String experience;
  final String? salary;
  final String? description;
  final String status;
  final Map<String, int>? pipeline;
  final int? applicationsCount;
  final int? shortlistedCount;
  final DateTime createdAt;

  // Additional fields for editing
  final String? category;
  final String? requiredSkills;
  final String? postedFor;
  final String? clientCompanyName;
  final String? clientDisclosure;
  final String? payrollType;
  final String? applicationDeadline;
  final int? openings;
  final String? aiInterviewPolicy;
  final int? minAiCutoffScore;
  final String? applicationQuestionnaire;

  Job({
    required this.jobId,
    required this.recruiterId,
    this.companyId,
    required this.jobTitle,
    this.department,
    required this.jobType,
    required this.workMode,
    this.location,
    required this.experience,
    this.salary,
    this.description,
    required this.status,
    this.pipeline,
    this.applicationsCount = 0,
    this.shortlistedCount = 0,
    required this.createdAt,
    this.category,
    this.requiredSkills,
    this.postedFor,
    this.clientCompanyName,
    this.clientDisclosure,
    this.payrollType,
    this.applicationDeadline,
    this.openings,
    this.aiInterviewPolicy,
    this.minAiCutoffScore,
    this.applicationQuestionnaire,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      jobId: (json['job_id'] ?? json['id']).toString(),
      recruiterId: json['recruiter_id'].toString(),
      companyId: json['company_id']?.toString(),
      jobTitle: json['job_title'] ?? '',
      department: json['department'],
      jobType: json['job_type'] ?? 'Full Time',
      workMode: json['work_mode'] ?? 'Onsite',
      location: json['location'],
      experience: json['experience_required'] ?? 'N/A',
      salary: json['salary_range'],
      description: json['description'] ?? json['job_description'],
      status: (() {
        final rawStatus = (json['job_status'] ?? json['status'] ?? 'Active').toString().toLowerCase();
        if (rawStatus == 'open' || rawStatus == 'active') return 'Active';
        if (rawStatus == 'closed') return 'Closed';
        if (rawStatus == 'draft') return 'Draft';
        if (rawStatus == 'expired') return 'Expired';
        // Capitalize default fallback
        if (rawStatus.isNotEmpty) {
          return rawStatus[0].toUpperCase() + rawStatus.substring(1);
        }
        return 'Active';
      })(),
      pipeline: json['pipeline'] != null ? Map<String, int>.from(json['pipeline']) : null,
      applicationsCount: int.tryParse(json['applications_count']?.toString() ?? '') ?? 0,
      shortlistedCount: int.tryParse(json['shortlisted_count']?.toString() ?? '') ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      category: json['category'],
      requiredSkills: json['required_skills'],
      postedFor: json['posted_for'],
      clientCompanyName: json['client_company_name'],
      clientDisclosure: json['client_disclosure'],
      payrollType: json['payroll_type'],
      applicationDeadline: json['application_deadline'],
      openings: int.tryParse(json['openings']?.toString() ?? ''),
      aiInterviewPolicy: json['ai_interview_policy'],
      minAiCutoffScore: int.tryParse(json['min_ai_cutoff_score']?.toString() ?? ''),
      applicationQuestionnaire: json['application_questionnaire'],
    );
  }
}
