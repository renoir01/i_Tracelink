import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../screens/profile/seed_producer_profile_screen.dart';
import '../screens/profile/agro_dealer_profile_screen.dart';
import '../screens/profile/cooperative_profile_screen.dart';
import '../screens/profile/aggregator_profile_screen.dart';
import '../screens/profile/institution_profile_screen.dart';
import '../screens/aggregator_dashboard_screen.dart';
import '../screens/institution_dashboard_screen.dart';
import '../screens/seed_producer_dashboard_screen.dart';
import '../screens/agro_dealer_dashboard_screen.dart';
import 'language_selection_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      // Check if user has completed their profile
      final userModel = authProvider.userModel;
      if (userModel == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
        );
        return;
      }
      
      final hasProfile = await FirestoreService()
          .hasCompletedProfile(userModel.id, userModel.userType);
      
      if (!mounted) return;
      
      if (!hasProfile) {
        // Route to appropriate profile screen based on user type
        Widget profileScreen;
        
        switch (userModel.userType) {
          case AppConstants.seedProducerType:
            profileScreen = const SeedProducerProfileScreen();
            break;
          case AppConstants.agroDealerType:
            profileScreen = const AgroDealerProfileScreen();
            break;
          case AppConstants.farmerType:
            profileScreen = const CooperativeProfileScreen();
            break;
          case AppConstants.aggregatorType:
            profileScreen = const AggregatorProfileScreen();
            break;
          case AppConstants.institutionType:
            profileScreen = const InstitutionProfileScreen();
            break;
          default:
            // If unknown type, go to dashboard
            Navigator.of(context).pushReplacementNamed('/dashboard');
            return;
        }
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => profileScreen),
        );
      } else {
        // Profile exists, go to appropriate dashboard
        Widget? dashboardScreen;
        
        if (userModel.userType == AppConstants.aggregatorType) {
          dashboardScreen = const AggregatorDashboardScreen();
        } else if (userModel.userType == AppConstants.institutionType) {
          dashboardScreen = const InstitutionDashboardScreen();
        } else if (userModel.userType == AppConstants.seedProducerType) {
          dashboardScreen = const SeedProducerDashboardScreen();
        } else if (userModel.userType == AppConstants.agroDealerType) {
          dashboardScreen = const AgroDealerDashboardScreen();
        }
        
        if (dashboardScreen != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => dashboardScreen!),
          );
        } else {
          // Default dashboard for other user types
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      }
    } else {
      // Navigate to language selection
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.eco,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appTaglineEn,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
