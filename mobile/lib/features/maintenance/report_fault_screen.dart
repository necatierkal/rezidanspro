import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/maintenance_provider.dart';

class ReportFaultScreen extends StatefulWidget {
  const ReportFaultScreen({super.key});

  @override
  State<ReportFaultScreen> createState() => _ReportFaultScreenState();
}

class _ReportFaultScreenState extends State<ReportFaultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'ELEVATOR';
  String _selectedPriority = 'NORMAL';
  bool _photoAttached = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'ELEVATOR', 'label': 'Asansör', 'icon': Icons.elevator_rounded},
    {'id': 'WATER', 'label': 'Su / Tesisat', 'icon': Icons.water_drop_rounded},
    {'id': 'ELECTRICITY', 'label': 'Elektrik', 'icon': Icons.bolt_rounded},
    {'id': 'LIGHTING', 'label': 'Aydınlatma', 'icon': Icons.lightbulb_rounded},
    {'id': 'DOOR', 'label': 'Kapı / Giriş', 'icon': Icons.door_front_door_rounded},
    {'id': 'PARKING', 'label': 'Otopark', 'icon': Icons.local_parking_rounded},
    {'id': 'GARDEN', 'label': 'Bahçe / Peyzaj', 'icon': Icons.park_rounded},
    {'id': 'HEATING', 'label': 'Isıtma', 'icon': Icons.thermostat_rounded},
    {'id': 'CLEANING', 'label': 'Temizlik', 'icon': Icons.cleaning_services_rounded},
    {'id': 'SECURITY', 'label': 'Güvenlik', 'icon': Icons.security_rounded},
    {'id': 'OTHER', 'label': 'Diğer', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final comm = context.read<CommunityProvider>();
    if (comm.activeCommunity == null) return;

    setState(() => _isLoading = true);

    final success = await context.read<MaintenanceProvider>().reportFault(
      communityId: comm.activeCommunity!.id,
      title: _titleController.text,
      description: _descController.text,
      category: _selectedCategory,
      priority: _selectedPriority,
      photoUrl: _photoAttached ? 'https://rezidanspro.app/mock-photo.jpg' : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arıza bildirimi yönetime başarıyla iletildi.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arıza Bildir'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Arıza Kategorisi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                // Category Grid / Wrap
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final isSelected = _selectedCategory == c['id'];
                    return ChoiceChip(
                      avatar: Icon(c['icon'] as IconData, size: 16),
                      label: Text(c['label'] as String),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = c['id'] as String),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Arıza Başlığı',
                    hintText: 'Örn: Asansör çalışmıyor',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık giriniz' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama & Detay',
                    hintText: 'Arızanın yerini ve durumunu detaylıca açıklayınız...',
                  ),
                  validator: (v) => (v == null || v.trim().length < 5) ? 'En az 5 karakter açıklama giriniz' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(labelText: 'Aciliyet'),
                  items: const [
                    DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                    DropdownMenuItem(value: 'IMPORTANT', child: Text('Önemli')),
                    DropdownMenuItem(value: 'URGENT', child: Text('Acil')),
                  ],
                  onChanged: (v) => setState(() => _selectedPriority = v ?? 'NORMAL'),
                ),
                const SizedBox(height: 16),

                // Photo Attachment Simulation (Sec 16)
                InkWell(
                  onTap: () {
                    setState(() => _photoAttached = !_photoAttached);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _photoAttached ? AppColors.success : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: _photoAttached ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _photoAttached ? Icons.check_circle_rounded : Icons.add_a_photo_outlined,
                          color: _photoAttached ? AppColors.success : AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _photoAttached ? '1 Fotoğraf Eklendi (Kaldırmak için dokunun)' : 'Fotoğraf Ekle (İsteğe bağlı)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _photoAttached ? AppColors.success : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Arıza Bildirimini Gönder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
