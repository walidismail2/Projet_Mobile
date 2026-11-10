import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/session.dart';
import 'package:flutter_example/modules/compte/repositories/auth_repository.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/modules/compte/screens/auth/welcome_screen.dart';
import 'package:flutter_example/modules/compte/screens/vet_role/vet_patients_screen.dart';

class VetShell extends StatelessWidget {
  const VetShell({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Session.instance.currentUser;
    final name = user?.name ?? 'Vétérinaire';
    final initials = () {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.isEmpty ? 'V' : name[0].toUpperCase();
    }();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.vet, Color(0xFF6B9BFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Espace vétérinaire',
                          style: TextStyle(
                            color: AppColors.vet,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Déconnexion',
                    onPressed: () async {
                      await AuthRepository().logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WelcomeScreen()),
                        (_) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const Expanded(child: VetPatientsScreen()),
          ],
        ),
      ),
    );
  }
}
