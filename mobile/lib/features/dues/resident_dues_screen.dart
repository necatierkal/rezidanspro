import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/dues_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state_view.dart';

class ResidentDuesScreen extends StatefulWidget {
  const ResidentDuesScreen({super.key});

  @override
  State<ResidentDuesScreen> createState() => _ResidentDuesScreenState();
}

class _ResidentDuesScreenState extends State<ResidentDuesScreen> {
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
      context.read<DuesProvider>().loadMyDues(comm.activeCommunity!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comm = context.watch<CommunityProvider>();
    final duesProvider = context.watch<DuesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final myDues = duesProvider.myDues;
    final aptDisplay = comm.activeMembership?.apartmentDisplay ?? 'Daireniz';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aidat Durumum'),
      ),
      body: duesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : myDues.isEmpty
              ? EmptyStateView(
                  icon: Icons.credit_card_rounded,
                  title: 'Bu döneme ait aidat kaydınız bulunmuyor.',
                  subtitle: 'Yeni bir aidat tanımlandığında burada görüntüleyebilirsiniz.',
                )
              : RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Hero Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            boxShadow: AppTheme.softShadowLight,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                aptDisplay,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Toplam Borç Durumu',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '₺${duesProvider.myTotalUnpaidAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  duesProvider.hasMyUnpaidDues ? 'Ödenmemiş Aidat Var' : 'Ödenmemiş Borç Yok',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bank Transfer Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.account_balance_rounded, size: 20, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Bina Yönetim Hesabı (IBAN)',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const SelectableText(
                                'TR42 0006 2000 0001 2345 6789 01',
                                style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Alıcı: Gül Sitesi Yöneticiliği\nAçıklama kısmına Blok ve Daire No yazınız.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'DÖNEM AİDATLARI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: myDues.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final due = myDues[index];
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
                                          due.period,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Son Ödeme: ${due.dueDate.toLocal().toString().substring(0, 10)}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        if (due.notes != null && due.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            due.notes!,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₺${due.amount.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 6),
                                      StatusBadge(status: due.status, isDues: true),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
