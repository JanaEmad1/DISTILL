import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../logic/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
    } else {
      context.showSnack(
          ref.read(authControllerProvider).error.toString(),
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: _sent ? _Sent(email: _email.text) : _form(loading),
        ),
      ),
    );
  }

  Widget _form(bool loading) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Forgot your password?', style: context.text.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
                "Enter your email and we'll send you a link to reset it.",
                style: context.text.bodyLarge
                    ?.copyWith(color: context.colors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xxxl),
            AppTextField(
              controller: _email,
              label: 'Email',
              icon: Symbols.mail,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary))
                  : const Text('Send reset link'),
            ),
          ],
        ),
      );
}

class _Sent extends StatelessWidget {
  const _Sent({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Symbols.mark_email_read,
            size: 72, color: context.colors.secondary),
        const SizedBox(height: AppSpacing.xl),
        Text('Check your inbox', style: context.text.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('We sent a reset link to $email.',
            textAlign: TextAlign.center,
            style: context.text.bodyLarge
                ?.copyWith(color: context.colors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.xxl),
        FilledButton(
          onPressed: () => context.pop(),
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }
}
