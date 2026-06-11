class Recruiter {
  final String id;
  final String fullName;
  final String companyName;
  final String? companyWebsite;
  final String? companyLocation;
  final String email;
  final String phone;
  final String? designation;
  final String? profileImage;
  final String accountType;
  final String? companyId;
  final String? companyLogo;

  Recruiter({
    required this.id,
    required this.fullName,
    required this.companyName,
    this.companyWebsite,
    this.companyLocation,
    required this.email,
    required this.phone,
    this.designation,
    this.profileImage,
    this.accountType = 'basic',
    this.companyId,
    this.companyLogo,
  });

  factory Recruiter.fromJson(Map<String, dynamic> json) {
    return Recruiter(
      id: (json['id'] ?? json['recruiter_id']).toString(),
      fullName: json['full_name'] ?? '',
      companyName: json['company_name'] ?? '',
      companyWebsite: json['company_website'] ?? json['website'],
      companyLocation: json['company_location'] ?? json['location'] ?? json['job_location'],
      email: json['email'] ?? json['official_email'] ?? '',
      phone: json['phone'] ?? '',
      designation: json['designation'] ?? 'Recruitment Partner',
      profileImage: json['profile_image'],
      accountType: json['account_type'] ?? 'basic',
      companyId: json['company_id']?.toString(),
      companyLogo: json['company_logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'company_name': companyName,
      'company_website': companyWebsite,
      'company_location': companyLocation,
      'email': email,
      'phone': phone,
      'designation': designation,
      'profile_image': profileImage,
      'account_type': accountType,
      'company_id': companyId,
      'company_logo': companyLogo,
    };
  }
}
