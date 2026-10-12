import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/community_provider.dart';

class JoinBuildingScreen extends StatefulWidget {
  const JoinBuildingScreen({super.key});

  @override
  State<JoinBuildingScreen> createState() => _JoinBuildingScreenState();
}

class _JoinBuildingScreenState extends State<JoinBuildingScreen> {
  final _codeController = TextEditingController(text: 'REZIDANS82K9');
  bool _isOwner = false;
  bool _isLoading = false;
  String? _errorMessage;

  // New building creation state
  bool _showCreateNew = false;
  final _nameController = TextEditingController();
  final _cityController = TextEditingController(text: 'Ankara');
  final _districtController = TextEditingController(text: 'Çankaya');
  String _buildingType = 'SITE';

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Lütfen davet kodunu giriniz.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final comm = context.read<CommunityProvider>();
    // In canonical demo, apartment 103 (id=3) is default for Necati or we attach to next available apartment
    final success = await comm.joinCommunity(
      inviteCode: code,
      apartmentId: 3, // A Blok 103
      isOwner: _isOwner,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _errorMessage = comm.errorMessage ?? 'Katılım sağlanamadı.');
      }
    }
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Bina/site adını giriniz.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final comm = context.read<CommunityProvider>();
    final success = await comm.createCommunity(
      name: name,
      type: _buildingType,
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _errorMessage = comm.errorMessage ?? 'Site oluşturulamadı.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_showCreateNew ? 'Yeni Bina / Site Oluştur' : 'Binaya Katıl'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _showCreateNew = !_showCreateNew;
                _errorMessage = null;
              });
            },
            child: Text(_showCreateNew ? 'Koda Göre Katıl' : 'Yeni Site Kur'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (!_showCreateNew) ...[
                // JOIN VIA INVITE CODE / QR
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    boxShadow: isDark ? AppTheme.softShadowDark : AppTheme.softShadowLight,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Davet Kodu ile Katılın',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Yöneticinizin paylaştığı 8 haneli katılım kodunu giriniz veya QR kod ile doğrulayın.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Davet Kodu',
                          hintText: 'Örn: REZIDANS82K9',
                          prefixIcon: Icon(Icons.vpn_key_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bu dairenin kat malikiyim (Ev sahibi)'),
                        subtitle: const Text('Kiracıysanız kapalı bırakınız.'),
                        value: _isOwner,
                        onChanged: (val) => setState(() => _isOwner = val),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleJoin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Binaya Katıl'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // CREATE NEW SITE (FOR MANAGERS)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    boxShadow: isDark ? AppTheme.softShadowDark : AppTheme.softShadowLight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Yeni Apartman / Site Tanımla',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Yönetici olarak yeni bir topluluk kurup sakinlerinizi davet edebilirsiniz.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Bina / Site Adı',
                          hintText: 'Örn: Manolya Rezidans',
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _buildingType,
                        decoration: const InputDecoration(
                          labelText: 'Bina Tipi',
                          prefixIcon: Icon(Icons.home_work_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'APARTMENT', child: Text('Tek Apartman')),
                          DropdownMenuItem(value: 'SITE', child: Text('Site / Toplu Konut')),
                          DropdownMenuItem(value: 'RESIDENCE', child: Text('Rezidans')),
                        ],
                        onChanged: (v) => setState(() => _buildingType = v ?? 'SITE'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(labelText: 'İl'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _districtController,
                              decoration: const InputDecoration(labelText: 'İlçe'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleCreate,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Siteyi Kur ve Yönetici Ol'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
