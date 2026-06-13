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
    );
  }
}
