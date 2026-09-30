import 'package:flutter/material.dart';
import '/core/extensions/spacing_extensions.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.hasError = false, this.onRetry});

  final bool hasError;
  final VoidCallback? onRetry;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 28,
                          offset: Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        'assets/icons/slamora_app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  20.h,
                  /*ScaleText(
                    text: "Slamora",
                      style: AppTextTheme.memoryTitle.copyWith(
                        color: AppColors.primary,
                        fontSize: 52,
                        height: 1,
                      ),
                    config: const AnimationConfig(
                     // duration: Duration(seconds: 1),
                      type: AnimationType.letter,
                    ),
                  ),*/
                  Text(
                    "Slamora",
                    style: AppTextTheme.memoryTitle.copyWith(
                      color: AppColors.primary,
                      fontSize: 52,
                      height: 1,
                    ),
                  ),
                  10.h,
                  Text(
                    widget.hasError
                        ? 'Something needs a quick retry.'
                        : 'People, memories, together.',
                    textAlign: TextAlign.center,
                    style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  if (widget.hasError) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: widget.onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Try again'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
