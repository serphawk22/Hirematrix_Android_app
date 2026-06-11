class Application {
  final String applicationId;
  final String candidateName;
  final String candidateEmail;
  final List<String> skills;
  final String experience;
  final String resumeLink;
  final String resumeUrl;
  final String location;
  final String status;
  final String appliedJob;
  final String recruiterId;
  final String? companyId;
  final String? jobId;
  final double matchScore;
  final DateTime appliedAt;

  Application({
    required this.applicationId,
    required this.candidateName,
    required this.candidateEmail,
    required this.skills,
    required this.experience,
    required this.resumeLink,
    required this.resumeUrl,
    required this.location,
    required this.status,
    required this.appliedJob,
    required this.recruiterId,
    this.companyId,
    this.jobId,
    this.matchScore = 0.0,
    required this.appliedAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      applicationId:
          json['application_id']?.toString() ?? json['id']?.toString() ?? '',
      candidateName: json['candidate_name'] ?? json['name'] ?? 'N/A',
      candidateEmail: json['candidate_email'] ?? json['email'] ?? '',
      skills: (json['skills'] is String)
          ? (json['skills'] as String)
              .split(',')
              .where((s) => s.trim().isNotEmpty)
              .toList()
          : List<String>.from(json['skills'] ?? []),
      experience: json['experience'] ?? 'N/A',
      resumeLink: json['resume_link'] ?? json['resume'] ?? '',
      resumeUrl:
          json['resume_url'] ?? json['resume_link'] ?? json['resume'] ?? '',
      location: json['location'] ?? json['candidate_location'] ?? '',
      status: json['status'] ?? 'Applied',
      appliedJob: json['job_title'] ?? json['applied_job'] ?? '',
      recruiterId: json['recruiter_id']?.toString() ??
          json['recruiterId']?.toString() ??
          '',
      companyId: json['company_id']?.toString(),
      jobId: json['job_id']?.toString(),
      matchScore: double.tryParse('${json['match_score'] ?? 0}') ?? 0.0,
      appliedAt:
          DateTime.tryParse(json['applied_at'] ?? json['created_at'] ?? '') ??
              DateTime.now(),
    );
  }
}
