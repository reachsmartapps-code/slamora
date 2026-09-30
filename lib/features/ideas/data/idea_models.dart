class GiftIdea {
  const GiftIdea({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
  });

  final int id;
  final String title;
  final String icon;
  final String description;

  factory GiftIdea.fromJson(Map<String, dynamic> json) {
    return GiftIdea(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      icon: json['icon'] as String? ?? '🎁',
      description: json['description'] as String? ?? '',
    );
  }
}

class MessageIdea {
  const MessageIdea({required this.id, required this.wish});

  final int id;
  final String wish;

  factory MessageIdea.fromJson(Map<String, dynamic> json) {
    return MessageIdea(
      id: (json['id'] as num?)?.toInt() ?? 0,
      wish: json['wish'] as String? ?? '',
    );
  }
}
