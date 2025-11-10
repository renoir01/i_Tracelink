import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<UserModel> _allUsers = [];
  List<UserModel> _pendingUsers = [];
  List<UserModel> _verifiedUsers = [];
  List<UserModel> _rejectedUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = await FirestoreService().getAllUsers();

      setState(() {
        _allUsers = users;
        _pendingUsers = users.where((u) => !u.isVerified).toList();
        _verifiedUsers = users.where((u) => u.isVerified).toList();
        _rejectedUsers = users.where((u) => u.status == 'rejected').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with Stats
        Container(
          padding: const EdgeInsets.all(24.0),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Management',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage user accounts, verifications, and permissions',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _loadUsers,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Users',
                      _allUsers.length.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Pending Verification',
                      _pendingUsers.length.toString(),
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Verified Users',
                      _verifiedUsers.length.toString(),
                      Icons.verified,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Rejected',
                      _rejectedUsers.length.toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: 'All Users (${_allUsers.length})',
                icon: const Icon(Icons.people),
              ),
              Tab(
                text: 'Pending (${_pendingUsers.length})',
                icon: const Icon(Icons.pending),
              ),
              Tab(
                text: 'Verified (${_verifiedUsers.length})',
                icon: const Icon(Icons.verified),
              ),
              Tab(
                text: 'Rejected (${_rejectedUsers.length})',
                icon: const Icon(Icons.cancel),
              ),
            ],
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUserList(_allUsers, showActions: true),
              _buildUserList(_pendingUsers, showActions: true),
              _buildUserList(_verifiedUsers, showActions: true),
              _buildUserList(_rejectedUsers, showActions: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<UserModel> users, {bool showActions = true}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getUserTypeColor(user.userType),
              child: Icon(
                _getUserTypeIcon(user.userType),
                color: Colors.white,
              ),
            ),
            title: Text(user.email ?? 'No email'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getUserTypeLabel(user.userType),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  user.isVerified ? 'Verified' : 'Pending Verification',
                  style: TextStyle(
                    color: user.isVerified ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: showActions
                ? PopupMenuButton<String>(
                    onSelected: (action) => _handleUserAction(action, user),
                    itemBuilder: (context) => [
                      if (!user.isVerified) ...[
                        const PopupMenuItem(
                          value: 'verify',
                          child: Row(
                            children: [
                              Icon(Icons.verified, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Verify User'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reject',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Reject User'),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuItem(
                        value: 'view_details',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit User'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete User'),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
            onTap: () => _showUserDetails(user),
          ),
        );
      },
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case AppConstants.seedProducerType:
        return Colors.green;
      case AppConstants.agroDealerType:
        return Colors.blue;
      case AppConstants.cooperativeType:
        return Colors.orange;
      case AppConstants.aggregatorType:
        return Colors.purple;
      case AppConstants.institutionType:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType) {
      case AppConstants.seedProducerType:
        return Icons.eco;
      case AppConstants.agroDealerType:
        return Icons.store;
      case AppConstants.cooperativeType:
        return Icons.agriculture;
      case AppConstants.aggregatorType:
        return Icons.local_shipping;
      case AppConstants.institutionType:
        return Icons.school;
      default:
        return Icons.person;
    }
  }

  String _getUserTypeLabel(String userType) {
    switch (userType) {
      case AppConstants.seedProducerType:
        return 'Seed Producer';
      case AppConstants.agroDealerType:
        return 'Agro-Dealer';
      case AppConstants.cooperativeType:
        return 'Farmer Cooperative';
      case AppConstants.aggregatorType:
        return 'Aggregator';
      case AppConstants.institutionType:
        return 'Institution';
      default:
        return 'Unknown';
    }
  }

  void _handleUserAction(String action, UserModel user) async {
    switch (action) {
      case 'verify':
        await _verifyUser(user);
        break;
      case 'reject':
        await _rejectUser(user);
        break;
      case 'view_details':
        _showUserDetails(user);
        break;
      case 'edit':
        _editUser(user);
        break;
      case 'delete':
        await _deleteUser(user);
        break;
    }
  }

  Future<void> _verifyUser(UserModel user) async {
    try {
      await FirestoreService().verifyUser(user.id);
      
      // Send SMS notification
      if (user.phone.isNotEmpty) {
        try {
          await SMSService().sendAccountVerifiedNotification(
            phoneNumber: user.phone,
            userName: user.email.split('@')[0], // Use email username
          );
          debugPrint('✅ SMS sent to verified user: ${user.phone}');
        } catch (smsError) {
          debugPrint('⚠️ SMS notification failed (this is normal on web browsers due to CORS): $smsError');
          debugPrint('💡 SMS will work on mobile/desktop apps. User verification still completed successfully.');
        }
      }
      
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.email} has been verified')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying user: $e')),
        );
      }
    }
  }

  Future<void> _rejectUser(UserModel user) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const RejectionReasonDialog(),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await FirestoreService().rejectUser(user.id, reason);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.email} has been rejected')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error rejecting user: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to permanently delete ${user.email}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService().deleteUser(user.id);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.email} has been deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailsDialog(user: user),
    );
  }

  void _editUser(UserModel user) {
    // TODO: Implement user editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User editing coming soon!')),
    );
  }
}

// Rejection Reason Dialog
class RejectionReasonDialog extends StatefulWidget {
  const RejectionReasonDialog({super.key});

  @override
  State<RejectionReasonDialog> createState() => _RejectionReasonDialogState();
}

class _RejectionReasonDialogState extends State<RejectionReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please provide a reason for rejecting this user:'),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Rejection Reason',
              border: OutlineInputBorder(),
              hintText: 'e.g., Incomplete documentation, Invalid credentials...',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_reasonController.text.trim().isNotEmpty) {
              Navigator.of(context).pop(_reasonController.text.trim());
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

// User Details Dialog
class UserDetailsDialog extends StatelessWidget {
  final UserModel user;

  const UserDetailsDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Text(user.email ?? 'User Details'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('User ID', user.id),
            _buildDetailRow('Email', user.email ?? 'N/A'),
            _buildDetailRow('User Type', _getUserTypeLabel(user.userType)),
            _buildDetailRow('Status', user.isVerified ? 'Verified' : 'Pending'),
            _buildDetailRow('Created', user.createdAt?.toString().split('T')[0] ?? 'N/A'),
            if (user.phoneNumber != null)
              _buildDetailRow('Phone', user.phoneNumber!),
            if (user.location != null) ...[
              _buildDetailRow('District', user.location!['district'] ?? 'N/A'),
              _buildDetailRow('Sector', user.location!['sector'] ?? 'N/A'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
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
      case AppConstants.cooperativeType:
        return 'Farmer Cooperative';
      case AppConstants.aggregatorType:
        return 'Aggregator';
      case AppConstants.institutionType:
        return 'Institution';
      default:
        return 'Unknown';
    }
  }
}
