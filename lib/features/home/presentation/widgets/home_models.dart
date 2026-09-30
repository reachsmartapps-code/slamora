import 'package:flutter/material.dart';

class SlamFriend {
  const SlamFriend({
    required this.name,
    required this.colors,
    required this.hairColor,
  });

  final String name;
  final List<Color> colors;
  final Color hairColor;
}

class SlamActivity {
  const SlamActivity({
    required this.icon,
    required this.title,
    required this.timeAgo,
  });

  final IconData icon;
  final String title;
  final String timeAgo;
}

class GiftIdea {
  const GiftIdea({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.tag,
    required this.kind,
    required this.tagColor,
  });

  final String title;
  final String subtitle;
  final String price;
  final String tag;
  final GiftVisualKind kind;
  final Color tagColor;
}

enum GiftVisualKind { watch, notebook, mug }
