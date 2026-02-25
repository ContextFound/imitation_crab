import 'agent.dart';

class SubmoltRule {
  const SubmoltRule({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
  });

  final String id;
  final String title;
  final String description;
  final int order;

  factory SubmoltRule.fromJson(Map<String, dynamic> json) {
    return SubmoltRule(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

class Submolt {
  const Submolt({
    required this.id,
    required this.name,
    this.displayName,
    this.description,
    this.iconUrl,
    this.bannerUrl,
    required this.subscriberCount,
    this.postCount,
    required this.createdAt,
    this.creatorId,
    this.creatorName,
    this.isSubscribed,
    this.isNsfw,
    this.rules = const [],
    this.moderators = const [],
    this.yourRole,
  });

  final String id;
  final String name;
  final String? displayName;
  final String? description;
  final String? iconUrl;
  final String? bannerUrl;
  final int subscriberCount;
  final int? postCount;
  final String createdAt;
  final String? creatorId;
  final String? creatorName;
  final bool? isSubscribed;
  final bool? isNsfw;
  final List<SubmoltRule> rules;
  final List<Agent> moderators;
  final String? yourRole;

  String get displayOrName => displayName ?? name;

  factory Submolt.fromJson(Map<String, dynamic> json) {
    final rulesJson = json['rules'] as List<dynamic>?;
    final modsJson = json['moderators'] as List<dynamic>?;
    return Submolt(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String?,
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      subscriberCount: (json['subscriberCount'] as num?)?.toInt() ?? 0,
      postCount: (json['postCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String? ?? '',
      creatorId: json['creatorId'] as String?,
      creatorName: json['creatorName'] as String?,
      isSubscribed: json['isSubscribed'] as bool?,
      isNsfw: json['isNsfw'] as bool?,
      rules: rulesJson != null
          ? rulesJson
              .map((e) => SubmoltRule.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      moderators: modsJson != null
          ? modsJson
              .map((e) => Agent.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      yourRole: json['yourRole'] as String?,
    );
  }
}
