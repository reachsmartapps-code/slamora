import 'dart:math';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase/firebase_bootstrap.dart';
import '../firebase/firestore_collections.dart';

class SlamFirestoreService {
  SlamFirestoreService._();

  static final SlamFirestoreService instance = SlamFirestoreService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool get isAvailable => FirebaseBootstrap.isConfigured;

  Future<String> createInvite({required String ownerUserId}) async {
    final inviteCode = _createInviteCode();

    if (!isAvailable) {
      return inviteCode;
    }

    await _firestore
        .collection(FirestoreCollections.invites)
        .doc(inviteCode)
        .set({
          'code': inviteCode,
          'ownerUserId': ownerUserId,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    return inviteCode;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getInvite(String inviteCode) {
    return _firestore
        .collection(FirestoreCollections.invites)
        .doc(inviteCode)
        .get();
  }

  Future<void> saveSlam({
    required String inviteCode,
    required Map<String, Object?> slam,
  }) async {
    if (!isAvailable) {
      return;
    }

    final inviteRef = _firestore
        .collection(FirestoreCollections.invites)
        .doc(inviteCode);
    final inviteSnapshot = await inviteRef.get();
    final ownerUserId = inviteSnapshot
        .data()?['ownerUserId']
        ?.toString()
        .trim();
    if (ownerUserId == null || ownerUserId.isEmpty) {
      throw StateError('Invite link is invalid or expired.');
    }

    final slamRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(ownerUserId)
        .collection(FirestoreCollections.slams)
        .doc();
    final auditSlamRef = _firestore
        .collection(FirestoreCollections.slams)
        .doc(slamRef.id);
    final now = FieldValue.serverTimestamp();
    final memoryPhotos = await _uploadMemoryPhotos(
      localPaths: _stringList(slam['memoryPhotoPaths']),
      basePath: 'users/$ownerUserId/slams/${slamRef.id}/photos',
    );

    final batch = _firestore.batch();

    batch.set(slamRef, {
      'id': slamRef.id,
      'ownerUserId': ownerUserId,
      'filledByUserId': slam['ownerUserId'] ?? '',
      'inviteCode': inviteCode,
      'templateId': slam['templateId'] ?? 'default',
      'status': 'filled',
      'fullName': slam['fullName'] ?? '',
      'nickname': slam['nickname'] ?? '',
      'relation': slam['relation'] ?? '',
      'gender': slam['gender'] ?? '',
      'dateOfBirth': slam['dateOfBirth'] ?? '',
      'anniversary': slam['anniversary'] ?? '',
      'hasProfilePicture': slam['hasProfilePicture'] ?? false,
      'photoUrl': slam['photoUrl'] ?? '',
      'photoCount': memoryPhotos.length,
      'memoryPhotoUrls': memoryPhotos
          .map((photo) => photo.downloadUrl)
          .toList(),
      'memoryPhotoStoragePaths': memoryPhotos
          .map((photo) => photo.storagePath)
          .toList(),
      'reminders': {
        'birthday': {
          'enabled': false,
          'remindBeforeDays': 1,
          'nextReminderAt': null,
        },
        'anniversary': {
          'enabled': false,
          'remindBeforeDays': 1,
          'nextReminderAt': null,
        },
      },
      'createdAt': now,
      'updatedAt': now,
      'filledAt': now,
    });
    batch.set(slamRef.collection('sections').doc('about'), {
      'data': {
        'fullName': slam['fullName'] ?? '',
        'nickname': slam['nickname'] ?? '',
        'relation': slam['relation'] ?? '',
        'gender': slam['gender'] ?? '',
        'dateOfBirth': slam['dateOfBirth'] ?? '',
        'anniversary': slam['anniversary'] ?? '',
        'hasProfilePicture': slam['hasProfilePicture'] ?? false,
        'photoUrl': slam['photoUrl'] ?? '',
      },
      'updatedAt': now,
    });
    batch.set(slamRef.collection('sections').doc('interests'), {
      'data': {'values': slam['interests'] ?? <String>[]},
      'updatedAt': now,
    });
    batch.set(slamRef.collection('sections').doc('favourites'), {
      'data': slam['favourites'] ?? <String, Object?>{},
      'updatedAt': now,
    });
    batch.set(slamRef.collection('sections').doc('memories'), {
      'data': slam['memories'] ?? <String, Object?>{},
      'updatedAt': now,
    });
    batch.set(slamRef.collection('sections').doc('photos'), {
      'data': {
        'photoCount': memoryPhotos.length,
        'items': memoryPhotos.map((photo) => photo.toMap()).toList(),
        'urls': memoryPhotos.map((photo) => photo.downloadUrl).toList(),
        'storagePaths': memoryPhotos.map((photo) => photo.storagePath).toList(),
      },
      'updatedAt': now,
    });
    batch.set(auditSlamRef, {
      ..._sanitizedSlamData(slam),
      'id': slamRef.id,
      'ownerUserId': ownerUserId,
      'filledByUserId': slam['ownerUserId'] ?? '',
      'inviteCode': inviteCode,
      'photoCount': memoryPhotos.length,
      'memoryPhotoUrls': memoryPhotos
          .map((photo) => photo.downloadUrl)
          .toList(),
      'memoryPhotoStoragePaths': memoryPhotos
          .map((photo) => photo.storagePath)
          .toList(),
      'memoryPhotos': memoryPhotos.map((photo) => photo.toMap()).toList(),
      'createdAt': now,
      'updatedAt': now,
    });
    batch.update(inviteRef, {
      'status': 'completed',
      'completedSlamId': slamRef.id,
      'updatedAt': now,
    });

    await batch.commit();
  }

  Future<String?> saveOwnSlam({
    required String ownerUserId,
    required Map<String, Object?> slam,
  }) async {
    if (!isAvailable) {
      return null;
    }

    final slamRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(ownerUserId)
        .collection(FirestoreCollections.slams)
        .doc();
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    final photoUrl = await _profilePhotoUrlForOwnSlam(
      ownerUserId: ownerUserId,
      slamId: slamRef.id,
      slam: slam,
    );
    final memoryPhotos = await _uploadMemoryPhotos(
      localPaths: _stringList(slam['memoryPhotoPaths']),
      basePath: 'users/$ownerUserId/slams/${slamRef.id}/photos',
    );

    batch.set(slamRef, {
      'id': slamRef.id,
      'ownerUserId': ownerUserId,
      'templateId': slam['templateId'] ?? 'default',
      'status': 'filled',
      'fullName': slam['fullName'] ?? '',
      'nickname': slam['nickname'] ?? '',
      'relation': slam['relation'] ?? '',
      'gender': slam['gender'] ?? '',
      'dateOfBirth': slam['dateOfBirth'] ?? '',
      'anniversary': slam['anniversary'] ?? '',
      'hasProfilePicture': photoUrl.isNotEmpty,
      'photoUrl': photoUrl,
      'photoCount': memoryPhotos.length,
      'memoryPhotoUrls': memoryPhotos
          .map((photo) => photo.downloadUrl)
          .toList(),
      'memoryPhotoStoragePaths': memoryPhotos
          .map((photo) => photo.storagePath)
          .toList(),
      'reminders': {
        'birthday': {
          'enabled': false,
          'remindBeforeDays': 1,
          'nextReminderAt': null,
        },
        'anniversary': {
          'enabled': false,
          'remindBeforeDays': 1,
          'nextReminderAt': null,
        },
      },
      'createdAt': now,
      'updatedAt': now,
      'filledAt': now,
    });

    batch.set(slamRef.collection('sections').doc('about'), {
      'data': {
        'fullName': slam['fullName'] ?? '',
        'nickname': slam['nickname'] ?? '',
        'relation': slam['relation'] ?? '',
        'gender': slam['gender'] ?? '',
        'dateOfBirth': slam['dateOfBirth'] ?? '',
        'anniversary': slam['anniversary'] ?? '',
        'hasProfilePicture': photoUrl.isNotEmpty,
        'photoUrl': photoUrl,
      },
      'updatedAt': now,
    });

    batch.set(slamRef.collection('sections').doc('interests'), {
      'data': {'values': slam['interests'] ?? <String>[]},
      'updatedAt': now,
    });

    batch.set(slamRef.collection('sections').doc('favourites'), {
      'data': slam['favourites'] ?? <String, Object?>{},
      'updatedAt': now,
    });

    batch.set(slamRef.collection('sections').doc('memories'), {
      'data': slam['memories'] ?? <String, Object?>{},
      'updatedAt': now,
    });

    batch.set(slamRef.collection('sections').doc('photos'), {
      'data': {
        'photoCount': memoryPhotos.length,
        'items': memoryPhotos.map((photo) => photo.toMap()).toList(),
        'urls': memoryPhotos.map((photo) => photo.downloadUrl).toList(),
        'storagePaths': memoryPhotos.map((photo) => photo.storagePath).toList(),
      },
      'updatedAt': now,
    });

    await batch.commit();
    return slamRef.id;
  }

  Future<void> updateSlamReminder({
    required String ownerUserId,
    required String slamId,
    required String reminderType,
    required bool enabled,
    required int remindBeforeDays,
    required String eventDate,
  }) async {
    if (!isAvailable) {
      return;
    }

    final nextReminderAt = enabled
        ? _nextReminderAt(eventDate, remindBeforeDays)
        : null;

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(ownerUserId)
        .collection(FirestoreCollections.slams)
        .doc(slamId)
        .update({
          'reminders.$reminderType': {
            'enabled': enabled,
            'remindBeforeDays': remindBeforeDays,
            'nextReminderAt': nextReminderAt,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<String> _profilePhotoUrlForOwnSlam({
    required String ownerUserId,
    required String slamId,
    required Map<String, Object?> slam,
  }) async {
    final existingUrl = slam['photoUrl']?.toString().trim() ?? '';
    if (existingUrl.isNotEmpty) {
      return existingUrl;
    }

    final localPhotoPath = slam['localPhotoPath']?.toString().trim() ?? '';
    if (localPhotoPath.isEmpty) {
      return '';
    }

    final file = File(localPhotoPath);
    if (!file.existsSync()) {
      return '';
    }

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(ownerUserId)
        .child('slams')
        .child(slamId)
        .child('profile.jpg');

    await storageRef.putFile(file);
    return storageRef.getDownloadURL();
  }

  Future<List<_UploadedSlamPhoto>> _uploadMemoryPhotos({
    required List<String> localPaths,
    required String basePath,
  }) async {
    final uploadedPhotos = <_UploadedSlamPhoto>[];

    for (final indexedPath in localPaths.indexed) {
      final file = File(indexedPath.$2);
      if (!file.existsSync()) {
        continue;
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child(basePath)
          .child('memory_${indexedPath.$1 + 1}.jpg');

      await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadedPhotos.add(
        _UploadedSlamPhoto(
          downloadUrl: await storageRef.getDownloadURL(),
          storagePath: storageRef.fullPath,
        ),
      );
    }

    return uploadedPhotos;
  }

  List<String> _stringList(Object? value) {
    if (value is! Iterable) {
      return const [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, Object?> _sanitizedSlamData(Map<String, Object?> slam) {
    return Map<String, Object?>.from(slam)
      ..remove('localPhotoPath')
      ..remove('memoryPhotoPaths');
  }

  Map<String, Object?> _mapValue(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  Future<void> _deleteStorageObject(String storagePath) async {
    try {
      await FirebaseStorage.instance.ref(storagePath).delete();
    } on FirebaseException catch (error) {
      const nonBlockingCodes = {
        'object-not-found',
        'unauthorized',
        'permission-denied',
      };
      if (!nonBlockingCodes.contains(error.code)) {
        rethrow;
      }
    }
  }

  Future<void> _deleteDocumentIfAllowed(
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    try {
      await docRef.delete();
    } on FirebaseException catch (error) {
      const nonBlockingCodes = {'permission-denied', 'not-found'};
      if (!nonBlockingCodes.contains(error.code)) {
        rethrow;
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSlamsForUser(
    String ownerUserId,
  ) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(ownerUserId)
        .collection(FirestoreCollections.slams)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, Object?>> getSlamDetail({
    required String ownerUserId,
    required String slamId,
  }) async {
    final slamRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(ownerUserId)
        .collection(FirestoreCollections.slams)
        .doc(slamId);

    final slamSnapshot = await slamRef.get();
    final sectionsSnapshot = await slamRef.collection('sections').get();
    final sections = <String, Object?>{};

    for (final doc in sectionsSnapshot.docs) {
      sections[doc.id] = doc.data()['data'];
    }

    return {
      'slam': slamSnapshot.data() ?? <String, Object?>{},
      'sections': sections,
    };
  }

  Future<void> deleteSlam({
    required String ownerUserId,
    required String slamId,
  }) async {
    if (!isAvailable) {
      return;
    }

    final slamRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(ownerUserId)
        .collection(FirestoreCollections.slams)
        .doc(slamId);
    final auditSlamRef = _firestore
        .collection(FirestoreCollections.slams)
        .doc(slamId);

    final slamSnapshot = await slamRef.get();
    final sectionsSnapshot = await slamRef.collection('sections').get();
    final storagePaths = <String>{
      ..._stringList(slamSnapshot.data()?['memoryPhotoStoragePaths']),
      'users/$ownerUserId/slams/$slamId/profile.jpg',
    };

    for (final section in sectionsSnapshot.docs) {
      final data = _mapValue(section.data()['data']);
      storagePaths.addAll(_stringList(data['storagePaths']));

      final items = data['items'];
      if (items is Iterable) {
        for (final item in items) {
          storagePaths.add(_mapValue(item)['storagePath']?.toString() ?? '');
        }
      }
    }

    await Future.wait(
      storagePaths
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty)
          .map(_deleteStorageObject),
    );

    final batch = _firestore.batch();
    for (final section in sectionsSnapshot.docs) {
      batch.delete(section.reference);
    }
    batch.delete(slamRef);
    await batch.commit();

    await _deleteDocumentIfAllowed(auditSlamRef);
  }

  String _createInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final random = Random.secure();

    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Timestamp? _nextReminderAt(String eventDate, int remindBeforeDays) {
    final parsed = _parseDayMonth(eventDate);
    if (parsed == null) {
      return null;
    }

    final now = DateTime.now();
    var nextEvent = DateTime(now.year, parsed.$2, parsed.$1, 9);
    var nextReminder = nextEvent.subtract(Duration(days: remindBeforeDays));
    if (!nextReminder.isAfter(now)) {
      nextEvent = DateTime(now.year + 1, parsed.$2, parsed.$1, 9);
      nextReminder = nextEvent.subtract(Duration(days: remindBeforeDays));
    }

    return Timestamp.fromDate(nextReminder);
  }

  (int, int)? _parseDayMonth(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return null;
    }

    final day = int.tryParse(parts.first);
    final month = _monthNumber(parts[1]);
    if (day == null || month == null) {
      return null;
    }

    return (day, month);
  }

  int? _monthNumber(String value) {
    return const {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    }[value.trim().toLowerCase()];
  }
}

class _UploadedSlamPhoto {
  const _UploadedSlamPhoto({
    required this.downloadUrl,
    required this.storagePath,
  });

  final String downloadUrl;
  final String storagePath;

  Map<String, String> toMap() {
    return {'url': downloadUrl, 'storagePath': storagePath};
  }
}
