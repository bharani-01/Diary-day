import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../constants.dart';
import '../services/weather_service.dart';
import '../services/biometric_service.dart';
import '../services/theme_provider.dart';
import '../services/language_provider.dart';
import '../widgets/app_ui.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _searchController = TextEditingController();
  
  String _currentLocationName = '';
  List<GeoLocation> _searchResults = [];
  bool _isSearching = false;
  bool _isSaving = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final enabled = await BiometricService.isBiometricEnabled();
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<void> _loadCurrentLocation() async {
    final location = await _weatherService.getSavedLocation();
    if (mounted) {
      setState(() {
        _currentLocationName = location['name'] as String;
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await _weatherService.searchLocations(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _selectLocation(GeoLocation location) async {
    setState(() => _isSaving = true);
    await _weatherService.saveLocation(
      location.displayName,
      location.latitude,
      location.longitude,
    );
    if (mounted) {
      setState(() {
        _currentLocationName = location.displayName;
        _searchResults = [];
        _searchController.clear();
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Weather location set to ${location.displayName}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final currentUser = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather Location Section
            _buildSectionHeader('Weather location', 'Set your farm\'s location for live weather and heat stress alerts'),
            const SizedBox(height: 12),
            
            // Current Location Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  const IconTile(Icons.location_on_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current location', style: TextStyle(fontSize: 12, color: context.mutedText)),
                        const SizedBox(height: 2),
                        Text(
                          _currentLocationName.isNotEmpty ? _currentLocationName : 'Loading…',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  if (_isSaving) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _searchLocation,
                decoration: InputDecoration(
                  hintText: 'Search for a place...',
                  hintStyle: TextStyle(color: context.subtleText),
                  prefixIcon: Icon(Icons.search, color: context.mutedText),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Search Results
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final loc = _searchResults[index];
                    return ListTile(
                      tileColor: Colors.transparent,
                      leading: Icon(Icons.place_outlined, color: context.mutedText),
                      title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${loc.admin1 ?? ''}, ${loc.country}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      trailing: Icon(Icons.chevron_right, size: 20, color: context.subtleText),
                      onTap: () => _selectLocation(loc),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: AppConstants.sectionGap),
            // Security Section
            _buildSectionHeader('Security', 'Protect your farm data with biometric authentication'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const IconTile(Icons.fingerprint),
                title: const Text('Biometric login', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Use Fingerprint or FaceID', style: TextStyle(fontSize: 12)),
                value: _biometricEnabled,
                activeColor: AppConstants.primaryColor,
                onChanged: (val) async {
                  if (val) {
                    final authenticated = await BiometricService.authenticate();
                    if (authenticated) {
                      await BiometricService.setBiometricEnabled(true);
                      setState(() => _biometricEnabled = true);
                    }
                  } else {
                    await BiometricService.setBiometricEnabled(false);
                    setState(() => _biometricEnabled = false);
                  }
                },
              ),
            ),

            const SizedBox(height: AppConstants.sectionGap),
            // Display Section
            _buildSectionHeader('Display', 'Customize the app appearance'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: IconTile(themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                    title: const Text('Dark mode', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Toggle visual appearance', style: TextStyle(fontSize: 12)),
                    value: themeProvider.isDarkMode,
                    activeColor: AppConstants.primaryColor,
                    onChanged: (val) {
                      themeProvider.toggleTheme();
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: AppConstants.sectionGap),
            // App Info Section
            _buildSectionHeader('About', 'KRB Dairy Farms v1.0'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  _buildInfoRow('App Version', '1.0.0'),
                  const Divider(),
                  _buildInfoRow('Developer', 'KRB Technologies'),
                  const Divider(),
                  _buildInfoRow('Default Location', 'Paramathi Velur, Namakkal, TN'),
                  const Divider(),
                  _buildClickableInfoRow(lp.translate('privacy_policy'), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                  }),
                  const Divider(),
                  _buildClickableInfoRow(lp.translate('terms_conditions'), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen()));
                  }),
                ],
              ),
            ),
            if (currentUser != null) ...[
              const SizedBox(height: AppConstants.sectionGap),
              _buildSectionHeader(lp.translate('account'), '${lp.translate('signed_in_as')}: ${currentUser.email}'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  tileColor: Colors.transparent,
                  leading: const IconTile(Icons.logout, color: AppConstants.dangerColor),
                  title: Text(lp.translate('logout'), style: const TextStyle(fontWeight: FontWeight.w600, color: AppConstants.dangerColor)),
                  subtitle: Text(lp.isTamil ? 'அமர்விலிருந்து வெளியேறு' : 'Sign out of your session', style: const TextStyle(fontSize: 12)),
                  trailing: Icon(Icons.chevron_right, size: 20, color: context.subtleText),
                  onTap: () => _showLogoutDialog(context, lp),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, LanguageProvider lp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lp.translate('logout_confirm')),
        content: Text(lp.translate('logout_subtitle')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lp.translate('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppConstants.dangerColor),
            child: Text(lp.translate('logout')),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 13, color: context.mutedText)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildClickableInfoRow(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            Icon(Icons.chevron_right, size: 20, color: context.subtleText),
          ],
        ),
      ),
    );
  }
}
