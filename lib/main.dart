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
  var firebaseInitialized = false;

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint('Firebase initialized successfully');

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

  } catch (e, stackTrace) {
    debugPrint('Firebase initialization failed: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  if (!firebaseInitialized) {
    runApp(const StartupErrorApp());
    return;
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


/// Shown when Firebase cannot initialize. Avoid building screens that access
/// Firebase singletons when the default Firebase app is unavailable.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'iTraceLink could not connect to its services.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check your connection and try again. If the problem continues, contact support.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
