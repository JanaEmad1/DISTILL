import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../logic/auth_controller.dart';
import 'widgets/google_button.dart';
import 'widgets/or_divider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signUp(_name.text, _email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        context.showSnack(next.error.toString(), isError: true);
      }
    });

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create account', style: context.text.displayLarge),
                const SizedBox(height: AppSpacing.sm),
                Text('Start reading less and understanding more.',
                    style: context.text.bodyLarge
                        ?.copyWith(color: context.colors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xxxl),
                AppTextField(
                  controller: _name,
                  label: 'Full name',
                  icon: Symbols.person,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  icon: Symbols.mail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _password,
                  label: 'Password',
                  icon: Symbols.lock,
                  obscureText: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: Validators.password,
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
                      : const Text('Create account'),
                ),
                const SizedBox(height: AppSpacing.xl),
                const OrDivider(),
                const SizedBox(height: AppSpacing.xl),
                GoogleButton(
                  onPressed: loading
                      ? null
                      : () => ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?',
                        style: context.text.bodyMedium),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Sign in'),
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
