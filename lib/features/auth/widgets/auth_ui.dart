import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/token_colors.dart';

/// Stitch-aligned auth chrome: gradients, fields, buttons, social row.
abstract final class AuthUi {
  static TextStyle displayFont(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        textStyle: Theme.of(context).textTheme.bodyMedium,
      );

  static TextStyle bodyFont(BuildContext context) =>
      GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium);

  static void showComingSoon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign-in is coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AuthGradientBackground extends StatelessWidget {
  const AuthGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF3EEFF),
            Color(0xFFF8F9FF),
            Color(0xFFEDE9FE),
          ],
        ),
      ),
      child: child,
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, this.showLanguage = true});

  final bool showLanguage;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Text(
            'ViralCut',
            style: AuthUi.displayFont(context).copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: primary,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          if (showLanguage)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ViralCutTokenColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 16, color: primary),
                  const SizedBox(width: 4),
                  Text(
                    'EN',
                    style: AuthUi.bodyFont(context).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthLabeledField extends StatelessWidget {
  const AuthLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
  });

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: AuthUi.bodyFont(context).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: ViralCutTokenColors.mutedLight,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class AuthTextFormField extends StatelessWidget {
  const AuthTextFormField({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      textInputAction: textInputAction,
      style: AuthUi.bodyFont(context).copyWith(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AuthUi.bodyFont(context).copyWith(
          color: ViralCutTokenColors.mutedLight.withValues(alpha: 0.7),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: ViralCutTokenColors.mutedLight)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ViralCutTokenColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ViralCutTokenColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class AuthPhoneRow extends StatelessWidget {
  const AuthPhoneRow({
    super.key,
    required this.countryController,
    required this.phoneController,
    this.onPhoneChanged,
  });

  final TextEditingController countryController;
  final TextEditingController phoneController;
  final ValueChanged<String>? onPhoneChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: TextField(
            controller: countryController,
            textAlign: TextAlign.center,
            style: AuthUi.bodyFont(context).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: ViralCutTokenColors.surfaceVariantLight,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: ViralCutTokenColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: ViralCutTokenColors.borderLight),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AuthTextFormField(
            controller: phoneController,
            hint: '98765 43210',
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: onPhoneChanged,
          ),
        ),
      ],
    );
  }
}

class AuthOtpField extends StatelessWidget {
  const AuthOtpField({
    super.key,
    required this.controller,
    this.onResend,
    this.resendEnabled = true,
  });

  final TextEditingController controller;
  final VoidCallback? onResend;
  final bool resendEnabled;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AuthLabeledField(
      label: 'One-time password',
      trailing: TextButton(
        onPressed: resendEnabled ? onResend : null,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Resend code',
          style: AuthUi.bodyFont(context).copyWith(
            color: primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      child: AuthTextFormField(
        controller: controller,
        hint: '6-digit code',
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        prefixIcon: Icons.lock_outline,
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AuthUi.bodyFont(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                ],
              ),
      ),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(color: ViralCutTokenColors.borderLight)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'OR',
              style: AuthUi.bodyFont(context).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ViralCutTokenColors.mutedLight,
              ),
            ),
          ),
          const Expanded(child: Divider(color: ViralCutTokenColors.borderLight)),
        ],
      ),
    );
  }
}

class SocialSignInRow extends StatelessWidget {
  const SocialSignInRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            onTap: () => AuthUi.showComingSoon(context, 'Google'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            label: 'Facebook',
            onTap: () => AuthUi.showComingSoon(context, 'Facebook'),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: ViralCutTokenColors.borderLight),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: label == 'Google'
                  ? const Color(0xFF4285F4)
                  : const Color(0xFF1877F2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AuthUi.bodyFont(context).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class LoginHeroIcon extends StatelessWidget {
  const LoginHeroIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary,
          ),
          child: const Icon(Icons.currency_rupee, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class EarningSocialProof extends StatelessWidget {
  const EarningSocialProof({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ViralCutTokenColors.borderLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 32,
            child: Stack(
              children: List.generate(3, (i) {
                return Positioned(
                  left: i * 22.0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: [
                      const Color(0xFF94A3B8),
                      const Color(0xFF64748B),
                      const Color(0xFF475569),
                    ][i],
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+ 2.4k earning now',
            style: AuthUi.bodyFont(context).copyWith(
              color: ViralCutTokenColors.mutedLight,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
