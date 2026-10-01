import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informations personnelles')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryLight,
              child: Text('SB',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Changer la photo'),
            ),
          ),
          const SizedBox(height: 12),
          const LabeledField(
            label: 'Nom complet',
            hint: 'Votre nom',
            icon: Icons.person_outline_rounded,
            initialValue: MockData.ownerName,
          ),
          const LabeledField(
            label: 'Adresse e-mail',
            hint: 'exemple@email.com',
            icon: Icons.mail_outline_rounded,
            initialValue: MockData.ownerEmail,
          ),
          const LabeledField(
            label: 'Téléphone',
            hint: '+33 …',
            icon: Icons.phone_outlined,
            initialValue: MockData.ownerPhone,
          ),
          const LabeledField(
            label: 'Adresse',
            hint: 'Votre adresse',
            icon: Icons.home_outlined,
            initialValue: '24 rue de la Roquette, 75011 Paris',
          ),
          const LabeledField(
            label: 'Contact d\'urgence',
            hint: 'Nom et téléphone',
            icon: Icons.emergency_outlined,
            initialValue: 'Karim Benali · +33 6 98 76 54 32',
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              showSuccessSnack(context, 'Profil mis à jour');
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
