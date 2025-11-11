import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/unauthorized_screen.dart';
import '../screens/login_screen.dart';

/// A route guard widget that protects screens with authentication and role-based access control
///
/// Usage:
/// ```dart
/// routes: {
///   '/admin': (context) => ProtectedRoute(
///     allowedRoles: ['admin'],
///     child: const AdminPanelScreen(),
///   ),
///   '/dashboard': (context) => ProtectedRoute(
///     child: const DashboardScreen(),
///   ),
/// }
/// ```
class ProtectedRoute extends StatelessWidget {
  /// The widget to display if the user is authorized
  final Widget child;

  /// List of user roles allowed to access this route
  /// If empty, any authenticated user can access
  /// Examples: ['admin'], ['aggregator', 'institution'], ['farmer']
  final List<String> allowedRoles;

  /// Whether authentication is required (default: true)
  /// Set to false for public routes that still need role checking
  final bool requiresAuth;

  /// Optional custom message to show on unauthorized access
  final String? unauthorizedMessage;

  const ProtectedRoute({
    Key? key,
    required this.child,
    this.allowedRoles = const [],
    this.requiresAuth = true,
    this.unauthorizedMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check authentication requirement
        if (requiresAuth && !authProvider.isAuthenticated) {
          // User not authenticated - redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) {
              Navigator.pushReplacementNamed(
                context,
                '/',
                arguments: {'returnUrl': ModalRoute.of(context)?.settings.name},
              );
            }
          });
          return const LoginScreen(userType: '');
        }

        // Check role-based authorization
        if (allowedRoles.isNotEmpty && authProvider.isAuthenticated) {
          final userRole = authProvider.userModel?.userType;

          if (userRole == null || !allowedRoles.contains(userRole)) {
            // User doesn't have required role - show unauthorized
            return UnauthorizedScreen(
              message: unauthorizedMessage ??
                  'You do not have permission to access this page.\n'
                      'Required role: ${allowedRoles.join(' or ')}',
              userRole: userRole,
            );
          }
        }

        // User is authenticated and authorized - show the protected content
        return child;
      },
    );
  }
}

/// A more flexible route guard that accepts a custom authorization function
///
/// Usage:
/// ```dart
/// CustomProtectedRoute(
///   canAccess: (authProvider) {
///     return authProvider.userModel?.email == 'admin@example.com';
///   },
///   child: const SuperSecretScreen(),
/// ),
/// ```
class CustomProtectedRoute extends StatelessWidget {
  /// The widget to display if the user is authorized
  final Widget child;

  /// Custom function to determine if user can access
  /// Returns true if user should have access, false otherwise
  final bool Function(AuthProvider) canAccess;

  /// Optional custom unauthorized widget
  final Widget? unauthorizedWidget;

  /// Optional custom message for unauthorized access
  final String? unauthorizedMessage;

  const CustomProtectedRoute({
    Key? key,
    required this.child,
    required this.canAccess,
    this.unauthorizedWidget,
    this.unauthorizedMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check authentication first
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) {
              Navigator.pushReplacementNamed(context, '/');
            }
          });
          return const LoginScreen(userType: '');
        }

        // Check custom authorization
        if (!canAccess(authProvider)) {
          return unauthorizedWidget ??
              UnauthorizedScreen(
                message: unauthorizedMessage ??
                    'You do not have permission to access this page.',
              );
        }

        return child;
      },
    );
  }
}

/// Route guard specifically for admin-only routes
///
/// Usage:
/// ```dart
/// routes: {
///   '/admin': (context) => AdminOnlyRoute(
///     child: const AdminPanelScreen(),
///   ),
/// }
/// ```
class AdminOnlyRoute extends StatelessWidget {
  final Widget child;

  const AdminOnlyRoute({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
      allowedRoles: const ['admin'],
      unauthorizedMessage: 'This page is restricted to administrators only.',
      child: child,
    );
  }
}
