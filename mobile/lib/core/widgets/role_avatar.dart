import 'package:flutter/material.dart';

import '../theme.dart';

/// Avatar circolare colorato per ruolo (P/D/C/A), usato ovunque compaia
/// un giocatore in lista per dare riconoscibilità visiva immediata.
class RoleAvatar extends StatelessWidget {
  const RoleAvatar({super.key, required this.ruolo, this.radius = 18});

  final String ruolo;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = RoleColors.of(ruolo);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.16),
      child: Text(
        ruolo,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.65,
        ),
      ),
    );
  }
}
