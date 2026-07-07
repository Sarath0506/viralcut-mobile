import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/token_colors.dart';
import '../../../theme/halchal_colors.dart';
import '../../../theme/halchal_text_styles.dart';

/// Shared auth chrome: background, fields, buttons, and social row.
abstract final class AuthUi {
  static TextStyle displayFont(BuildContext context) =>
      HalchalTextStyles.display(context);

  static TextStyle bodyFont(BuildContext context) =>
      HalchalTextStyles.body(context);

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
    final vc = HalchalColors.of(context);
    return ColoredBox(
      color: vc.surface,
      child: child,
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, this.showLanguage = true});

  final bool showLanguage;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Text(
            'Halchal',
            style: AuthUi.displayFont(context).copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: primary,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          if (showLanguage)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: vc.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: vc.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 16, color: primary),
                  const SizedBox(width: 4),
                  Text(
                    'EN',
                    style: HalchalTextStyles.bodyText(context).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: vc.onSurface,
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
    final vc = HalchalColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(ViralCutTokenRadius.xl),
        border: Border.all(color: vc.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: vc.onSurface.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
    final vc = HalchalColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: HalchalTextStyles.label(context).copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: vc.muted,
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
    final vc = HalchalColors.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      textInputAction: textInputAction,
      style: HalchalTextStyles.bodyText(context).copyWith(color: vc.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: HalchalTextStyles.bodyText(context).copyWith(
          color: vc.muted.withValues(alpha: 0.7),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: vc.muted)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: vc.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViralCutTokenRadius.md),
          borderSide: BorderSide(color: vc.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViralCutTokenRadius.md),
          borderSide: BorderSide(color: vc.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViralCutTokenRadius.md),
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
    final vc = HalchalColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: TextField(
            controller: countryController,
            readOnly: true,
            enableInteractiveSelection: false,
            textAlign: TextAlign.center,
            style: HalchalTextStyles.bodyText(context).copyWith(
              fontWeight: FontWeight.w600,
              color: vc.onSurface,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: vc.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ViralCutTokenRadius.md),
                borderSide: BorderSide(color: vc.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ViralCutTokenRadius.md),
                borderSide: BorderSide(color: vc.border),
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
    final vc = HalchalColors.of(context);
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
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: vc.onPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: HalchalTextStyles.bodyText(context).copyWith(
                      color: vc.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: vc.onPrimary),
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
    final vc = HalchalColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(child: Divider(color: vc.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'OR',
              style: HalchalTextStyles.label(context).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: vc.muted,
              ),
            ),
          ),
          Expanded(child: Divider(color: vc.border)),
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
    final vc = HalchalColors.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViralCutTokenRadius.md),
        ),
        side: BorderSide(color: vc.border),
        backgroundColor: vc.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: label == 'Google'
                  ? ViralCutOAuthColors.google
                  : ViralCutOAuthColors.facebook,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: HalchalTextStyles.meta(context).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: vc.onSurface,
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
    final vc = HalchalColors.of(context);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: vc.primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: vc.primary,
          ),
          child: Icon(Icons.currency_rupee, color: vc.onPrimary, size: 26),
        ),
      ),
    );
  }
}

class EarningSocialProof extends StatelessWidget {
  const EarningSocialProof({super.key});

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: vc.infoSurface,
        borderRadius: BorderRadius.circular(ViralCutTokenRadius.lg),
        border: Border.all(color: vc.border),
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
                    backgroundColor: Color.lerp(
                      vc.muted,
                      vc.onSurface,
                      i * 0.25,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: vc.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+ 2.4k earning now',
            style: HalchalTextStyles.meta(context).copyWith(
              color: vc.muted,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
