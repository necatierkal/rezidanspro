import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/community_provider.dart';

class BuildingInfoScreen extends StatelessWidget {
  const BuildingInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final comm = context.watch<CommunityProvider>();
    final activeComm = comm.activeCommunity;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Binamız & İletişim'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Site Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeComm?.name ?? 'Gül Sitesi',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activeComm?.district ?? "Çankaya"} / ${activeComm?.city ?? "Ankara"}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activeComm?.address ?? 'Atatürk Bulvarı No: 142',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ACİL NUMARALAR (Sec 33)
            Text(
              'ACİL İLETİŞİM NUMARALARI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 10),

            _EmergencyTile(
              title: '112 Acil Çağrı Merkezi',
              subtitle: 'Ambulans, Polis, İtfaiye, Jandarma (Tek Numara)',
              phone: '112',
              icon: Icons.local_hospital_rounded,
              color: AppColors.error,
            ),
            const SizedBox(height: 8),
            _EmergencyTile(
              title: 'Site Güvenlik Noktası',
              subtitle: '7/24 Güvenlik ve Giriş Kontrol',
              phone: '+90 312 400 0001',
              icon: Icons.shield_rounded,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 8),
            _EmergencyTile(
              title: 'Asansör Arıza & Servis',
              subtitle: '7/24 Acil Kurtarma',
              phone: '+90 312 400 0002',
              icon: Icons.elevator_rounded,
              color: AppColors.warning,
            ),
            const SizedBox(height: 8),
            _EmergencyTile(
              title: 'Doğalgaz Acil (187)',
              subtitle: 'Gaz Kaçağı İhbar',
              phone: '187',
              icon: Icons.local_fire_department_rounded,
              color: AppColors.statusInProgress,
            ),
            const SizedBox(height: 24),

            // BİNA KURALLARI (Sec 34)
            Text(
              'SİTE KURALLARI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RuleItem(number: '1', title: 'Sessizlik Saatleri', desc: 'Hafta içi ve hafta sonu 23:00 - 08:00 saatleri arasında yüksek ses yapılmamalıdır.'),
                  const SizedBox(height: 12),
                  _RuleItem(number: '2', title: 'Otopark Düzeni', desc: 'Misafir ve sakin araçları sadece tahsis edilen numaralı alanlara park edilmelidir.'),
                  const SizedBox(height: 12),
                  _RuleItem(number: '3', title: 'Ortak Alanlar', desc: 'Bina koridorları ve yangın merdivenlerine eşya, ayakkabılık ve çöp bırakılmamalıdır.'),
                  const SizedBox(height: 12),
                  _RuleItem(number: '4', title: 'Evcil Hayvanlar', desc: 'Evcil hayvanların ortak alan ve bahçede tasmayla gezdirilmesi zorunludur.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String phone;
  final IconData icon;
  final Color color;

  const _EmergencyTile({
    required this.title,
    required this.subtitle,
    required this.phone,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              phone,
              style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _RuleItem({required this.number, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: AppColors.primary,
          child: Text(number, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
