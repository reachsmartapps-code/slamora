import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/slam_firestore_service.dart';
import '../../../home/presentation/widgets/home_models.dart';
import 'my_slam_detail_screen.dart';
import '../widgets/my_slam_person_card.dart';
import '../widgets/my_slam_search_field.dart';

class MySlamScreen extends StatefulWidget {
  const MySlamScreen({super.key});

  @override
  State<MySlamScreen> createState() => _MySlamScreenState();
}

class _MySlamScreenState extends State<MySlamScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  static const _people = [
    MySlamPerson(
      friend: SlamFriend(
        name: 'Amit',
        colors: [Color(0xFFF8D4B8), Color(0xFF243D73)],
        hairColor: Color(0xFF151515),
      ),
      fullName: 'Amit Sharma',
      relation: 'Best friend',
      date: '28 Aug',
      memories: 62,
    ),
    MySlamPerson(
      friend: SlamFriend(
        name: 'Neha',
        colors: [Color(0xFFFFD8C8), Color(0xFFBF4C3C)],
        hairColor: Color(0xFF4B2C21),
      ),
      fullName: 'Neha Verma',
      relation: 'Cousin',
      date: '12 Sep',
      memories: 49,
      favorite: true,
    ),
    MySlamPerson(
      friend: SlamFriend(
        name: 'Rahul',
        colors: [Color(0xFFF7D7C0), Color(0xFF224A73)],
        hairColor: Color(0xFF121212),
      ),
      fullName: 'Rahul Malhotra',
      relation: 'College Friend',
      date: '20 Sep',
      memories: 55,
    ),
    MySlamPerson(
      friend: SlamFriend(
        name: 'Priya',
        colors: [Color(0xFFFFDEC8), Color(0xFFE86755)],
        hairColor: Color(0xFF3D241C),
      ),
      fullName: 'Priya Nair',
      relation: 'Close Friend',
      date: '5 Oct',
      memories: 31,
    ),
    MySlamPerson(
      friend: SlamFriend(
        name: 'Karan',
        colors: [Color(0xFFF4D2B5), Color(0xFF203863)],
        hairColor: Color(0xFF2B211C),
      ),
      fullName: 'Karan Mehta',
      relation: 'Brother',
      date: '17 Oct',
      memories: 44,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 390 ? 16.0 : 20.0;
    final userId = AuthService.instance.currentUser?.uid;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  124,
                ),
                sliver: SliverList.list(
                  children: [
                    Text(
                      'My Slam',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),

                    const SizedBox(height: 18),
                    MySlamSearchField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 22),
                    if (userId == null)
                      ..._buildFilteredPeople(context, _people)
                    else
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: SlamFirestoreService.instance.watchSlamsForUser(
                          userId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _MySlamLoadingState();
                          }

                          if (snapshot.hasError) {
                            return const _MySlamMessageState(
                              icon: Icons.cloud_off_rounded,
                              message:
                                  'Could not load your slams. Please try again.',
                            );
                          }

                          final people =
                              snapshot.data?.docs
                                  .map(_personFromSlam)
                                  .toList() ??
                              [];
                          final filteredPeople = _filterPeople(people);

                          if (people.isEmpty) {
                            return const _MySlamMessageState(
                              icon: Icons.auto_stories_outlined,
                              message:
                                  'No slams yet. Tap + on Home to create one.',
                            );
                          }

                          if (filteredPeople.isEmpty) {
                            return _MySlamMessageState(
                              icon: Icons.search_off_rounded,
                              message:
                                  'No slams found for "${_searchController.text.trim()}".',
                            );
                          }

                          return Column(
                            children: _buildPeopleCards(
                              context,
                              filteredPeople,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFilteredPeople(
    BuildContext context,
    List<MySlamPerson> people,
  ) {
    final filteredPeople = _filterPeople(people);
    if (filteredPeople.isEmpty) {
      return [
        _MySlamMessageState(
          icon: Icons.search_off_rounded,
          message: 'No slams found for "${_searchController.text.trim()}".',
        ),
      ];
    }

    return _buildPeopleCards(context, filteredPeople);
  }

  List<MySlamPerson> _filterPeople(List<MySlamPerson> people) {
    if (_searchQuery.isEmpty) {
      return people;
    }

    return people.where((person) {
      final searchableText = [
        person.fullName,
        person.friend.name,
        person.relation,
        person.date,
      ].join(' ').toLowerCase();

      return searchableText.contains(_searchQuery);
    }).toList();
  }

  static List<Widget> _buildPeopleCards(
    BuildContext context,
    List<MySlamPerson> people,
  ) {
    return [
      for (final person in people) ...[
        MySlamPersonCard(
          person: person,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MySlamDetailScreen(person: person),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  static MySlamPerson _personFromSlam(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final fullName = _stringValue(data['fullName'], fallback: 'Untitled Slam');
    final nickname = _stringValue(data['nickname']);
    final relation = _stringValue(data['relation'], fallback: nickname);

    return MySlamPerson(
      id: doc.id,
      friend: SlamFriend(
        name: fullName,
        colors: const [Color(0xFFFFD8C8), Color(0xFFBF4C3C)],
        hairColor: const Color(0xFF4B2C21),
      ),
      fullName: fullName,
      relation: relation.isEmpty ? 'My Slam' : relation,
      date: _shortDate(_stringValue(data['dateOfBirth'])),
      memories: _intValue(data['photoCount']),
      photoUrl: _stringValue(data['photoUrl']),
      localPhotoPath: _stringValue(data['localPhotoPath']),
      favorite: data['favorite'] == true,
    );
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  static String _shortDate(String value) {
    final parts = value.split(' ');
    if (parts.length >= 2) {
      return '${parts[0]} ${parts[1]}';
    }
    return value.isEmpty ? 'No date' : value;
  }
}

class _MySlamLoadingState extends StatelessWidget {
  const _MySlamLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _MySlamMessageState extends StatelessWidget {
  const _MySlamMessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 34),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
