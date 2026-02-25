import 'agent.dart';

enum SubmoltListSort { popular, new_, top }

extension SubmoltListSortX on SubmoltListSort {
  String get apiValue {
    switch (this) {
      case SubmoltListSort.popular:
        return 'popular';
      case SubmoltListSort.new_:
        return 'new';
      case SubmoltListSort.top:
        return 'top';
    }
  }
}

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
    final createdBy = json['created_by'] as Map<String, dynamic>?;
    return Submolt(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String? ?? json['displayName'] as String?,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String? ?? json['iconUrl'] as String?,
      bannerUrl: json['banner_url'] as String? ?? json['bannerUrl'] as String?,
      subscriberCount: (json['subscriber_count'] as num?)?.toInt() ?? (json['subscriberCount'] as num?)?.toInt() ?? 0,
      postCount: (json['post_count'] as num?)?.toInt() ?? (json['postCount'] as num?)?.toInt(),
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? json['creatorId'] as String?,
      creatorName: (createdBy?['name'] as String?) ?? json['creatorName'] as String?,
      isSubscribed: json['is_subscribed'] as bool? ?? json['isSubscribed'] as bool?,
      isNsfw: json['is_nsfw'] as bool? ?? json['isNsfw'] as bool?,
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
      yourRole: json['your_role'] as String? ?? json['yourRole'] as String?,
    );
  }
}
