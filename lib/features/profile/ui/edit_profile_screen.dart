import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/providers.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validators.dart';
import '../../../shared/widgets/app_text_field.dart';

/// Edit the signed-in user's display name. Email is read-only.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _name = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfileName(_name.text.trim());
      if (mounted) {
        context.showSnack('Profile updated');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: context.colors.secondaryContainer,
                  child: Text(user?.initial ?? '?',
                      style: context.text.displaySmall?.copyWith(
                          color: context.colors.onSecondaryContainer)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _name,
                label: 'Display name',
                icon: Symbols.person,
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.required(v, field: 'Name'),
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                initialValue: user?.email ?? '',
                enabled: false,
                style: context.text.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Symbols.mail, size: 20),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
