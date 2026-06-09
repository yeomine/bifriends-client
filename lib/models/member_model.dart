class Member {
  final int? id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final String? nickname;
  final int? grade;
  final List<String> interests;
  final String? guardianPhone;
  final bool notificationEnabled;
  final bool microphoneEnabled;
  final bool onboardingCompleted;
  final String? representativeItemType;

  Member({
    this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    this.nickname,
    this.grade,
    this.interests = const [],
    this.guardianPhone,
    required this.notificationEnabled,
    required this.microphoneEnabled,
    required this.onboardingCompleted,
    this.representativeItemType,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int?,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      nickname: json['nickname'] as String?,
      grade: json['grade'] as int?,
      interests:
          (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      guardianPhone: json['guardianPhone'] as String?,
      notificationEnabled: json['notificationEnabled'] as bool? ?? false,
      microphoneEnabled: json['microphoneEnabled'] as bool? ?? false,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      representativeItemType: json['representativeItemType'] as String?,
    );
  }

  String get displayNickname => nickname ?? '친구';
  int get displayGrade => grade ?? 4;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'nickname': nickname,
      'grade': grade,
      'interests': interests,
      'guardianPhone': guardianPhone,
      'notificationEnabled': notificationEnabled,
      'microphoneEnabled': microphoneEnabled,
      'onboardingCompleted': onboardingCompleted,
      'representativeItemType': representativeItemType,
    };
  }
}
