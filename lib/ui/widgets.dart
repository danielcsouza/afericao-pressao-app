import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import 'theme.dart';

/// Painel das abas Resumo e Mais: cartão com borda de 1px, título e conteúdo.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// Texto de apoio dos painéis (15px, cinza).
class PanelText extends StatelessWidget {
  const PanelText(this.text, {super.key, this.span});
  final String text;
  final InlineSpan? span;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 15, color: context.colors.muted);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: span == null
          ? Text(text, style: style)
          : Text.rich(span!, style: style),
    );
  }
}

/// Botão pequeno e cheio (brand), "Usar hoje" etc.
class SmallButton extends StatelessWidget {
  const SmallButton(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: context.colors.headerColor,
      foregroundColor: AppColors.brandInk,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    onPressed: onTap,
    child: Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );
}

/// Chips de duração (7/15/30/60/90/outro), usados na Agenda e em Ajustes.
class DaysChips extends StatelessWidget {
  const DaysChips({super.key, required this.days, required this.onChanged});
  final int days;
  final ValueChanged<int> onChanged;

  static const presets = [7, 15, 30, 60, 90];

  @override
  Widget build(BuildContext context) {
    final custom = !presets.contains(days);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final d in presets)
          _DaysChip('$d', selected: d == days, onTap: () => onChanged(d)),
        _DaysChip(
          custom ? '$days' : 'Outro',
          selected: custom,
          onTap: () async {
            final v = await askDays(context, custom ? days : null);
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _DaysChip extends StatelessWidget {
  const _DaysChip(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.brandSoft : Colors.transparent,
          border: Border.all(color: selected ? c.brand : c.line, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: selected ? c.brand : c.ink,
          ),
        ),
      ),
    );
  }
}

/// Pergunta quantos dias (1–365). Devolve null se cancelar ou digitar algo inválido.
Future<int?> askDays(BuildContext context, int? current) async {
  final v = await showDialog<int>(
    context: context,
    builder: (_) => _DaysDialog(current: current),
  );
  return v?.clamp(Config.minDays, Config.maxDays);
}

/// O diálogo é dono do controlador: ele só é descartado quando a rota some
/// de vez (descartar logo após o `pop` quebra a animação de saída).
class _DaysDialog extends StatefulWidget {
  const _DaysDialog({this.current});
  final int? current;

  @override
  State<_DaysDialog> createState() => _DaysDialogState();
}

class _DaysDialogState extends State<_DaysDialog> {
  late final _ctrl = TextEditingController(
    text: widget.current == null ? '' : '${widget.current}',
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, int.tryParse(_ctrl.text));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quantos dias?'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        // "Concluído" no teclado confirma, igual ao botão OK.
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: InputDecoration(
          hintText: '${Config.minDays} a ${Config.maxDays}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String ok = 'Continuar',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok)),
      ],
    ),
  );
  return r == true;
}

/// Botões segmentados (tema, braços, pulso…): borda de 2px; ativo em brand-soft.
class SegButtons<T> extends StatelessWidget {
  const SegButtons({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      spacing: 8,
      children: [
        for (final (v, label) in options)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(v),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: v == value ? c.brandSoft : Colors.transparent,
                  border: Border.all(
                    color: v == value ? c.brand : c.line,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: v == value ? c.brand : c.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum AppButtonKind { filled, ghost, danger }

/// Botão largo das abas (btn / ghost / danger do app web).
class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    required this.onTap,
    this.kind = AppButtonKind.filled,
  });
  final String label;
  final VoidCallback? onTap;
  final AppButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, border) = switch (kind) {
      AppButtonKind.filled => (c.headerColor, AppColors.brandInk, null),
      AppButtonKind.ghost => (c.card, c.ink, c.line),
      AppButtonKind.danger => (c.card, c.danger, c.dangerLine),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: border == null
                  ? BorderSide.none
                  : BorderSide(color: border, width: 2),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
