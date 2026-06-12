class Candidate {
  final String id;
  final String name;
  final String email;
  final String location;
  final String resumePath;
  final String profilePhoto;
  final String profilePhotoUrl;
  final String skillName;
  final String experienceDisplay;
  final int totalExperienceMonths;
  final double matchScore;
  final String matchReason;
  final DateTime createdAt;

  Candidate({
    required this.id,
    required this.name,
    required this.email,
    required this.location,
    required this.resumePath,
    required this.profilePhoto,
    required this.profilePhotoUrl,
    required this.skillName,
    required this.experienceDisplay,
    required this.totalExperienceMonths,
    this.matchScore = 0.0,
    this.matchReason = '',
    required this.createdAt,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'N/A',
      email: json['email'] ?? '',
      location: json['location'] ?? 'N/A',
      resumePath: json['resume_path'] ?? '',
      profilePhoto: json['profile_photo'] ?? '',
      profilePhotoUrl: json['profile_photo_url'] ?? '',
      skillName: json['skill_name'] ?? '',
      experienceDisplay: json['experience_display'] ?? '-',
      totalExperienceMonths: int.tryParse(json['total_experience_months']?.toString() ?? '0') ?? 0,
      matchScore: double.tryParse(json['match_score']?.toString() ?? '0.0') ?? 0.0,
      matchReason: json['match_reason'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
