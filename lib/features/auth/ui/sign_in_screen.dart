import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validators.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../logic/auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final loading = state.isLoading;

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        context.showSnack(next.error.toString(), isError: true);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const AppLogo(size: 36),
                    const SizedBox(width: AppSpacing.md),
                    Text(AppConstants.appName, style: context.text.titleLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.huge),
                Text('Welcome back', style: context.text.displayLarge),
                const SizedBox(height: AppSpacing.sm),
                Text('Sign in to continue summarizing.',
                    style: context.text.bodyLarge
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xxxl),
                AppTextField(
                  key: const Key('email_field'),
                  controller: _email,
                  label: 'Email',
                  icon: Symbols.mail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  key: const Key('password_field'),
                  controller: _password,
                  label: 'Password',
                  icon: Symbols.lock,
                  obscureText: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: Validators.password,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const _BtnSpinner()
                      : const Text('Sign In'),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: context.text.bodyMedium),
                    TextButton(
                      onPressed: () => context.push('/sign-up'),
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BtnSpinner extends StatelessWidget {
  const _BtnSpinner();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
      );
}
