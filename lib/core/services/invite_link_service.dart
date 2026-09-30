import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_navigator.dart';
import '../../features/create_slam/presentation/screens/create_slam_flow_screen.dart';
import 'analytics_service.dart';
import 'auth_service.dart';
import 'slam_firestore_service.dart';

class InviteLinkService {
  InviteLinkService._();

  static final InviteLinkService instance = InviteLinkService._();

  static const String inviteHost = 'slamora.com';
  static const String invitePathPrefix = '/i';
  static const String androidPackageName = 'com.smartappsin.slamora';
  static const MethodChannel _inviteReferrerChannel = MethodChannel(
    'slamora/invite_referrer',
  );

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastHandledInviteCode;
  String? _pendingInviteCode;

  Uri buildInviteUri(String inviteCode) {
    return Uri.https(inviteHost, '$invitePathPrefix/$inviteCode');
  }

  String buildInviteMessage(String inviteCode) {
    return 'Fill my Slamora memory here: ${buildInviteUri(inviteCode)}';
  }

  Future<void> start() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }
    await _handleInstallReferrer();

    await _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleUri);
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  Future<void> copyInviteLink(String inviteCode) async {
    await Clipboard.setData(
      ClipboardData(text: buildInviteUri(inviteCode).toString()),
    );
  }

  Future<void> shareInvite(String inviteCode) async {
    await SharePlus.instance.share(
      ShareParams(text: buildInviteMessage(inviteCode)),
    );
  }

  Future<void> shareInviteOnWhatsapp(String inviteCode) async {
    final message = Uri.encodeComponent(buildInviteMessage(inviteCode));
    final whatsappUri = Uri.parse('whatsapp://send?text=$message');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      return;
    }

    await shareInvite(inviteCode);
  }

  Future<String> createInviteLink({required String ownerUserId}) async {
    final inviteCode = await SlamFirestoreService.instance.createInvite(
      ownerUserId: ownerUserId,
    );
    return buildInviteUri(inviteCode).toString();
  }

  Uri buildPlayStoreFallbackUri(String inviteCode) {
    return Uri.https('play.google.com', '/store/apps/details', {
      'id': androidPackageName,
      'referrer': 'invite_code=$inviteCode',
    });
  }

  Future<void> _handleInstallReferrer() async {
    try {
      final referrer = await _inviteReferrerChannel.invokeMethod<String>(
        'getInstallReferrer',
      );
      final inviteCode = parseInviteCodeFromReferrer(referrer);
      if (inviteCode != null) {
        handleInviteCode(inviteCode);
      }
    } catch (_) {
      return;
    }
  }

  String? parseInviteCodeFromReferrer(String? referrer) {
    if (referrer == null || referrer.trim().isEmpty) {
      return null;
    }

    final params = Uri.splitQueryString(referrer);
    final inviteCode = params['invite_code']?.trim();
    return inviteCode == null || inviteCode.isEmpty ? null : inviteCode;
  }

  void _handleUri(Uri uri) {
    final inviteCode = parseInviteCode(uri);
    if (inviteCode == null || inviteCode == _lastHandledInviteCode) {
      return;
    }

    _lastHandledInviteCode = inviteCode;
    handleInviteCode(inviteCode);
  }

  void handleInviteCode(String inviteCode) {
    final trimmedInviteCode = inviteCode.trim();
    if (trimmedInviteCode.isEmpty) {
      return;
    }

    unawaited(AnalyticsService.instance.inviteLinkOpened());

    if (AuthService.instance.currentUser == null) {
      _pendingInviteCode = trimmedInviteCode;
      return;
    }

    _pendingInviteCode = null;
    _openCreateSlamFlow(trimmedInviteCode);
  }

  void openPendingInviteAfterLogin() {
    final inviteCode = _pendingInviteCode;
    if (inviteCode == null || AuthService.instance.currentUser == null) {
      return;
    }

    _pendingInviteCode = null;
    _openCreateSlamFlow(inviteCode);
  }

  String? parseInviteCode(Uri uri) {
    if (uri.scheme == 'slamora' && uri.host == 'invite') {
      final inviteCode = uri.pathSegments.isEmpty
          ? ''
          : uri.pathSegments.first.trim();
      return inviteCode.isEmpty ? null : inviteCode;
    }

    if (uri.host != inviteHost || uri.pathSegments.length < 2) {
      return null;
    }

    if (uri.pathSegments.first != invitePathPrefix.replaceFirst('/', '')) {
      return null;
    }

    final inviteCode = uri.pathSegments[1].trim();
    return inviteCode.isEmpty ? null : inviteCode;
  }

  void _openCreateSlamFlow(String inviteCode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null) {
        return;
      }

      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => CreateSlamFlowScreen(inviteCode: inviteCode),
        ),
      );
    });
  }
}
