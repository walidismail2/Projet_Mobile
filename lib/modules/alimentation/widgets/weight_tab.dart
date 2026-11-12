import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_example/core/data/app_refresh.dart';
import 'package:flutter_example/core/models/models.dart';
import 'package:flutter_example/core/theme/app_theme.dart';
import 'package:flutter_example/core/widgets/common.dart';
import 'package:flutter_example/modules/alimentation/repositories/weight_repository.dart';

/// Onglet « Poids » : résumé, courbe et historique des pesées.
class WeightTab extends StatelessWidget {
  final Pet pet;

  /// Pesées triées de la plus ancienne à la plus récente.
  final List<WeightLog> logs;
  final Diet? diet;
  final VoidCallback onChanged;

  const WeightTab({
    super.key,
    required this.pet,
    required this.logs,
    required this.diet,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monitor_weight_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Aucune pesée pour ${pet.name}.\n'
                'Poids sur la fiche : ${_kg(pet.weight)}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _add(context),
                icon: const Icon(Icons.add),
                label: const Text('Première pesée'),
              ),
            ],
          ),
        ),
      );
    }

    final latest = logs.last;
    final previous = logs.length > 1 ? logs[logs.length - 2] : null;
    final first = logs.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Poids (kg)',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _kg(latest.weight),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (previous != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: _DeltaLabel(
                        latest.weight - previous.weight,
                        suffix: ' vs pesée préc.',
                      ),
                    ),
                ],
              ),
              if (logs.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _DeltaLabel(
                    latest.weight - first.weight,
                    suffix: ' depuis le ${formatFrDate(first.date)}',
                  ),
                ),
              if (diet != null && diet!.goal.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Objectif véto : ${diet!.goal}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              if (logs.length > 1) ...[
                const SizedBox(height: 16),
                SizedBox(height: 180, child: WeightChart(logs: logs)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader('Historique'),
        for (var i = logs.length - 1; i >= 0; i--)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: ListTile(
                leading: const Icon(
                  Icons.monitor_weight_outlined,
                  color: AppColors.food,
                ),
                title: Text(_kg(logs[i].weight)),
                subtitle: Text(
                  [
                    formatFrDate(logs[i].date),
                    if (logs[i].note.isNotEmpty) logs[i].note,
                  ].join(' · '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (i > 0) _DeltaLabel(logs[i].weight - logs[i - 1].weight),
                    PopupMenuButton<String>(
                      onSelected: (v) => v == 'edit'
                          ? _edit(context, logs[i])
                          : _delete(context, logs[i]),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _add(BuildContext context) async {
    if (await showWeightSheet(context, pet: pet)) onChanged();
  }

  Future<void> _edit(BuildContext context, WeightLog log) async {
    if (await showWeightSheet(context, pet: pet, existing: log)) onChanged();
  }

  Future<void> _delete(BuildContext context, WeightLog log) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Supprimer cette pesée ?',
      message: '${_kg(log.weight)} · ${formatFrDate(log.date)}',
      confirmLabel: 'Supprimer',
    );
    if (!ok) return;
    await WeightRepository().delete(log);
    AppRefresh.instance.petsChanged();
    onChanged();
  }
}

String _kg(double v) =>
    '${v.toStringAsFixed(v >= 10 ? 1 : 2)} kg'.replaceAll('.', ',');

class _DeltaLabel extends StatelessWidget {
  final double delta;
  final String suffix;

  const _DeltaLabel(this.delta, {this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    final flat = delta.abs() < 0.005;
    final icon = flat
        ? Icons.trending_flat_rounded
        : (delta > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded);
    final sign = flat ? '±' : (delta > 0 ? '+' : '−');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 2),
        Text(
          '$sign${delta.abs().toStringAsFixed(2).replaceAll('.', ',')} kg$suffix',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

/// Ajout / édition d'une pesée. Renvoie `true` si enregistré.
Future<bool> showWeightSheet(
  BuildContext context, {
  required Pet pet,
  WeightLog? existing,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _WeightSheet(pet: pet, existing: existing),
  );
  if (saved == true) AppRefresh.instance.petsChanged();
  return saved == true;
}

class _WeightSheet extends StatefulWidget {
  final Pet pet;
  final WeightLog? existing;

  const _WeightSheet({required this.pet, this.existing});

  @override
  State<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<_WeightSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight;
  late final TextEditingController _note;
  late final TextEditingController _dateText;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final w = e?.weight ?? widget.pet.weight;
    _weight = TextEditingController(
      text: w > 0 ? w.toString().replaceAll('.', ',') : '',
    );
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? DateTime.now();
    _dateText = TextEditingController(text: formatFrDate(_date));
  }

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    _dateText.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: _date.isAfter(DateTime.now()) ? DateTime.now() : _date,
    );
    if (d == null) return;
    setState(() {
      _date = d;
      _dateText.text = formatFrDate(d);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final log = WeightLog(
      id: widget.existing?.id,
      petId: widget.pet.id!,
      weight: parseDecimal(_weight.text)!,
      date: _date,
      note: _note.text.trim(),
    );
    final repo = WeightRepository();
    if (log.id == null) {
      await repo.insert(log);
    } else {
      await repo.update(log);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? 'Nouvelle pesée · ${widget.pet.name}'
                  : 'Modifier la pesée',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Poids (kg)',
              hint: '12,5',
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final w = parseDecimal(v ?? '');
                if (w == null || w <= 0 || w > 150) {
                  return 'Poids invalide (0 – 150 kg)';
                }
                return null;
              },
            ),
            LabeledField(
              label: 'Date',
              hint: '',
              controller: _dateText,
              readOnly: true,
              onTap: _pickDate,
              suffix: const Icon(Icons.calendar_today_rounded, size: 18),
            ),
            LabeledField(
              label: 'Note (optionnel)',
              hint: 'Après le repas, chez le véto…',
              controller: _note,
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Courbe de poids (une seule série) — toucher un point affiche sa valeur.
class WeightChart extends StatefulWidget {
  final List<WeightLog> logs;

  const WeightChart({super.key, required this.logs});

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  int? _selected;

  @override
  void didUpdateWidget(covariant WeightChart old) {
    super.didUpdateWidget(old);
    if (_selected != null && _selected! >= widget.logs.length) {
      _selected = null;
    }
  }

  void _select(Offset local, Size size) {
    final geo = _ChartGeometry(widget.logs, size);
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < widget.logs.length; i++) {
      final d = (geo.point(i).dx - local.dx).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    setState(() => _selected = best);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Courbe de poids, ${widget.logs.length} pesées',
      child: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _select(d.localPosition, size),
            onHorizontalDragUpdate: (d) => _select(d.localPosition, size),
            child: CustomPaint(
              size: size,
              painter: _WeightChartPainter(widget.logs, _selected),
            ),
          );
        },
      ),
    );
  }
}

/// Zone de tracé partagée entre le dessin et la détection du toucher.
class _ChartGeometry {
  static const left = 40.0;
  static const right = 12.0;
  static const top = 28.0;
  static const bottom = 22.0;

  final List<WeightLog> logs;
  final Size size;
  late final double minW;
  late final double maxW;
  late final int t0;
  late final int span;

  _ChartGeometry(this.logs, this.size) {
    var lo = logs.map((l) => l.weight).reduce(math.min);
    var hi = logs.map((l) => l.weight).reduce(math.max);
    final pad = math.max((hi - lo) * 0.15, 0.2);
    lo -= pad;
    hi += pad;
    minW = math.max(0, lo);
    maxW = hi;
    t0 = logs.first.date.millisecondsSinceEpoch;
    span = math.max(1, logs.last.date.millisecondsSinceEpoch - t0);
  }

  Rect get plot =>
      Rect.fromLTRB(left, top, size.width - right, size.height - bottom);

  double y(double w) => plot.bottom - (w - minW) / (maxW - minW) * plot.height;

  Offset point(int i) {
    final l = logs[i];
    final x = logs.length == 1
        ? plot.center.dx
        : plot.left + (l.date.millisecondsSinceEpoch - t0) / span * plot.width;
    return Offset(x, y(l.weight));
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<WeightLog> logs;
  final int? selected;

  _WeightChartPainter(this.logs, this.selected);

  static const _line = AppColors.primaryDark;

  @override
  void paint(Canvas canvas, Size size) {
    final geo = _ChartGeometry(logs, size);
    final plot = geo.plot;

    // Grille horizontale discrète + graduations à gauche.
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var k = 0; k <= 2; k++) {
      final w = geo.minW + (geo.maxW - geo.minW) * k / 2;
      final yy = geo.y(w);
      canvas.drawLine(Offset(plot.left, yy), Offset(plot.right, yy), grid);
      _text(
        canvas,
        w.toStringAsFixed(1).replaceAll('.', ','),
        Offset(plot.left - 6, yy),
        align: _Align.rightMiddle,
      );
    }

    // Dates de début / fin sous l'axe.
    _text(
      canvas,
      _short(logs.first.date),
      Offset(plot.left, plot.bottom + 6),
      align: _Align.leftTop,
    );
    _text(
      canvas,
      _short(logs.last.date),
      Offset(plot.right, plot.bottom + 6),
      align: _Align.rightTop,
    );

    // Courbe 2px.
    final path = Path();
    for (var i = 0; i < logs.length; i++) {
      final p = geo.point(i);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = _line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Points 8px avec anneau blanc 2px.
    final ring = Paint()..color = Colors.white;
    final dot = Paint()..color = _line;
    for (var i = 0; i < logs.length; i++) {
      final p = geo.point(i);
      final r = i == selected ? 6.0 : 4.0;
      canvas.drawCircle(p, r + 2, ring);
      canvas.drawCircle(p, r, dot);
    }

    // Étiquette : point touché, sinon la dernière pesée.
    final i = selected ?? logs.length - 1;
    final p = geo.point(i);
    if (selected != null) {
      canvas.drawLine(
        Offset(p.dx, plot.top),
        Offset(p.dx, plot.bottom),
        Paint()
          ..color = AppColors.textSecondary.withValues(alpha: 0.4)
          ..strokeWidth = 1,
      );
    }
    final label =
        '${logs[i].weight.toStringAsFixed(2).replaceAll('.', ',')} kg · ${_short(logs[i].date)}';
    _bubble(canvas, label, p, size);
  }

  String _short(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  void _text(Canvas canvas, String s, Offset at, {required _Align align}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      _Align.rightMiddle || _Align.rightTop => at.dx - tp.width,
      _Align.leftTop => at.dx,
    };
    final dy = align == _Align.rightMiddle ? at.dy - tp.height / 2 : at.dy;
    tp.paint(canvas, Offset(dx, dy));
  }

  void _bubble(Canvas canvas, String s, Offset p, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const padH = 8.0, padV = 4.0;
    final w = tp.width + padH * 2;
    final h = tp.height + padV * 2;
    final left = (p.dx - w / 2).clamp(0.0, size.width - w);
    final top = math.max(0.0, p.dy - h - 10);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = AppColors.navy);
    tp.paint(canvas, Offset(left + padH, top + padV));
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) =>
      old.logs != logs || old.selected != selected;
}

enum _Align { rightMiddle, leftTop, rightTop }
