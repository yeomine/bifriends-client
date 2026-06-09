class GuardianMission {
  final String praisePhrase;
  final String activitySuggestion;

  const GuardianMission({
    required this.praisePhrase,
    required this.activitySuggestion,
  });

  factory GuardianMission.fromJson(Map<String, dynamic> json) {
    return GuardianMission(
      praisePhrase: json['praise'] as String? ?? '',
      activitySuggestion: json['activity'] as String? ?? '',
    );
  }

  bool get isReady => praisePhrase.isNotEmpty || activitySuggestion.isNotEmpty;
}
