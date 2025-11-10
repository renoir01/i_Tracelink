import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/app_localizations.dart';
import 'user_type_selection_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // App Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.eco,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                AppLocalizations.of(context)!.selectLanguage,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // English Button
              _LanguageCard(
                flag: '🇬🇧',
                language: AppLocalizations.of(context)!.english,
                onTap: () {
                  Provider.of<LanguageProvider>(context, listen: false)
                      .setLanguage(AppConstants.languageEnglish);
                  _navigateNext(context);
                },
              ),
              const SizedBox(height: 16),
              // Kinyarwanda Button
              _LanguageCard(
                flag: '🇷🇼',
                language: AppLocalizations.of(context)!.kinyarwanda,
                onTap: () {
                  Provider.of<LanguageProvider>(context, listen: false)
                      .setLanguage(AppConstants.languageKinyarwanda);
                  _navigateNext(context);
                },
              ),
              const Spacer(),
              // Admin Login Button
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/admin-login');
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Admin Login'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateNext(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const UserTypeSelectionScreen(),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String language;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  language,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
