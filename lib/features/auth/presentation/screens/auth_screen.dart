import 'dart:async';

import 'package:flutter/material.dart';
import '/core/extensions/spacing_extensions.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_social_button.dart';
import '../widgets/auth_tab_switcher.dart';

enum AuthMode { login, signUp }

const _authTextMuted = Color(0xFF74819A);
const _authSoftShadow = Color(0x147A563C);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.onAuthChanged});

  final VoidCallback? onAuthChanged;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _mode = AuthMode.login;
  bool _acceptedTerms = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool get _isLogin => _mode == AuthMode.login;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) {
      return;
    }

    final error = _validateForm();
    if (error != null) {
      _showSnackBar(error, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await AuthService.instance.loginWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
        unawaited(AnalyticsService.instance.loginSuccess(method: 'email'));
      } else {
        await AuthService.instance.signUpWithEmail(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
        unawaited(AnalyticsService.instance.signupSuccess(method: 'email'));
      }

      if (!mounted) {
        return;
      }

      if (!_isLogin) {
        _showSnackBar('Please verify your email to continue.');
      }
      widget.onAuthChanged?.call();
    } catch (error) {
      if (mounted) {
        _showSnackBar(_authMessage(error), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await AuthService.instance.loginWithGoogle();
      final isNewUser = credential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        unawaited(AnalyticsService.instance.signupSuccess(method: 'google'));
      } else {
        unawaited(AnalyticsService.instance.loginSuccess(method: 'google'));
      }

      if (!mounted) {
        return;
      }
      widget.onAuthChanged?.call();
    } catch (error) {
      if (mounted) {
        _showSnackBar(_authMessage(error), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_looksLikeEmail(email)) {
      _showSnackBar('Enter your email to reset password.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.sendPasswordResetEmail(email);

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'If an account exists for this email, a password reset link has been sent.',
      );
    } catch (error) {
      if (mounted) {
        _showSnackBar(_authMessage(error), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_isLogin && _nameController.text.trim().length < 2) {
      return 'Please enter your full name.';
    }

    if (email.isEmpty || !_looksLikeEmail(email)) {
      return 'Please enter a valid email address.';
    }

    if (password.length < 6) {
      return 'Password should be at least 6 characters.';
    }

    if (!_isLogin && password != _confirmPasswordController.text) {
      return 'Passwords do not match.';
    }

    if (!_isLogin && !_acceptedTerms) {
      return 'Please accept the terms to continue.';
    }

    return null;
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String _authMessage(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('user-not-found') || text.contains('wrong-password')) {
      return 'Email or password is incorrect.';
    }
    if (text.contains('invalid-credential')) {
      return 'Could not sign in with these details.';
    }
    if (text.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }
    if (text.contains('weak-password')) {
      return 'Please choose a stronger password.';
    }
    if (text.contains('network-request-failed')) {
      return 'Please check your internet connection.';
    }
    if (text.contains('canceled')) {
      return 'Google sign in was cancelled.';
    }
    if (text.contains('missing-google-token')) {
      return 'Google sign in is not configured yet.';
    }

    return 'Something went wrong. Please try again.';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.coral : AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontalPadding = size.width < 390 ? 20.0 : 30.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  const _AuthTopBar(),
                  15.h,
                  _AuthHero(isLogin: _isLogin),

                  20.h,
                  AuthTabSwitcher(
                    selectedMode: _mode,
                    onChanged: (mode) => setState(() => _mode = mode),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final offsetAnimation = Tween<Offset>(
                          begin: const Offset(0, .04),
                          end: Offset.zero,
                        ).animate(animation);

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: _isLogin
                          ? _LoginForm(
                              key: const ValueKey('login-form'),
                              emailController: _emailController,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              onTogglePassword: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            )
                          : _SignUpForm(
                              key: const ValueKey('signup-form'),
                              nameController: _nameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              acceptedTerms: _acceptedTerms,
                              obscurePassword: _obscurePassword,
                              obscureConfirmPassword: _obscureConfirmPassword,
                              onTermsChanged: (value) {
                                setState(() => _acceptedTerms = value ?? false);
                              },
                              onTogglePassword: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              onToggleConfirmPassword: () {
                                setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                );
                              },
                            ),
                    ),
                  ),
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _sendPasswordReset,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: _authSoftShadow,
                            blurRadius: 18,
                            offset: Offset(0, 9),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        label: Text(
                          _isLoading
                              ? 'Please wait...'
                              : _isLogin
                              ? 'Continue'
                              : 'Create Account',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                  20.h,
                  _DividerLabel(
                    label: _isLogin ? 'Or continue with' : 'Or sign up with',
                  ),
                  15.h,
                  AuthSocialButton(
                    label: 'Google',
                    onPressed: _isLoading ? null : _loginWithGoogle,
                  ),
                  const SizedBox(height: 26),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          _isLogin ? 'New here? ' : 'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(
                              () => _mode = _isLogin
                                  ? AuthMode.signUp
                                  : AuthMode.login,
                            );
                          },
                          child: Text(
                            _isLogin ? 'Create an account' : 'Log in',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  decoration: _isLogin
                                      ? TextDecoration.none
                                      : TextDecoration.underline,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLogin ? 'WELCOME TO' : 'JOIN',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
            ),
            5.h,
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    'Slamora',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.primary,
                      fontSize: compact ? 24 : 32,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.favorite_border_rounded,
                    color: AppColors.coral,
                    size: 28,
                  ),
                ],
              ),
            ),
            10.h,
            Text(
              isLogin
                  ? 'Good to see you again.'
                  : 'Create your Slamora account.',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _authTextMuted,
                fontWeight: FontWeight.w500,
                height: 1.34,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthInputField(
          icon: Icons.mail_outline_rounded,
          hintText: 'Email address',
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        AuthInputField(
          icon: Icons.lock_outline_rounded,
          hintText: 'Password',
          controller: passwordController,
          obscureText: obscurePassword,
          trailing: IconButton(
            onPressed: onTogglePassword,
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.acceptedTerms,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTermsChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool acceptedTerms;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthInputField(
          icon: Icons.person_outline_rounded,
          hintText: 'Full Name',
          controller: nameController,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        AuthInputField(
          icon: Icons.mail_outline_rounded,
          hintText: 'Email address',
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        AuthInputField(
          icon: Icons.lock_outline_rounded,
          hintText: 'Password',
          controller: passwordController,
          obscureText: obscurePassword,
          trailing: IconButton(
            onPressed: onTogglePassword,
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        const SizedBox(height: 14),
        AuthInputField(
          icon: Icons.lock_outline_rounded,
          hintText: 'Confirm Password',
          controller: confirmPasswordController,
          obscureText: obscureConfirmPassword,
          trailing: IconButton(
            onPressed: onToggleConfirmPassword,
            icon: Icon(
              obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Checkbox(
                value: acceptedTerms,
                onChanged: onTermsChanged,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  children: [
                    Text(
                      'I agree to the ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _LinkedText(label: 'Terms of Service'),
                    Text(
                      ' and ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _LinkedText(label: 'Privacy Policy'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LinkedText extends StatelessWidget {
  const _LinkedText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.underline,
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}
