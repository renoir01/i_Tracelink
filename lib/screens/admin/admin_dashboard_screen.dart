import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/sms_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import 'developer_tools_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const AdminDashboardScreen({super.key, required this.adminData});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedTab = 'pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard - User Verification'),
        actions: [
          // Admin info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.adminData['name'] ?? 'Admin',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          // Developer Tools
          IconButton(
            icon: const Icon(Icons.developer_mode),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DeveloperToolsScreen(),
                ),
              );
            },
            tooltip: 'Developer Tools',
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _selectedTab == 'pending' ? 0 : 1,
            onDestinationSelected: (index) {
              setState(() {
                _selectedTab = index == 0 ? 'pending' : 'verified';
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.pending_actions),
                label: Text('Pending'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.verified_user),
                label: Text('Verified'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(
            child: _selectedTab == 'pending'
                ? const PendingUsersTab()
                : const VerifiedUsersTab(),
          ),
        ],
      ),
    );
  }
}

// Pending users tab
class PendingUsersTab extends StatelessWidget {
  const PendingUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.warningColor.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.pending_actions, color: AppTheme.warningColor),
              const SizedBox(width: 8),
              Text(
                'Pending Verification',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // User list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('isVerified', isEqualTo: false)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;

              if (users.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: AppTheme.successColor),
                      SizedBox(height: 16),
                      Text('No pending verifications!'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userData = users[index].data() as Map<String, dynamic>;
                  final userId = users[index].id;
                  
                  return UserVerificationCard(
                    userId: userId,
                    userData: userData,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Verified users tab
class VerifiedUsersTab extends StatelessWidget {
  const VerifiedUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.successColor.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.verified_user, color: AppTheme.successColor),
              const SizedBox(width: 8),
              Text(
                'Verified Users',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // User list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('isVerified', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;

              if (users.isEmpty) {
                return const Center(child: Text('No verified users yet.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userData = users[index].data() as Map<String, dynamic>;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.successColor,
                        child: const Icon(Icons.verified_user, color: Colors.white),
                      ),
                      title: Text(userData['email'] ?? 'No email'),
                      subtitle: Text(
                        _getUserTypeLabel(userData['userType'] ?? ''),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.check_circle, color: AppTheme.successColor),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _getUserTypeLabel(String userType) {
    switch (userType) {
      case AppConstants.seedProducerType:
        return 'Seed Producer';
      case AppConstants.agroDealerType:
        return 'Agro-Dealer';
      case AppConstants.farmerType:
        return 'Farmer Cooperative';
      case AppConstants.aggregatorType:
        return 'Aggregator';
      case AppConstants.institutionType:
        return 'School/Hospital';
      default:
        return userType;
    }
  }
}

// User verification card
class UserVerificationCard extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserVerificationCard({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<UserVerificationCard> createState() => _UserVerificationCardState();
}

class _UserVerificationCardState extends State<UserVerificationCard> {
  bool _isProcessing = false;

  Future<void> _verifyUser() async {
    setState(() => _isProcessing = true);

    try {
      // Get user data first
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      final userData = userDoc.data();
      
      // Update verification status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': FirebaseAuth.instance.currentUser?.email,
      });
      
      // Send SMS notification
      if (userData != null) {
        final phone = userData['phone'] as String? ?? '';
        final name = userData['name'] as String? ?? 'User';
        
        if (phone.isNotEmpty) {
          try {
            await SMSService().sendAccountVerifiedNotification(
              phoneNumber: phone,
              userName: name,
            );
            debugPrint('✅ SMS sent to verified user: $phone');
          } catch (smsError) {
            debugPrint('⚠️ SMS failed but user verified: $smsError');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ User verified successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectUser() async {
    setState(() => _isProcessing = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User rejected and removed.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.userData['email'] ?? 'No email';
    final userType = widget.userData['userType'] ?? '';
    final phone = widget.userData['phone'] ?? 'No phone';
    final createdAt = widget.userData['createdAt'] as Timestamp?;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    email[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getUserTypeLabel(userType),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'Phone', phone),
            _buildInfoRow(Icons.badge, 'User Type', _getUserTypeLabel(userType)),
            _buildInfoRow(
              Icons.calendar_today,
              'Registered',
              createdAt != null
                  ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
                  : 'Unknown',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _rejectUser,
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _verifyUser,
                  icon: const Icon(Icons.check),
                  label: _isProcessing
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _getUserTypeLabel(String userType) {
    switch (userType) {
      case AppConstants.seedProducerType:
        return 'Seed Producer';
      case AppConstants.agroDealerType:
        return 'Agro-Dealer';
      case AppConstants.farmerType:
        return 'Farmer Cooperative';
      case AppConstants.aggregatorType:
        return 'Aggregator';
      case AppConstants.institutionType:
        return 'School/Hospital';
      default:
        return userType;
    }
  }
}
