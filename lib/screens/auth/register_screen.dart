import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../main_shell.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscure = true;
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text('Créer un compte', style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Rejoignez PetCare et prenez soin de vos animaux en toute simplicité 🐾',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 28),
            const LabeledField(
              label: 'Nom complet',
              hint: 'Sarah Benali',
              icon: Icons.person_outline_rounded,
            ),
            const LabeledField(
              label: 'Adresse e-mail',
              hint: 'exemple@email.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const LabeledField(
              label: 'Téléphone',
              hint: '+33 6 00 00 00 00',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            LabeledField(
              label: 'Mot de passe',
              hint: '8 caractères minimum',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
            ),
            LabeledField(
              label: 'Confirmer le mot de passe',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _accepted,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  onChanged: (v) => setState(() => _accepted = v ?? false),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text.rich(
                      TextSpan(
                        text: 'J\'accepte les ',
                        style: TextStyle(color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'conditions d\'utilisation',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ' et la '),
                          TextSpan(
                            text: 'politique de confidentialité',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainShell()),
                (_) => false,
              ),
              child: const Text('Créer mon compte'),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Déjà inscrit ?', style: text.bodyMedium),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
