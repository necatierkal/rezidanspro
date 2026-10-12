import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/dues_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state_view.dart';

class ManagerDuesScreen extends StatefulWidget {
  const ManagerDuesScreen({super.key});

  @override
  State<ManagerDuesScreen> createState() => _ManagerDuesScreenState();
}

class _ManagerDuesScreenState extends State<ManagerDuesScreen> {
  String _selectedStatus = 'ALL';

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
      context.read<DuesProvider>().loadManagerDues(comm.activeCommunity!.id);
    }
  }

  void _showCreateDueDialog() {
    final periodController = TextEditingController(text: 'Ekim 2026');
    final amountController = TextEditingController(text: '2500');
    final notesController = TextEditingController();
    int selectedAptId = 3; // default A Blok 103

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Yeni Aidat Tanımla'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedAptId,
                  decoration: const InputDecoration(labelText: 'Daire Seçimi'),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('A Blok - Daire 103 (Necati E.)')),
                    DropdownMenuItem(value: 14, child: Text('B Blok - Daire 104 (Ayşe D.)')),
                    DropdownMenuItem(value: 1, child: Text('A Blok - Daire 101')),
                    DropdownMenuItem(value: 2, child: Text('A Blok - Daire 102')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedAptId = v ?? 3),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: periodController,
                  decoration: const InputDecoration(labelText: 'Dönem', hintText: 'Örn: Ekim 2026'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tutar (₺)', hintText: '2500'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Açıklama / Not'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (amt <= 0) return;

                final comm = context.read<CommunityProvider>();
                if (comm.activeCommunity != null) {
                  await context.read<DuesProvider>().createDue(
                        communityId: comm.activeCommunity!.id,
                        apartmentId: selectedAptId,
                        period: periodController.text,
                        amount: amt,
                        dueDate: DateTime.now().add(const Duration(days: 10)),
                        notes: notesController.text,
                      );
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordPaymentDialog(int dueId, double dueAmount, String aptInfo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ödeme Onayı: $aptInfo'),
        content: Text('₺${dueAmount.toStringAsFixed(0)} tutarındaki aidatı "Ödendi" olarak sisteme işlemek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final comm = context.read<CommunityProvider>();
              if (comm.activeCommunity != null) {
                await context.read<DuesProvider>().recordPayment(
                      dueId: dueId,
                      amount: dueAmount,
                      paymentMethod: 'BANK_TRANSFER',
                      reference: 'MANUAL_APPROVAL',
                      communityId: comm.activeCommunity!.id,
                    );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Ödendi Olarak İşle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duesProvider = context.watch<DuesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    var dues = duesProvider.managerDues;
    if (_selectedStatus != 'ALL') {
      dues = dues.where((d) => d.status == _selectedStatus).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aidat Yönetimi (Tüm Daireler)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Aidat Tanımla',
            onPressed: _showCreateDueDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tümü'),
                  selected: _selectedStatus == 'ALL',
                  onSelected: (_) => setState(() => _selectedStatus = 'ALL'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Ödenmedi'),
                  selected: _selectedStatus == 'UNPAID',
                  onSelected: (_) => setState(() => _selectedStatus = 'UNPAID'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Ödendi'),
                  selected: _selectedStatus == 'PAID',
                  onSelected: (_) => setState(() => _selectedStatus = 'PAID'),
                ),
              ],
            ),
          ),
          const Divider(),

          Expanded(
            child: duesProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : dues.isEmpty
                    ? EmptyStateView(
                        icon: Icons.credit_card_rounded,
                        title: 'Bu kritere uygun aidat kaydı bulunmuyor.',
                        actionLabel: 'Aidat Tanımla',
                        onAction: _showCreateDueDialog,
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _load(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: dues.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final due = dues[index];
                            final aptStr = '${due.blockName ?? ""} No: ${due.apartmentNo ?? ""}';

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          aptStr,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Dönem: ${due.period}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        Text(
                                          'Tutar: ₺${due.amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: due.status == 'PAID' ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      StatusBadge(status: due.status, isDues: true),
                                      const SizedBox(height: 8),
                                      if (due.status != 'PAID') ...[
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            minimumSize: Size.zero,
                                          ),
                                          onPressed: () => _showRecordPaymentDialog(due.id, due.amount, aptStr),
                                          child: const Text('Ödeme İşle', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
