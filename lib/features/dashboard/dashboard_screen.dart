import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_base_url.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/format/money_format.dart';
import '../../theme/token_colors.dart';

final dashboardProvider = FutureProvider<CreatorDashboard>((ref) async {
  return ref.read(apiClientProvider).fetchDashboard();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moneyColor =
        isDark ? ViralCutTokenColors.moneyDark : ViralCutTokenColors.moneyLight;

    return dash.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Cannot reach API at $kApiBaseUrl',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Physical phone: use your PC IP, not 10.0.2.2.\n'
                'flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3001',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(dashboardProvider),
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => context.go('/profile'),
                child: const Text('Go to You → Log out'),
              ),
            ],
          ),
        ),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hey Creator 👋',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Post clips. Get paid.',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => context.go('/profile'),
                  icon: const CircleAvatar(child: Icon(Icons.person)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.military_tech, color: ViralCutTokenColors.primaryLight),
                  const SizedBox(width: 12),
                  Text(
                    'Silver Clipper',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? ViralCutTokenColors.deepSurface
                    : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total earned',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  Text(
                    formatPaise(data.wallet.lifetimePaise),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatChip(
                        label: 'Available',
                        value: formatPaise(data.wallet.availablePaise),
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: 'Pending',
                        value: formatPaise(data.wallet.pendingPaise),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/wallet'),
                    child: const Text('Withdraw'),
                  ),
                ],
              ),
            ),
            if (data.clipsUnderReview > 0) ...[
              const SizedBox(height: 12),
              ListTile(
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text('${data.clipsUnderReview} clips under review'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/submissions'),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Trending campaigns',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ...data.trending.map(
              (c) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(c.title),
                  subtitle: Text(
                    c.ratePer1kDisplay,
                    style: TextStyle(color: moneyColor, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/campaigns/${c.id}'),
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/campaigns'),
              child: const Text('View all campaigns'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
