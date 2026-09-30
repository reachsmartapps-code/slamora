import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../firebase/firebase_bootstrap.dart';
import '../firebase/firestore_collections.dart';

class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  bool _hasShownOptionalUpdate = false;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<AppUpdateInfo?> getUpdateInfo() async {
    if (!FirebaseBootstrap.isConfigured) {
      return null;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final snapshot = await _firestore
        .collection(FirestoreCollections.appConfig)
        .doc('update')
        .get();
    final data = snapshot.data();
    if (data == null || data['enabled'] == false) {
      return null;
    }

    final currentVersion =
        _AppVersion.parse(
          packageInfo.version,
          buildNumber: packageInfo.buildNumber,
        ) ??
        const _AppVersion(0, 0, 0, 0);
    final minimumVersion = _AppVersion.parse(
      _stringValue(data['minimumVersion']),
      buildNumber: _stringValue(data['minimumBuildNumber']),
    );
    final latestVersion = _AppVersion.parse(
      _stringValue(data['latestVersion']),
      buildNumber: _stringValue(data['latestBuildNumber']),
    );

    final requiresUpdate =
        minimumVersion != null && currentVersion < minimumVersion;
    final hasOptionalUpdate =
        latestVersion != null && currentVersion < latestVersion;

    if (!requiresUpdate && !hasOptionalUpdate) {
      return null;
    }
    if (!requiresUpdate && _hasShownOptionalUpdate) {
      return null;
    }

    if (!requiresUpdate) {
      _hasShownOptionalUpdate = true;
    }

    return AppUpdateInfo(
      forceUpdate: requiresUpdate || data['forceUpdate'] == true,
      title: _stringValue(data['title'], fallback: 'Update Slamora'),
      message: _stringValue(
        data['message'],
        fallback: 'A newer version of Slamora is available.',
      ),
      updateUrl: _storeUrl(data),
      currentVersion: packageInfo.version,
      latestVersion: latestVersion?.displayValue ?? '',
    );
  }

  String _storeUrl(Map<String, dynamic> data) {
    final platformUrl = Platform.isIOS
        ? _stringValue(data['iosUrl'])
        : _stringValue(data['androidUrl']);
    if (platformUrl.isNotEmpty) {
      return platformUrl;
    }

    return _stringValue(data['storeUrl']);
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.forceUpdate,
    required this.title,
    required this.message,
    required this.updateUrl,
    required this.currentVersion,
    required this.latestVersion,
  });

  final bool forceUpdate;
  final String title;
  final String message;
  final String updateUrl;
  final String currentVersion;
  final String latestVersion;
}

class _AppVersion implements Comparable<_AppVersion> {
  const _AppVersion(this.major, this.minor, this.patch, this.buildNumber);

  final int major;
  final int minor;
  final int patch;
  final int buildNumber;

  String get displayValue => '$major.$minor.$patch';

  static _AppVersion? parse(String version, {String buildNumber = ''}) {
    final cleanVersion = version.trim();
    if (cleanVersion.isEmpty) {
      return null;
    }

    final versionParts = cleanVersion.split('+');
    final numbers = versionParts.first
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
    while (numbers.length < 3) {
      numbers.add(0);
    }

    final build = int.tryParse(
      buildNumber.trim().isNotEmpty
          ? buildNumber.trim()
          : versionParts.length > 1
          ? versionParts.last.trim()
          : '0',
    );

    return _AppVersion(numbers[0], numbers[1], numbers[2], build ?? 0);
  }

  @override
  int compareTo(_AppVersion other) {
    final currentParts = [major, minor, patch, buildNumber];
    final otherParts = [
      other.major,
      other.minor,
      other.patch,
      other.buildNumber,
    ];

    for (var index = 0; index < currentParts.length; index += 1) {
      final result = currentParts[index].compareTo(otherParts[index]);
      if (result != 0) {
        return result;
      }
    }

    return 0;
  }

  bool operator <(_AppVersion other) => compareTo(other) < 0;
}
