import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../repositories/auth_repository.dart';
import '../../services/app_exception.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _specialties = [
    'Généraliste',
    'Chirurgie',
    'NAC',
    'Dentaire',
    'Dermatologie',
  ];

  static const _allServices = [
    'Consultation',
    'Vaccination',
    'Chirurgie',
    'Radiologie',
    'Analyses',
    'Identification',
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _clinic = TextEditingController();
  final _address = TextEditingController();
  final _hoursWeekdays = TextEditingController(text: '08:30 – 19:00');
  final _hoursSaturday = TextEditingController(text: '09:00 – 13:00');
  final _auth = AuthRepository();

  bool _obscure = true;
  bool _accepted = false;
  bool _loading = false;
  UserRole _role = UserRole.owner;
  String _specialty = 'Généraliste';
  final Set<String> _services = {'Consultation', 'Vaccination'};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _clinic.dispose();
    _address.dispose();
    _hoursWeekdays.dispose();
    _hoursSaturday.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez accepter les conditions')),
      );
      return;
    }
    if (_role == UserRole.vet && _services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis au moins un service')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        phone: _phone.text,
        role: _role,
        specialty: _specialty,
        clinic: _clinic.text,
        address: _address.text,
        services: _services.toList(),
        hoursWeekdays: _hoursWeekdays.text,
        hoursSaturday: _hoursSaturday.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirme ton e-mail'),
          content: Text(
            'Un lien de confirmation a été envoyé à ${_email.text.trim()}.\n\n'
            'Ouvre-le, puis connecte-toi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              Text('Créer un compte', style: text.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Rejoignez PetCare et prenez soin de vos animaux 🐾',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 20),
              Text('Type de compte', style: text.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.owner,
                    label: Text('Propriétaire'),
                    icon: Icon(Icons.pets_rounded),
                  ),
                  ButtonSegment(
                    value: UserRole.vet,
                    label: Text('Vétérinaire'),
                    icon: Icon(Icons.medical_services_outlined),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: 'Nom complet',
                hint: _role == UserRole.vet ? 'Dr. Sarah Benali' : 'Sarah Benali',
                icon: Icons.person_outline_rounded,
                controller: _name,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              LabeledField(
                label: 'Adresse e-mail',
                hint: 'exemple@email.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                controller: _email,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'E-mail requis';
                  if (!v.contains('@')) return 'E-mail invalide';
                  return null;
                },
              ),
              LabeledField(
                label: 'Téléphone',
                hint: '+33 6 00 00 00 00',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                controller: _phone,
              ),
              if (_role == UserRole.vet) ...[
                const SizedBox(height: 8),
                Text('Profil cabinet', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Ces infos apparaîtront dans « Trouver un vétérinaire ».',
                  style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text('Spécialité', style: text.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _specialties)
                      ChoiceChip(
                        label: Text(s),
                        selected: _specialty == s,
                        onSelected: (_) => setState(() => _specialty = s),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: 'Clinique / cabinet',
                  hint: 'Clinique VetCare',
                  icon: Icons.local_hospital_outlined,
                  controller: _clinic,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Clinique requise'
                      : null,
                ),
                LabeledField(
                  label: 'Adresse',
                  hint: '12 rue des Lilas, Paris',
                  icon: Icons.place_outlined,
                  controller: _address,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Adresse requise'
                      : null,
                ),
                Text('Services proposés', style: text.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _allServices)
                      FilterChip(
                        label: Text(s),
                        selected: _services.contains(s),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _services.add(s);
                            } else {
                              _services.remove(s);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: 'Horaires Lun – Ven',
                  hint: '08:30 – 19:00',
                  icon: Icons.schedule_rounded,
                  controller: _hoursWeekdays,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Horaires requis'
                      : null,
                ),
                LabeledField(
                  label: 'Horaires Samedi',
                  hint: '09:00 – 13:00',
                  icon: Icons.schedule_rounded,
                  controller: _hoursSaturday,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Horaires requis'
                      : null,
                ),
              ],
              LabeledField(
                label: 'Mot de passe',
                hint: '6 caractères minimum',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                controller: _password,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Mot de passe requis';
                  if (v.length < 6) return '6 caractères minimum';
                  return null;
                },
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
                controller: _confirm,
                validator: (v) =>
                    v != _password.text ? 'Les mots de passe diffèrent' : null,
              ),
              Row(
                children: [
                  Checkbox(
                    value: _accepted,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _accepted = v ?? false),
                  ),
                  const Expanded(
                    child: Text("J'accepte les conditions d'utilisation",
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Créer mon compte'),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
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
      ),
    );
  }
}
