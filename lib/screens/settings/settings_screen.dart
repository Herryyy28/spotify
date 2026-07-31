import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../admin/admin_dashboard_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Account Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark ? AppColors.cardDark : AppColors.cardLight,
                        isDark ? AppColors.elevatedDark : Colors.grey[100]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary,
                        backgroundImage: userProvider.user?.photoURL != null
                            ? NetworkImage(userProvider.user!.photoURL!)
                            : null,
                        child: userProvider.user?.photoURL == null
                            ? Text(
                                (userProvider.user?.displayName
                                            ?.substring(0, 1) ??
                                        'U')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userProvider.user?.displayName ?? 'User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userProvider.user?.email ?? 'user@example.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.spotifyGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          userProvider.isPremium ? 'Premium' : 'Free',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (userProvider.isAdmin) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader('Admin Panel', isDark),
                  const SizedBox(height: 16),
                  _buildSettingsTile(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Dashboard',
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                    textColor: Colors.redAccent,
                  ),
                ],

                const SizedBox(height: 32),

                // Preferences Section
                _buildSectionHeader('Preferences', isDark),
                const SizedBox(height: 16),

                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  isDark: isDark,
                  onTap: () {
                    _showEditProfileDialog(context, userProvider);
                  },
                ),

                // Open Admin Dashboard tile for Admins only
                if (userProvider.isAdmin)
                  _buildSettingsTile(
                    icon: Icons.admin_panel_settings,
                    title: 'Open Admin Dashboard',
                    isDark: isDark,
                    textColor: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                  ),

                // Theme Toggle
                _buildThemeTile(
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  isDark: isDark,
                  currentTheme: themeProvider.themeModeValue == ThemeMode.dark
                      ? 'Dark'
                      : themeProvider.themeModeValue == ThemeMode.light
                          ? 'Light'
                          : 'System',
                  onTap: () {
                    _showThemeDialog(context, themeProvider);
                  },
                ),

                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  isDark: isDark,
                  trailing: userProvider.preferences['pushNotifications'] == false ? 'Off' : 'On',
                  onTap: () => _showNotificationsDialog(context, userProvider),
                ),

                _buildSettingsTile(
                  icon: Icons.download_outlined,
                  title: 'Download Quality',
                  isDark: isDark,
                  trailing: userProvider.preferences['downloadQuality'] ?? 'High',
                  onTap: () => _showQualityDialog(context, userProvider, 'Download Quality', 'downloadQuality'),
                ),

                _buildSettingsTile(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  isDark: isDark,
                  trailing: userProvider.preferences['language'] ?? 'English',
                  onTap: () => _showLanguageDialog(context, userProvider),
                ),

                const SizedBox(height: 32),

                // Privacy Section
                _buildSectionHeader('Privacy & Security', isDark),
                const SizedBox(height: 16),

                _buildSettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Privacy Settings',
                  isDark: isDark,
                  onTap: () => _showPrivacyDialog(context, userProvider),
                ),

                _buildSettingsTile(
                  icon: Icons.security_outlined,
                  title: 'Security',
                  isDark: isDark,
                  onTap: () => _showSecurityDialog(context, userProvider),
                ),

                const SizedBox(height: 32),

                // About Section
                _buildSectionHeader('About', isDark),
                const SizedBox(height: 16),

                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'About Harmony Music',
                  isDark: isDark,
                  trailing: 'v1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),

                _buildSettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  isDark: isDark,
                  onTap: () => _showDocumentDialog(
                    context,
                    'Terms & Conditions',
                    'Welcome to Harmony Music.\n\n1. Acceptance of Terms: By accessing or using Harmony Music, you agree to comply with these terms.\n2. User Accounts: You are responsible for safeguarding your credentials.\n3. Content Usage: All streamed tracks are for personal, non-commercial enjoyment.\n4. Audio Quality & Data: Playback streams are subject to device network bandwidth.\n5. Intellectual Property: Harmony Music respects artist rights.',
                  ),
                ),

                _buildSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  isDark: isDark,
                  onTap: () => _showDocumentDialog(
                    context,
                    'Privacy Policy',
                    'Harmony Music Privacy Policy\n\n1. Information Collection: We store your account email, display name, liked songs, and listening history.\n2. Data Encryption: All account records are stored securely on Firebase cloud servers.\n3. Data Rights: You have full control to edit your profile, update settings, or permanently delete your account.\n4. Cookies & Analytics: Anonymous performance diagnostics are logged to improve app performance.',
                  ),
                ),

                const SizedBox(height: 32),

                // Logout Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade400,
                        Colors.orange.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () async {
                        final confirm = await _showLogoutDialog(context);
                        if (confirm == true) {
                          await userProvider.signOut();
                          if (context.mounted) {
                            Navigator.of(context)
                                .pushReplacementNamed('/login');
                          }
                        }
                      },
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                if (!userProvider.isAnonymous) ...[
                  const SizedBox(height: 16),
                  // Delete Account Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade600,
                          Colors.red.shade800,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () async {
                          final confirm = await _showDeleteAccountDialog(context);
                          if (confirm == true) {
                            final success = await userProvider.deleteAccount();
                            if (context.mounted) {
                              if (success) {
                                Navigator.of(context).pushReplacementNamed('/login');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(userProvider.error ?? 'Failed to delete account. Please re-login and try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_forever, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Delete Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required bool isDark,
    String? trailing,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withValues(alpha: 0.5) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: textColor ?? AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          textColor ?? (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTile({
    required IconData icon,
    required String title,
    required bool isDark,
    required String currentTheme,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withValues(alpha: 0.5) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Text(
                  currentTheme,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showThemeDialog(
      BuildContext context, ThemeProvider themeProvider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text(
          'Choose Theme',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              'Light',
              Icons.light_mode,
              themeProvider.themeMode == AppTheme.light,
              () {
                themeProvider.setTheme(AppTheme.light);
                Navigator.pop(context);
              },
              isDark,
            ),
            _buildThemeOption(
              context,
              'Dark',
              Icons.dark_mode,
              themeProvider.themeMode == AppTheme.dark,
              () {
                themeProvider.setTheme(AppTheme.dark);
                Navigator.pop(context);
              },
              isDark,
            ),
            _buildThemeOption(
              context,
              'System',
              Icons.settings_system_daydream,
              themeProvider.themeMode == AppTheme.system,
              () {
                themeProvider.setTheme(AppTheme.system);
                Navigator.pop(context);
              },
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppColors.primary
            : (isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white : Colors.black),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }

  Future<void> _showEditProfileDialog(
      BuildContext context, UserProvider userProvider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController =
        TextEditingController(text: userProvider.user?.displayName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            labelText: 'Display Name',
            labelStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await userProvider.updateDisplayName(newName);
                await userProvider.updateProfile({'name': newName});
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotificationsDialog(BuildContext context, UserProvider userProvider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = userProvider.preferences;
    bool pushEnabled = prefs['pushNotifications'] ?? true;
    bool emailEnabled = prefs['emailNotifications'] ?? false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          title: Text(
            'Notification Settings',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Push Notifications', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                subtitle: const Text('New music releases & recommendation alerts'),
                value: pushEnabled,
                activeColor: AppColors.primary,
                onChanged: (val) => setDialogState(() => pushEnabled = val),
              ),
              SwitchListTile(
                title: Text('Email Updates', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                subtitle: const Text('Weekly digest and playlist updates'),
                value: emailEnabled,
                activeColor: AppColors.primary,
                onChanged: (val) => setDialogState(() => emailEnabled = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                await userProvider.updatePreferences({
                  ...prefs,
                  'pushNotifications': pushEnabled,
                  'emailNotifications': emailEnabled,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQualityDialog(BuildContext context, UserProvider userProvider, String title, String key) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = ['Low (96 kbps)', 'Normal (160 kbps)', 'High (320 kbps)', 'Lossless'];
    final currentVal = userProvider.preferences[key] ?? 'High';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => RadioListTile<String>(
            title: Text(opt, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            value: opt,
            groupValue: currentVal,
            activeColor: AppColors.primary,
            onChanged: (val) async {
              if (val != null) {
                final newPrefs = Map<String, dynamic>.from(userProvider.preferences);
                newPrefs[key] = val;
                await userProvider.updatePreferences(newPrefs);
                if (context.mounted) Navigator.pop(context);
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context, UserProvider userProvider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languages = ['English', 'Spanish', 'French', 'German', 'Hindi', 'Japanese', 'Portuguese'];
    final currentLang = userProvider.preferences['language'] ?? 'English';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text('Select Language', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: languages.map((lang) => RadioListTile<String>(
              title: Text(lang, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              value: lang,
              groupValue: currentLang,
              activeColor: AppColors.primary,
              onChanged: (val) async {
                if (val != null) {
                  final newPrefs = Map<String, dynamic>.from(userProvider.preferences);
                  newPrefs['language'] = val;
                  await userProvider.updatePreferences(newPrefs);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _showPrivacyDialog(BuildContext context, UserProvider userProvider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = userProvider.preferences;
    bool isPublicProfile = prefs['publicProfile'] ?? true;
    bool showListeningActivity = prefs['showActivity'] ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          title: Text('Privacy Settings', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Public Profile', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                subtitle: const Text('Allow followers to see your profile and playlists'),
                value: isPublicProfile,
                activeColor: AppColors.primary,
                onChanged: (val) => setDialogState(() => isPublicProfile = val),
              ),
              SwitchListTile(
                title: Text('Listening Activity', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                subtitle: const Text('Share recently played songs'),
                value: showListeningActivity,
                activeColor: AppColors.primary,
                onChanged: (val) => setDialogState(() => showListeningActivity = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                await userProvider.updatePreferences({
                  ...prefs,
                  'publicProfile': isPublicProfile,
                  'showActivity': showListeningActivity,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSecurityDialog(BuildContext context, UserProvider userProvider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text('Security Settings', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              title: const Text('Email Verification'),
              subtitle: Text(userProvider.isEmailVerified ? 'Verified' : 'Tap to send verification link'),
              onTap: userProvider.isEmailVerified
                  ? null
                  : () async {
                      final success = await userProvider.sendEmailVerification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Verification email sent!' : (userProvider.error ?? 'Failed to send link.')),
                          ),
                        );
                      }
                    },
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (currentPasswordController.text.isNotEmpty && newPasswordController.text.isNotEmpty) {
                final success = await userProvider.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Password updated!' : (userProvider.error ?? 'Password update failed.')),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                  if (success) Navigator.pop(context);
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Harmony Music',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.headphones, size: 48, color: AppColors.primary),
      children: const [
        SizedBox(height: 12),
        Text('Harmony Music is an original, high-performance music application built with Flutter and Cloud Firebase.'),
        SizedBox(height: 8),
        Text('© 2026 Harmony Music. All rights reserved.'),
      ],
    );
  }

  void _showDocumentDialog(BuildContext context, String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800], fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showLogoutDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text(
          'Log Out',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteAccountDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text(
          'Delete Account',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and will erase all your playlists, favorites, and history.',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}
