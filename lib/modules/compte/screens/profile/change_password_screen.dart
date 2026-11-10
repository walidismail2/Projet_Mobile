import 'package:flutter/material.dart';

import 'package:flutter_example/core/services/app_exception.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/compte/repositories/auth_repository.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthRepository();

  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await _auth.changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showSuccessSnack(context, 'Mot de passe mis à jour');
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le mot de passe')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Le mot de passe est stocké en SQLite (hash SHA-256 + salt).',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Mot de passe actuel',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              controller: _current,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
            ),
            LabeledField(
              label: 'Nouveau mot de passe',
              hint: '6 caractères minimum',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              controller: _next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Nouveau mot de passe requis';
                if (v.length < 6) return '6 caractères minimum';
                return null;
              },
            ),
            LabeledField(
              label: 'Confirmer le nouveau mot de passe',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              controller: _confirm,
              validator: (v) =>
                  v != _next.text ? 'Les mots de passe diffèrent' : null,
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
