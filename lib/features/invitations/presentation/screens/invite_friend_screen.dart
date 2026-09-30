import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '/core/extensions/spacing_extensions.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_theme.dart';
import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/invite_link_service.dart';

class InviteFriendScreen extends StatefulWidget {
  const InviteFriendScreen({super.key});

  @override
  State<InviteFriendScreen> createState() => _InviteFriendScreenState();
}

class _InviteFriendScreenState extends State<InviteFriendScreen> {
  late final Future<String> _inviteCodeFuture;
  String? inviteCode;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _inviteCodeFuture = _createInviteCode()
      ..then((code) {
        if (!mounted) {
          return;
        }
        setState(() {
          inviteCode = code;
          isLoading = false;
        });
      }).catchError((Object _) {
        if (!mounted) {
          return;
        }
        setState(() => isLoading = false);
      });
  }

  Future<String> _createInviteCode() async {
    final ownerUserId =
        AuthService.instance.currentUser?.uid ??
        (FirebaseBootstrap.isConfigured ? null : 'local-demo-owner');
    if (ownerUserId == null) {
      throw StateError('You need to login before creating an invite.');
    }

    final link = await InviteLinkService.instance.createInviteLink(
      ownerUserId: ownerUserId,
    );
    return Uri.parse(link).pathSegments.last;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 390 ? 24.0 : 32.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppColors.primary,
          iconSize: 34,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Share the joy',
                      textAlign: TextAlign.center,
                      style: AppTextTheme.memoryTitle.copyWith(
                        fontSize: 42,
                        color: AppColors.primary,
                        height: 1.05,
                      ),
                    ),
                    10.h,
                    Text(
                      'Invite your friends to fill their\nslambook and be part of\nyour special moments.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    20.h,
                    const SizedBox(
                      width: 160,
                      height: 160,
                      child: _EnvelopeIllustration(),
                    ),
                    20.h,
                    FutureBuilder<String>(
                      future: _inviteCodeFuture,
                      builder: (context, snapshot) {
                        final code = snapshot.data ?? inviteCode;
                        final loading =
                            snapshot.connectionState != ConnectionState.done &&
                            code == null;
                        if (snapshot.hasError) {
                          return Text(
                            'Could not create invite link. Please login and try again.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.coral,
                                  fontWeight: FontWeight.w800,
                                ),
                          );
                        }

                        return Column(
                          children: [
                            _InviteLinkField(
                              inviteCode: code,
                              isLoading: loading,
                            ),
                            20.h,
                            _WhatsappShareButton(
                              inviteCode: code,
                              isLoading: loading,
                            ),
                            30.h,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            _InviteActions(inviteCode: inviteCode, isLoading: isLoading),
          ],
        ),
      ),
    );
  }
}

class _InviteLinkField extends StatelessWidget {
  const _InviteLinkField({required this.inviteCode, required this.isLoading});

  final String? inviteCode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final link = inviteCode == null
        ? 'Creating your invite link...'
        : InviteLinkService.instance.buildInviteUri(inviteCode!).toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: inviteCode == null
            ? null
            : () => _copyInviteLink(context, inviteCode!),
        child: Ink(
          height: 58,
          padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  link,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              10.w,
              const Icon(
                Icons.copy_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsappShareButton extends StatelessWidget {
  const _WhatsappShareButton({
    required this.inviteCode,
    required this.isLoading,
  });

  final String? inviteCode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton.icon(
        onPressed: isLoading || inviteCode == null
            ? null
            : () =>
                  InviteLinkService.instance.shareInviteOnWhatsapp(inviteCode!),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1FB965),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0x331FB965),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Image.asset(
          "assets/icons/whatsapp.png",
          color: Colors.white,
          width: 24,
          height: 24,
        ),
        label: Text(
          'Share on WhatsApp',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InviteActions extends StatelessWidget {
  const _InviteActions({required this.inviteCode, required this.isLoading});

  final String? inviteCode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(120),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(120),

          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.64),
                borderRadius: BorderRadius.circular(120),
                border: Border.all(
                  color: AppColors.peach.withValues(alpha: 0.42),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.80),
                    AppColors.surfaceWarm.withValues(alpha: 0.52),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _InviteAction(
                        icon: HugeIcons.strokeRoundedCopyLink,
                        label: 'Copy Link',
                        onTap: inviteCode == null
                            ? null
                            : () => _copyInviteLink(context, inviteCode!),
                      ),
                    ),
                    Expanded(
                      child: _InviteAction(
                        icon: HugeIcons.strokeRoundedSent02,
                        label: 'Share More',
                        onTap: inviteCode == null
                            ? null
                            : () => InviteLinkService.instance.shareInvite(
                                inviteCode!,
                              ),
                      ),
                    ),
                    Expanded(
                      child: _InviteAction(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        label: 'How it works',
                        onTap: () => _showHowItWorksSheet(
                          context,
                          inviteCode: inviteCode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showHowItWorksSheet(BuildContext context, {required String? inviteCode}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => _HowItWorksSheet(inviteCode: inviteCode),
  );
}

Future<void> _copyInviteLink(BuildContext context, String inviteCode) async {
  await InviteLinkService.instance.copyInviteLink(inviteCode);

  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: const Text('Invite link copied'),
    ),
  );
}

class _HowItWorksSheet extends StatelessWidget {
  const _HowItWorksSheet({required this.inviteCode});

  final String? inviteCode;

  @override
  Widget build(BuildContext context) {
    final canUseInvite = inviteCode != null && inviteCode!.trim().isNotEmpty;
    final maxHeight = MediaQuery.sizeOf(context).height * .9;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              16.h,
              Text(
                'How this invite works',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              8.h,
              Text(
                'Share this link with someone close to you. They open it, sign in, and fill a small slam for you. Once they save it, their answers show up in your My Slam list.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              16.h,
              const _HowItWorksStep(
                number: '1',
                text:
                    'Send the link on WhatsApp, Messages, or anywhere you like.',
              ),
              const _HowItWorksStep(
                number: '2',
                text:
                    'Your friend opens it and Slamora takes them to the fill-slam flow.',
              ),
              const _HowItWorksStep(
                number: '3',
                text:
                    'After they save it, you can read their memories from My Slam.',
              ),
              10.h,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Tip: send it to one person at a time if you want the answers to feel personal.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
              16.h,
              OutlinedButton.icon(
                onPressed: canUseInvite ? () => Navigator.pop(context) : null,
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
                label: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          12.w,
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteAction extends StatelessWidget {
  const _InviteAction({required this.icon, required this.label, this.onTap});

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon(icon, color: AppColors.primary, size: 24),
          HugeIcon(icon: icon, color: AppColors.primary, size: 24),
          5.h,
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvelopeIllustration extends StatelessWidget {
  const _EnvelopeIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _EnvelopePainter());
  }
}

class _EnvelopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final centerX = size.width / 2;
    final envelopeTop = size.height * .47;
    final envelopeRect = Rect.fromLTWH(
      size.width * .18,
      envelopeTop,
      size.width * .64,
      size.height * .38,
    );

    paint.color = AppColors.coral;
    for (final sparkle in [
      Offset(size.width * .08, size.height * .42),
      Offset(size.width * .18, size.height * .24),
      Offset(size.width * .88, size.height * .22),
      Offset(size.width * .93, size.height * .52),
      Offset(size.width * .75, size.height * .38),
      Offset(size.width * .05, size.height * .62),
    ]) {
      _drawSparkle(canvas, sparkle, paint);
    }

    paint.color = AppColors.accent.withValues(alpha: .86);
    final backFlap = Path()
      ..moveTo(envelopeRect.left, envelopeTop)
      ..lineTo(centerX, size.height * .28)
      ..lineTo(envelopeRect.right, envelopeTop)
      ..close();
    canvas.drawPath(backFlap, paint);

    paint.color = AppColors.surface;
    final letter = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .31,
        size.height * .23,
        size.width * .38,
        size.height * .38,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(letter, paint);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.border;
    canvas.drawRRect(letter, paint);
    paint.style = PaintingStyle.fill;

    paint.color = AppColors.coral.withValues(alpha: .84);
    final heart = Path()
      ..moveTo(centerX, size.height * .50)
      ..cubicTo(
        centerX - 34,
        size.height * .32,
        centerX - 58,
        size.height * .49,
        centerX,
        size.height * .63,
      )
      ..cubicTo(
        centerX + 58,
        size.height * .49,
        centerX + 34,
        size.height * .32,
        centerX,
        size.height * .50,
      );
    canvas.drawPath(heart, paint);

    paint.color = AppColors.peach;
    canvas.drawRRect(
      RRect.fromRectAndRadius(envelopeRect, const Radius.circular(4)),
      paint,
    );

    paint.color = AppColors.accent.withValues(alpha: .88);
    final leftFlap = Path()
      ..moveTo(envelopeRect.left, envelopeRect.top)
      ..lineTo(centerX, envelopeRect.center.dy)
      ..lineTo(envelopeRect.left, envelopeRect.bottom)
      ..close();
    final rightFlap = Path()
      ..moveTo(envelopeRect.right, envelopeRect.top)
      ..lineTo(centerX, envelopeRect.center.dy)
      ..lineTo(envelopeRect.right, envelopeRect.bottom)
      ..close();
    canvas.drawPath(leftFlap, paint);
    canvas.drawPath(rightFlap, paint);

    paint.color = AppColors.peach.withValues(alpha: .95);
    final frontFlap = Path()
      ..moveTo(envelopeRect.left, envelopeRect.bottom)
      ..lineTo(centerX, envelopeRect.center.dy)
      ..lineTo(envelopeRect.right, envelopeRect.bottom)
      ..close();
    canvas.drawPath(frontFlap, paint);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.accent;
    canvas.drawPath(backFlap, paint);
    canvas.drawPath(leftFlap, paint);
    canvas.drawPath(rightFlap, paint);
    canvas.drawPath(frontFlap, paint);
    paint.style = PaintingStyle.fill;

    paint.color = AppColors.shadow;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, size.height * .88),
        width: size.width * .70,
        height: 16,
      ),
      paint,
    );
  }

  void _drawSparkle(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(center, 2.4, paint);
    canvas.drawCircle(center.translate(6, -4), 1.6, paint);
    canvas.drawCircle(center.translate(-5, 5), 1.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
