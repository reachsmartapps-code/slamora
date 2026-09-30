class IdeasRequest {
  const IdeasRequest({
    required this.name,
    required this.event,
    this.relation,
    this.dob,
    this.gender,
    this.language = 'English',
    this.interests = const [],
    this.favoriteColor,
    this.favourites = const {},
    this.budget,
    this.tone,
  });

  final String name;
  final String event;
  final String? relation;
  final String? dob;
  final String? gender;
  final String language;
  final List<String> interests;
  final String? favoriteColor;
  final Map<String, String> favourites;
  final String? budget;
  final String? tone;

  Map<String, dynamic> toJson() {
    final resolvedFavoriteColor = favoriteColor?.trim().isNotEmpty == true
        ? favoriteColor!.trim()
        : favourites['colour']?.trim();

    return {
      'name': name,
      'dob': _apiDate(dob),
      'gender': _apiGender(gender),
      'language': language,
      'event': _titleCase(event),
      if (relation != null && relation!.trim().isNotEmpty)
        'relationship': relation,
      if (interests.isNotEmpty) 'interests': interests,
      if (resolvedFavoriteColor != null && resolvedFavoriteColor.isNotEmpty)
        'favourite_color': resolvedFavoriteColor,
      if (budget != null && budget!.trim().isNotEmpty) 'budget': budget,
      if (tone != null && tone!.trim().isNotEmpty) 'tone': tone,
    };
  }

  static String _apiDate(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '08/09/1990';
    }

    final slashParts = trimmed.split('/');
    if (slashParts.length == 3) {
      return trimmed;
    }

    final spaceParts = trimmed.split(RegExp(r'\s+'));
    if (spaceParts.length >= 3) {
      final day = int.tryParse(spaceParts[0]);
      final month = _monthNumber(spaceParts[1]);
      final year = int.tryParse(spaceParts[2]);

      if (day != null && month != null && year != null) {
        return '${day.toString().padLeft(2, '0')}/'
            '${month.toString().padLeft(2, '0')}/'
            '$year';
      }
    }

    return trimmed;
  }

  static String _apiGender(String? value) {
    final trimmed = value?.trim().toLowerCase() ?? '';
    return switch (trimmed) {
      'female' => 'female',
      'male' => 'male',
      _ => 'unspecified',
    };
  }

  static String _titleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Birthday';
    }

    return trimmed
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) {
            return word;
          }

          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  static int? _monthNumber(String value) {
    return switch (value.toLowerCase()) {
      'jan' || 'january' => 1,
      'feb' || 'february' => 2,
      'mar' || 'march' => 3,
      'apr' || 'april' => 4,
      'may' => 5,
      'jun' || 'june' => 6,
      'jul' || 'july' => 7,
      'aug' || 'august' => 8,
      'sep' || 'sept' || 'september' => 9,
      'oct' || 'october' => 10,
      'nov' || 'november' => 11,
      'dec' || 'december' => 12,
      _ => null,
    };
  }
}
