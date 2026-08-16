import 'package:flutter/material.dart';

enum StatusBannerType { info, warning, error }

/// Banner coerente per stati come "modalità offline" o errori di rete,
/// al posto di `Container(color: Colors.orange.shade100, ...)` ad hoc.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.type = StatusBannerType.warning,
    this.icon,
  });

  final String message;
  final StatusBannerType type;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final Color bg;
    late final Color fg;
    late final IconData defaultIcon;
    switch (type) {
      case StatusBannerType.info:
        bg = scheme.secondaryContainer;
        fg = scheme.onSecondaryContainer;
        defaultIcon = Icons.info_outline;
      case StatusBannerType.warning:
        bg = scheme.tertiaryContainer;
        fg = scheme.onTertiaryContainer;
        defaultIcon = Icons.cloud_off;
      case StatusBannerType.error:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        defaultIcon = Icons.error_outline;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: bg,
      child: Row(
        children: [
          Icon(icon ?? defaultIcon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: fg, fontSize: 13))),
        ],
      ),
    );
  }
}
