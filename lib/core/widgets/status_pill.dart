import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = status.replaceAll('_', ' ').toUpperCase();
    final color = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _colorFor(String status) {
    switch (status) {
      case 'live':
      case 'paid':
      case 'approved':
      case 'live_tracking':
        return const Color(0xFF006C49);
      case 'rejected':
        return const Color(0xFFBA1A1A);
      case 'awaiting_live_link':
        return const Color(0xFF630ED4);
      default:
        return const Color(0xFFAA4900);
    }
  }
}
