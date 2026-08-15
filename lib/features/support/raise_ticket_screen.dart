import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/halchal_colors.dart';
import 'support_providers.dart';

class RaiseTicketScreen extends ConsumerStatefulWidget {
  const RaiseTicketScreen({super.key});

  @override
  ConsumerState<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends ConsumerState<RaiseTicketScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.length < 3 || message.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Add a subject and a few more details before submitting.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(apiClientProvider)
          .createSupportTicket(subject: subject, message: message);
      if (!mounted) return;
      _subjectController.clear();
      _messageController.clear();
      ref.invalidate(supportTicketsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ticket submitted — we\'ll take a look shortly.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final tickets = ref.watch(supportTicketsProvider);

    return VcScaffold(
      title: 'Raise a Ticket',
      showBack: true,
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(supportTicketsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: vc.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: vc.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tell us what\'s going on and we\'ll look into it.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: vc.muted, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  _TicketField(
                      controller: _subjectController,
                      hint: 'Subject',
                      vc: vc,
                      maxLines: 1),
                  const SizedBox(height: 10),
                  _TicketField(
                      controller: _messageController,
                      hint: 'Describe your issue',
                      vc: vc,
                      maxLines: 5),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vc.primary,
                        foregroundColor: vc.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: vc.onPrimary),
                            )
                          : Text(
                              'Submit Ticket',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'MY TICKETS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: vc.muted,
              ),
            ),
            const SizedBox(height: 10),
            tickets.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                'Couldn\'t load your tickets.',
                style: GoogleFonts.inter(fontSize: 13, color: vc.muted),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Text(
                    'No tickets yet.',
                    style: GoogleFonts.inter(fontSize: 13, color: vc.muted),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: vc.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: vc.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        _TicketTile(ticket: items[i]),
                        if (i != items.length - 1)
                          Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: vc.border),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketField extends StatelessWidget {
  const _TicketField(
      {required this.controller,
      required this.hint,
      required this.vc,
      required this.maxLines});
  final TextEditingController controller;
  final String hint;
  final HalchalColors vc;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 13.5, color: vc.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13.5, color: vc.muted),
        filled: true,
        fillColor: vc.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});
  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final vc = HalchalColors.of(context);
    final resolved = ticket.status == 'resolved';
    final reviewing = !resolved && ticket.resolutionNote != null;
    final pillColor = resolved
        ? vc.moneyBright
        : reviewing
            ? vc.primary
            : vc.warningBright;
    final pillLabel = resolved
        ? 'Resolved'
        : reviewing
            ? 'Under Review'
            : 'Under investigation';

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        iconColor: vc.primary,
        collapsedIconColor: vc.muted,
        title: Text(
          ticket.subject,
          style: GoogleFonts.inter(
              fontSize: 13.5, fontWeight: FontWeight.w700, color: vc.onSurface),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pillColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pillLabel,
                style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: pillColor),
              ),
            ),
          ),
        ),
        children: [
          Text(
            ticket.message,
            style:
                GoogleFonts.inter(fontSize: 13, color: vc.muted, height: 1.45),
          ),
          if (ticket.resolutionNote != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: vc.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolved ? 'Response' : 'Latest update',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: vc.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.resolutionNote!,
                    style: GoogleFonts.inter(
                        fontSize: 12.5, color: vc.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
