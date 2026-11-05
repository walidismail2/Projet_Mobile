import 'package:flutter/material.dart';

import '../../data/session.dart';
import '../../widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final u = Session.instance.currentUser!;
    _name = TextEditingController(text: u.name);
    _email = TextEditingController(text: u.email);
    _phone = TextEditingController(text: u.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final current = Session.instance.currentUser!;
    await Session.instance.updateLocalProfile(current.copyWith(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
    ));
    if (!mounted) return;
    Navigator.pop(context);
    showSuccessSnack(context, 'Profil mis à jour (local)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informations personnelles')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            LabeledField(
              label: 'Nom',
              hint: 'Nom',
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            LabeledField(
              label: 'E-mail',
              hint: 'email',
              controller: _email,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'E-mail invalide' : null,
            ),
            LabeledField(
              label: 'Téléphone',
              hint: 'Tél',
              controller: _phone,
            ),
            FilledButton(onPressed: _save, child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
  }
}
