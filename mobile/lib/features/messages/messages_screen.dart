import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/message_provider.dart';
import '../../widgets/empty_state_view.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
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
      context.read<MessageProvider>().loadMessages(comm.activeCommunity!.id);
    }
  }

  void _showNewMessageDialog() {
    final comm = context.read<CommunityProvider>();
    final isManager = comm.isCurrentUserManager;
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    // If manager, select resident (e.g. Necati id=2, Ayşe id=3)
    // If resident, receiver is always manager (id=1)
    int receiverId = isManager ? 2 : 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isManager ? 'Sakine Özel Mesaj Gönder' : 'Yöneticiye Özel Mesaj'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isManager) ...[
                  DropdownButtonFormField<int>(
                    value: receiverId,
                    decoration: const InputDecoration(labelText: 'Alıcı Sakin'),
                    items: const [
                      DropdownMenuItem(value: 2, child: Text('Necati Erkal (A Blok 103)')),
                      DropdownMenuItem(value: 3, child: Text('Ayşe Demir (B Blok 104)')),
                    ],
                    onChanged: (v) => setDialogState(() => receiverId = v ?? 2),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Konu', hintText: 'Örn: Aidat Bilgilendirmesi'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Mesajınız', hintText: 'Mesajınızı yazınız...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (bodyController.text.trim().isEmpty) return;
                final comm = context.read<CommunityProvider>();
                if (comm.activeCommunity != null) {
                  await context.read<MessageProvider>().sendMessage(
                        communityId: comm.activeCommunity!.id,
                        receiverId: receiverId,
                        subject: subjectController.text,
                        body: bodyController.text,
                      );
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myId = auth.currentUser?.id ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Özel Mesajlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Yeni Mesaj Yaz',
            onPressed: _showNewMessageDialog,
          ),
        ],
      ),
      body: messageProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : messageProvider.messages.isEmpty
              ? EmptyStateView(
                  icon: Icons.mail_outline_rounded,
                  title: 'Henüz özel mesajınız yok.',
                  subtitle: 'Yönetici ile birebir güvenli ve gizli mesajlaşma başlatabilirsiniz.',
                  actionLabel: 'Mesaj Yaz',
                  onAction: _showNewMessageDialog,
                )
              : RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: messageProvider.messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final item = messageProvider.messages[index];
                      final isMine = item.isSentByMe(myId);
                      final otherPartyName = isMine ? item.receiverName : item.senderName;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          boxShadow: isDark ? AppTheme.softShadowDark : AppTheme.softShadowLight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  child: Icon(
                                    isMine ? Icons.arrow_outward_rounded : Icons.mark_email_unread_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isMine ? 'Kime: $otherPartyName' : 'Kimden: $otherPartyName',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                      Text(
                                        item.createdAt.toLocal().toString().substring(0, 16),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.readAt == null && !isMine)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('Yeni', style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ),
                              ],
                            ),
                            if (item.subject != null && item.subject!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                item.subject!,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              item.body,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
