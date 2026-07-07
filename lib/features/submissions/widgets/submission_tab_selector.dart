import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/halchal_colors.dart';

class SubmissionTabSelector extends StatelessWidget {
  const SubmissionTabSelector({
    super.key,
    required this.selectedTab,
    required this.activeCount,
    required this.completedCount,
    required this.onTabSelected,
  });

  final String selectedTab;
  final int activeCount;
  final int completedCount;
  final ValueChanged<String> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SubmissionTabPill(
            label: 'Active',
            count: activeCount,
            selected: selectedTab == 'active',
            onTap: () => onTabSelected('active'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SubmissionTabPill(
            label: 'Completed',
            count: completedCount,
            selected: selectedTab == 'completed',
            onTap: () => onTabSelected('completed'),
          ),
        ),
      ],
    );
  }
}

class _SubmissionTabPill extends StatelessWidget {
  const _SubmissionTabPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    final background = selected
        ? primary.withValues(alpha: 0.1)
        : vc.surfaceVariant.withValues(alpha: 0.55);
    final borderColor =
        selected ? primary.withValues(alpha: 0.28) : vc.border;
    final textColor = selected ? primary : vc.muted;

    return Material(
      color: background,
      shape: StadiumBorder(side: BorderSide(color: borderColor)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Center(
            child: Text(
              '$label ($count)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
