class SavedAccount {
  final String id;
  final String name;
  final String email;
  final String company;
  final String? profileImage;
  final String token;

  SavedAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.company,
    this.profileImage,
    required this.token,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'company': company,
    'profileImage': profileImage,
    'token': token,
  };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    company: json['company'],
    profileImage: json['profileImage'],
    token: json['token'],
  );
}
