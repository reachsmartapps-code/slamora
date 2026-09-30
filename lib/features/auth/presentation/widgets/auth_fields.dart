import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/capitalize_first_letter_formatter.dart';

const _authTextSoft = Color(0xFF2B4774);
const _authTextMuted = Color(0xFF74819A);

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    required this.icon,
    required this.hintText,
    this.controller,
    this.trailing,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  final IconData icon;
  final String hintText;
  final TextEditingController? controller;
  final Widget? trailing;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: .72)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x147A563C),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters:
            !obscureText && keyboardType != TextInputType.emailAddress
            ? const [CapitalizeFirstLetterFormatter()]
            : null,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: _authTextSoft,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _authTextMuted.withValues(alpha: .82),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primary.withValues(alpha: .88),
            size: 20,
          ),
          suffixIcon: trailing == null
              ? null
              : IconTheme(
                  data: IconThemeData(
                    color: AppColors.primary.withValues(alpha: .62),
                    size: 20,
                  ),
                  child: trailing!,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}
