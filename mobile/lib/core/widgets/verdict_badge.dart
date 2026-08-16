import 'package:flutter/material.dart';

enum VerdictTone { positive, negative, neutral }

/// Badge di verdetto (es. "RILANCIA" / "ABBANDONA", "FAVOREVOLE" / "SFAVOREVOLE"),
/// usato in Asta e Scambio al posto di Row+Icon+Text colorati manualmente.
class VerdictBadge extends StatelessWidget {
  const VerdictBadge({super.key, required this.label, required this.tone, this.icon});

  final String label;
  final VerdictTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final Color bg;
    late final Color fg;
    late final IconData defaultIcon;
    switch (tone) {
      case VerdictTone.positive:
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
        defaultIcon = Icons.trending_up;
      case VerdictTone.negative:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        defaultIcon = Icons.trending_down;
      case VerdictTone.neutral:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
        defaultIcon = Icons.balance;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? defaultIcon, color: fg, size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
