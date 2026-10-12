import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/poll_provider.dart';
import '../../widgets/empty_state_view.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  void _load() {
    final comm = context.read<CommunityProvider>();
    if (comm.activeCommunity != null) {
      context.read<PollProvider>().loadPolls(comm.activeCommunity!.id);
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final opt1Controller = TextEditingController();
    final opt2Controller = TextEditingController();
    final opt3Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Anket Oluştur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Anket Sorusu')),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Açıklama (İsteğe bağlı)')),
              const SizedBox(height: 12),
              TextField(controller: opt1Controller, decoration: const InputDecoration(labelText: '1. Seçenek')),
              const SizedBox(height: 8),
              TextField(controller: opt2Controller, decoration: const InputDecoration(labelText: '2. Seçenek')),
              const SizedBox(height: 8),
              TextField(controller: opt3Controller, decoration: const InputDecoration(labelText: '3. Seçenek (İsteğe bağlı)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty || opt1Controller.text.trim().isEmpty || opt2Controller.text.trim().isEmpty) return;
              final comm = context.read<CommunityProvider>();
              if (comm.activeCommunity != null) {
                final options = [opt1Controller.text, opt2Controller.text];
                if (opt3Controller.text.trim().isNotEmpty) options.add(opt3Controller.text);

                await context.read<PollProvider>().createPoll(
                      communityId: comm.activeCommunity!.id,
                      title: titleController.text,
                      description: descController.text,
                      options: options,
                    );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Yayınla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comm = context.watch<CommunityProvider>();
    final pollProvider = context.watch<PollProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isManager = comm.isCurrentUserManager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anketler'),
        actions: [
          if (isManager)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Anket Oluştur',
              onPressed: _showCreateDialog,
            ),
        ],
      ),
      body: pollProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : pollProvider.polls.isEmpty
              ? EmptyStateView(
                  icon: Icons.poll_rounded,
                  title: 'Aktif bir anket bulunmuyor.',
                  actionLabel: isManager ? 'Anket Oluştur' : null,
                  onAction: isManager ? _showCreateDialog : null,
                )
              : RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: pollProvider.polls.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, index) {
                      final poll = pollProvider.polls[index];

                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.poll_rounded, color: AppColors.secondary, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    poll.title,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            if (poll.description != null && poll.description!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(poll.description!, style: Theme.of(context).textTheme.bodySmall),
                            ],
                            const SizedBox(height: 16),

                            // Option Bars
                            ...poll.options.map((opt) {
                              final isVoted = poll.userVotedOptionId == opt.id;
                              final pct = opt.votePercentage / 100.0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: InkWell(
                                  onTap: poll.hasVoted
                                      ? null
                                      : () {
                                          context.read<PollProvider>().vote(poll.id, opt.id, poll.communityId);
                                        },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isVoted
                                          ? AppColors.primary.withValues(alpha: 0.12)
                                          : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isVoted ? AppColors.primary : AppColors.borderLight,
                                        width: isVoted ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                opt.label,
                                                style: TextStyle(
                                                  fontWeight: isVoted ? FontWeight.w700 : FontWeight.w500,
                                                  color: isVoted ? AppColors.primary : null,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '%${opt.votePercentage.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: isVoted ? AppColors.primary : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pct.clamp(0.0, 1.0),
                                            backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              isVoted ? AppColors.primary : AppColors.secondary,
                                            ),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),

                            const SizedBox(height: 4),
                            Text(
                              poll.hasVoted ? '✓ Oyunuz kaydedildi (Toplam oy: ${poll.totalVotes})' : 'Oy vermek için seçeneğe dokunun',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: poll.hasVoted ? AppColors.success : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
