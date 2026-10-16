import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'services/payment_service.dart';
import 'services/email_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'utils/app_localizations.dart';
import 'utils/material_localizations_rw.dart';
import 'widgets/protected_route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');

    // Initialize Firebase Crashlytics
    // This catches and reports all Flutter framework errors
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      debugPrint('❌ Flutter Error: ${errorDetails.exception}');
    };

    // This catches errors outside the Flutter framework (async errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      debugPrint('❌ Platform Error: $error');
      return true;
    };

    debugPrint('✅ Firebase Crashlytics initialized successfully');

  } catch (e) {
    debugPrint('⚠️ Firebase initialization error: $e');
  }

  // Initialize Payment Service
  try {
    PaymentService().initialize();
    debugPrint('✅ Payment service initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Payment service initialization error: $e');
  }

  // Initialize Email Service
  try {
    EmailService().initialize();
    debugPrint('✅ Email service initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Email service initialization error: $e');
  }
  
  runApp(const iTraceLinkApp());
}

class iTraceLinkApp extends StatelessWidget {
  const iTraceLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            
            // Theme
            theme: AppTheme.lightTheme,
            
            // Localization
            locale: languageProvider.locale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('rw', ''),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              FallbackMaterialLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              // For Kinyarwanda, return it even though Material doesn't support it
              // This allows our custom AppLocalizations to work
              if (locale?.languageCode == 'rw') {
                return const Locale('rw', '');
              }
              
              // Check if locale is supported
              if (locale != null) {
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode) {
                    return supportedLocale;
                  }
                }
              }
              
              // Default to English
              return const Locale('en', '');
            },
            
            // Routes
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/dashboard': (context) => ProtectedRoute(
                    child: const DashboardScreen(),
                  ),
              '/admin': (context) => AdminOnlyRoute(
                    child: const AdminPanelScreen(),
                  ),
              '/admin-login': (context) => const AdminLoginScreen(),
            },
          );
        },
      ),
    );
  }
}
