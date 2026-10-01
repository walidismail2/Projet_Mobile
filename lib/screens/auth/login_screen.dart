import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _remember = true;

  void _login() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Text('🐾', style: TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Bon retour !',
                textAlign: TextAlign.center, style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Connectez-vous pour retrouver vos compagnons',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 32),
            const LabeledField(
              label: 'Adresse e-mail',
              hint: 'exemple@email.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            LabeledField(
              label: 'Mot de passe',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _remember,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
                const Expanded(
                  child: Text('Se souvenir de moi',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.navy)),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Mot de passe oublié ?',
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _login, child: const Text('Se connecter')),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou continuer avec', style: text.bodyMedium),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    onPressed: _login,
                    icon: const Text('G',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.vet)),
                    label: 'Google',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialButton(
                    onPressed: _login,
                    icon: const Icon(Icons.facebook_rounded,
                        color: Color(0xFF1877F2)),
                    label: 'Facebook',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Pas encore de compte ?', style: text.bodyMedium),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('S\'inscrire'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
