import 'package:flutter/material.dart';
import 'package:slamora/core/extensions/spacing_extensions.dart';

import '../../../../app/theme/app_colors.dart';
import '../screens/auth_screen.dart';

class AuthTabSwitcher extends StatelessWidget {
  const AuthTabSwitcher({
    required this.selectedMode,
    required this.onChanged,
    super.key,
  });

  final AuthMode selectedMode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.divider.withValues(alpha: .9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x147A563C),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          final selectedIndex = selectedMode == AuthMode.login ? 0 : 1;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: selectedIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .96),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _AuthTabButton(
                      icon: Icons.person_rounded,
                      label: 'Login',
                      selected: selectedMode == AuthMode.login,
                      onTap: () => onChanged(AuthMode.login),
                    ),
                  ),
                  Expanded(
                    child: _AuthTabButton(
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'Sign Up',
                      selected: selectedMode == AuthMode.signUp,
                      onTap: () => onChanged(AuthMode.signUp),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    icon,
                    key: ValueKey('$label-$selected'),
                    color: selected ? Colors.white : AppColors.primary,
                    size: 24,
                  ),
                ),
                10.w,
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected ? Colors.white : AppColors.primary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ) ??
                      const TextStyle(),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
